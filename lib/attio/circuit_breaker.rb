# frozen_string_literal: true

module Attio
  # Circuit breaker pattern for fault tolerance
  #
  # @example Basic usage
  #   breaker = CircuitBreaker.new(
  #     threshold: 5,
  #     timeout: 60,
  #     half_open_requests: 3
  #   )
  #
  #   breaker.call do
  #     # API call that might fail
  #     client.records.list
  #   end
  class CircuitBreaker
    class OpenCircuitError < StandardError; end

    # Circuit states
    CLOSED = :closed
    OPEN = :open
    HALF_OPEN = :half_open

    attr_reader :state, :failure_count, :success_count, :last_failure_time
    attr_accessor :on_state_change

    # Initialize circuit breaker
    #
    # @param threshold [Integer] Number of failures before opening circuit
    # @param timeout [Integer] Seconds before attempting to close circuit
    # @param half_open_requests [Integer] Successful requests needed to close circuit
    # @param exceptions [Array<Class>] Exception classes to catch
    def initialize(
      threshold: 5,
      timeout: 60,
      half_open_requests: 3,
      exceptions: [StandardError]
    )
      @threshold = threshold
      @timeout = timeout
      @half_open_requests = half_open_requests
      @exceptions = exceptions

      @state = CLOSED
      @failure_count = 0
      @success_count = 0
      @last_failure_time = nil
      @half_open_successes = 0

      @mutex = Mutex.new
      @on_state_change = nil

      # Statistics
      @stats = {
        requests: 0,
        failures: 0,
        successes: 0,
        rejections: 0,
        state_changes: 0,
      }
    end

    # Execute a block with circuit breaker protection
    #
    # @yield Block to execute
    # @return Result of the block
    # @raise [OpenCircuitError] if circuit is open
    def call
      @mutex.synchronize do
        @stats[:requests] += 1

        case @state
        when OPEN
          if can_attempt_reset?
            transition_to(HALF_OPEN)
          else
            @stats[:rejections] += 1
            raise OpenCircuitError, "Circuit breaker is open (#{time_until_retry}s until retry)"
          end
        when HALF_OPEN
          # Allow limited requests through
          if @half_open_successes >= @half_open_requests
            # Already proven stable, close the circuit
            transition_to(CLOSED)
          end
        end
      end

      # Execute the block outside the mutex
      begin
        result = yield
        record_success
        result
      rescue *@exceptions => e
        record_failure
        raise e
      end
    end

    # Manually trip the circuit breaker
    def trip!
      @mutex.synchronize do
        transition_to(OPEN)
      end
    end

    # Manually reset the circuit breaker
    def reset!
      @mutex.synchronize do
        @failure_count = 0
        @success_count = 0
        @half_open_successes = 0
        @last_failure_time = nil
        transition_to(CLOSED)
      end
    end

    # Check if circuit allows requests
    #
    # @return [Boolean] True if requests are allowed
    def allow_request?
      @state != OPEN || can_attempt_reset?
    end

    # Get circuit breaker statistics
    #
    # @return [Hash] Statistics
    def stats
      @mutex.synchronize do
        @stats.merge(
          state: @state,
          failure_count: @failure_count,
          success_count: @success_count,
          threshold: @threshold,
          time_until_retry: @state == OPEN ? time_until_retry : nil
        )
      end
    end

    # Time remaining until circuit can attempt reset
    #
    # @return [Integer] Seconds until retry, 0 if ready
    def time_until_retry
      return 0 unless @state == OPEN
      return 0 unless @last_failure_time

      elapsed = Time.now - @last_failure_time
      remaining = @timeout - elapsed
      remaining > 0 ? remaining.to_i : 0
    end

    private def record_success
      @mutex.synchronize do
        @stats[:successes] += 1
        @success_count += 1

        case @state
        when HALF_OPEN
          @half_open_successes += 1
          if @half_open_successes >= @half_open_requests
            # Circuit has proven stable
            transition_to(CLOSED)
          end
        when CLOSED
          # Reset failure count on success
          @failure_count = 0
        end
      end
    end

    private def record_failure
      @mutex.synchronize do
        @stats[:failures] += 1
        @failure_count += 1
        @last_failure_time = Time.now

        case @state
        when CLOSED
          transition_to(OPEN) if @failure_count >= @threshold
        when HALF_OPEN
          # Single failure in half-open state reopens circuit
          transition_to(OPEN)
        end
      end
    end

    private def can_attempt_reset?
      return false unless @last_failure_time

      Time.now - @last_failure_time >= @timeout
    end

    private def transition_to(new_state)
      return if @state == new_state

      old_state = @state
      @state = new_state
      @stats[:state_changes] += 1

      # Reset counters for new state
      case new_state
      when CLOSED
        @failure_count = 0
        @half_open_successes = 0
      when HALF_OPEN
        @half_open_successes = 0
      end

      # Notify state change
      @on_state_change&.call(old_state, new_state)
    end
  end

  # Wrapper for circuit breaker protected HTTP client
  class CircuitBreakerClient
    def initialize(client, circuit_breaker)
      @client = client
      @circuit_breaker = circuit_breaker
    end

    def get(path, params = nil)
      @circuit_breaker.call { @client.get(path, params) }
    end

    def post(path, body = {})
      @circuit_breaker.call { @client.post(path, body) }
    end

    def patch(path, body = {})
      @circuit_breaker.call { @client.patch(path, body) }
    end

    def put(path, body = {})
      @circuit_breaker.call { @client.put(path, body) }
    end

    def delete(path, body = nil)
      @circuit_breaker.call { @client.delete(path, body) }
    end
  end

  # Composite circuit breaker for multiple endpoints
  class CompositeCircuitBreaker
    def initialize(default_config = {})
      @breakers = {}
      @default_config = {
        threshold: 5,
        timeout: 60,
        half_open_requests: 3,
      }.merge(default_config)
      @mutex = Mutex.new
    end

    # Get or create circuit breaker for endpoint
    #
    # @param key [String] Endpoint key
    # @param config [Hash] Optional config overrides
    # @return [CircuitBreaker] Circuit breaker for endpoint
    def for_endpoint(key, config = {})
      @mutex.synchronize do
        @breakers[key] ||= CircuitBreaker.new(**@default_config, **config)
      end
    end

    # Execute with circuit breaker for endpoint
    #
    # @param key [String] Endpoint key
    # @yield Block to execute
    def call(key, &block)
      for_endpoint(key).call(&block)
    end

    # Get all circuit breaker states
    #
    # @return [Hash] States by endpoint
    def states
      @mutex.synchronize do
        @breakers.transform_values(&:state)
      end
    end

    # Get aggregated statistics
    #
    # @return [Hash] Combined statistics
    def stats
      @mutex.synchronize do
        @breakers.transform_values(&:stats)
      end
    end

    # Reset all circuit breakers
    def reset_all!
      @mutex.synchronize do
        @breakers.each_value(&:reset!)
      end
    end
  end
end
