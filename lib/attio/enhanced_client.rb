# frozen_string_literal: true

require_relative "client"
require_relative "connection_pool"
require_relative "circuit_breaker"
require_relative "observability"
require_relative "webhooks"

module Attio
  # Enhanced client with enterprise features
  #
  # @example With connection pooling
  #   client = Attio::EnhancedClient.new(
  #     api_key: 'your-api-key',
  #     connection_pool: { size: 10, timeout: 5 },
  #     circuit_breaker: { threshold: 5, timeout: 60 },
  #     instrumentation: { logger: Rails.logger, metrics: :datadog }
  #   )
  class EnhancedClient < Client
    attr_reader :pool, :circuit_breaker, :instrumentation, :webhooks

    # Initialize enhanced client with enterprise features
    #
    # @param api_key [String] Attio API key
    # @param timeout [Integer] Request timeout
    # @param connection_pool [Hash] Pool configuration
    # @param circuit_breaker [Hash] Circuit breaker configuration
    # @param instrumentation [Hash] Observability configuration
    # @param webhook_secret [String] Webhook signing secret
    def initialize(
      api_key:,
      timeout: DEFAULT_TIMEOUT,
      connection_pool: nil,
      circuit_breaker: nil,
      instrumentation: nil,
      webhook_secret: nil
    )
      super(api_key: api_key, timeout: timeout)

      setup_connection_pool(connection_pool) if connection_pool
      setup_circuit_breaker(circuit_breaker) if circuit_breaker
      setup_instrumentation(instrumentation) if instrumentation
      setup_webhooks(webhook_secret) if webhook_secret
    end

    # Override connection to use pooled connections
    def connection
      return super unless @pool

      @connection ||= begin
        client = PooledHttpClient.new(@pool)
        client = wrap_with_circuit_breaker(client) if @circuit_breaker
        client = wrap_with_instrumentation(client) if @instrumentation
        client
      end
    end

    # Execute with automatic retries and circuit breaking
    #
    # @param endpoint [String] Optional endpoint key for circuit breaker
    # @yield Block to execute
    def execute(endpoint: nil, &block)
      if @circuit_breaker && endpoint
        @composite_breaker ||= CompositeCircuitBreaker.new
        @composite_breaker.call(endpoint, &block)
      elsif @circuit_breaker
        @circuit_breaker.call(&block)
      else
        yield
      end
    end

    # Health check for all components
    #
    # @return [Hash] Health status
    def health_check
      {
        api: check_api_health,
        pool: @pool&.healthy? || true,
        circuit_breaker: circuit_breaker_health,
        rate_limiter: rate_limiter.status[:remaining] > 0,
      }
    end

    # Get comprehensive statistics
    #
    # @return [Hash] Statistics from all components
    def stats
      {
        pool: @pool&.stats,
        circuit_breaker: @circuit_breaker&.stats,
        rate_limiter: rate_limiter.status,
        instrumentation: @instrumentation&.metrics&.counters,
      }
    end

    # Graceful shutdown
    def shutdown!
      @pool&.shutdown
      @instrumentation&.disable!

      # Gracefully stop background stats thread
      return unless @stats_thread&.alive?

      @stats_thread.kill
      @stats_thread.join(5) # Wait up to 5 seconds for clean shutdown
    end

    private def setup_connection_pool(config)
      pool_size = config[:size] || ConnectionPool::DEFAULT_SIZE
      pool_timeout = config[:timeout] || ConnectionPool::DEFAULT_TIMEOUT

      @pool = ConnectionPool.new(size: pool_size, timeout: pool_timeout) do
        HttpClient.new(
          base_url: API_BASE_URL,
          headers: default_headers,
          timeout: timeout,
          rate_limiter: rate_limiter
        )
      end
    end

    private def setup_circuit_breaker(config)
      @circuit_breaker = CircuitBreaker.new(
        threshold: config[:threshold] || 5,
        timeout: config[:timeout] || 60,
        half_open_requests: config[:half_open_requests] || 3,
        exceptions: [Attio::Error, Timeout::Error, Errno::ECONNREFUSED]
      )

      # Set up state change notifications
      @circuit_breaker.on_state_change = lambda do |old_state, new_state|
        @instrumentation&.record_circuit_breaker(
          endpoint: "api",
          old_state: old_state,
          new_state: new_state
        )
      end
    end

    private def setup_instrumentation(config)
      @instrumentation = Observability::Instrumentation.new(
        logger: config[:logger],
        metrics_backend: config[:metrics],
        trace_backend: config[:traces]
      )

      # Start background stats reporter if pool exists
      return unless @pool

      @stats_thread = Thread.new do
        loop do
          sleep 60 # Report every minute
          @instrumentation.record_pool_stats(@pool.stats) if @pool
        rescue StandardError => e
          @instrumentation.logger.error(
            "Background stats thread error: #{e.class.name}: #{e.message}\n" \
            "Backtrace: #{e.backtrace.join("\n")}"
          )
          # Continue the loop to keep the thread alive
        end
      rescue StandardError => e
        @instrumentation.logger.fatal(
          "Background stats thread crashed: #{e.class.name}: #{e.message}\n" \
          "Backtrace: #{e.backtrace.join("\n")}"
        )
        # Thread will exit, but this prevents it from crashing silently
      end
    end

    private def setup_webhooks(secret)
      @webhooks = Webhooks.new(secret: secret)
    end

    private def wrap_with_circuit_breaker(client)
      CircuitBreakerClient.new(client, @circuit_breaker)
    end

    private def wrap_with_instrumentation(client)
      # Create instrumented wrapper
      Class.new do
        def initialize(client, instrumentation)
          @client = client
          @instrumentation = instrumentation
        end

        %i[get post patch put delete].each do |method|
          define_method(method) do |*args|
            start_time = Time.now
            path = args[0]

            begin
              result = @client.send(method, *args)
              status = result.is_a?(Hash) ? result["_status"] : nil
              @instrumentation.record_api_call(
                method: method,
                path: path,
                duration: Time.now - start_time,
                status: status
              )
              result
            rescue StandardError => e
              @instrumentation.record_api_call(
                method: method,
                path: path,
                duration: Time.now - start_time,
                error: e
              )
              raise
            end
          end
        end
      end.new(client, @instrumentation)
    end

    private def default_headers
      {
        "Authorization" => "Bearer #{api_key}",
        "Accept" => "application/json",
        "Content-Type" => "application/json",
        "User-Agent" => "Attio Ruby Client/#{VERSION}",
      }
    end

    private def check_api_health
      connection.get("meta/identify")
      true
    rescue StandardError
      false
    end

    private def circuit_breaker_health
      return true unless @circuit_breaker

      CIRCUIT_STATES[@circuit_breaker.state]
    end

    CIRCUIT_STATES = {
      closed: :healthy,
      half_open: :recovering,
      open: :unhealthy,
    }.freeze
    private_constant :CIRCUIT_STATES
  end

  # Factory method for creating enhanced client
  #
  # @example
  #   client = Attio.enhanced_client(
  #     api_key: ENV['ATTIO_API_KEY'],
  #     connection_pool: { size: 25 },
  #     circuit_breaker: { threshold: 10 }
  #   )
  def self.enhanced_client(**options)
    EnhancedClient.new(**options)
  end
end
