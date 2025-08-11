# frozen_string_literal: true

module Attio
  # Rate limiter with intelligent retry and backoff strategies
  #
  # @example Using the rate limiter
  #   limiter = Attio::RateLimiter.new(
  #     max_requests: 100,
  #     window_seconds: 60,
  #     max_retries: 3
  #   )
  #
  #   limiter.execute { client.records.list }
  class RateLimiter
    attr_reader :max_requests, :window_seconds, :max_retries
    attr_accessor :current_limit, :remaining, :reset_at

    # Initialize a new rate limiter
    #
    # @param max_requests [Integer] Maximum requests per window
    # @param window_seconds [Integer] Time window in seconds
    # @param max_retries [Integer] Maximum retry attempts
    # @param enable_jitter [Boolean] Add jitter to backoff delays
    def initialize(max_requests: 1000, window_seconds: 3600, max_retries: 3, enable_jitter: true)
      @max_requests = max_requests
      @window_seconds = window_seconds
      @max_retries = max_retries
      @enable_jitter = enable_jitter

      @current_limit = max_requests
      @remaining = max_requests
      @reset_at = Time.now + window_seconds

      @mutex = Mutex.new
      @request_queue = []
      @request_times = []
    end

    # Execute a block with rate limiting
    #
    # @yield The block to execute
    # @return The result of the block
    def execute
      raise ArgumentError, "Block required" unless block_given?

      @mutex.synchronize do
        wait_if_needed
        track_request
      end

      attempt = 0
      begin
        result = yield
        # Thread-safe header update
        @mutex.synchronize do
          update_from_headers(result) if result.is_a?(Hash) && result["_headers"]
        end
        result
      rescue Attio::RateLimitError => e
        attempt += 1
        raise e unless attempt <= @max_retries

        wait_time = calculate_backoff(attempt, e)
        sleep(wait_time)
        retry
      end
    end

    # Check if rate limit is exceeded
    #
    # @return [Boolean] True if rate limit would be exceeded
    def rate_limited?
      @mutex.synchronize do
        cleanup_old_requests
        @request_times.size >= @max_requests
      end
    end

    # Get current rate limit status
    #
    # @return [Hash] Current status
    def status
      @mutex.synchronize do
        cleanup_old_requests
        {
          limit: @current_limit,
          remaining: [@remaining, @max_requests - @request_times.size].min,
          reset_at: @reset_at,
          reset_in: [@reset_at - Time.now, 0].max.to_i,
          current_usage: @request_times.size,
        }
      end
    end

    # Update rate limit info from response headers
    # NOTE: This method should be called within a mutex lock
    #
    # @param response [Hash] Response containing headers
    private def update_from_headers(response)
      return unless response.is_a?(Hash)

      headers = response["_headers"] || {}

      @current_limit = headers["x-ratelimit-limit"].to_i if headers["x-ratelimit-limit"]
      @remaining = headers["x-ratelimit-remaining"].to_i if headers["x-ratelimit-remaining"]
      @reset_at = Time.at(headers["x-ratelimit-reset"].to_i) if headers["x-ratelimit-reset"]
    end

    # Reset the rate limiter
    def reset!
      @mutex.synchronize do
        @request_times.clear
        @remaining = @max_requests
        @reset_at = Time.now + @window_seconds
      end
    end

    # Queue a request for later execution
    #
    # @param priority [Integer] Priority (lower = higher priority)
    # @yield Block to execute
    def queue_request(priority: 5, &block)
      @mutex.synchronize do
        @request_queue << { priority: priority, block: block, queued_at: Time.now }
        @request_queue.sort_by! { |r| [r[:priority], r[:queued_at]] }
      end
    end

    # Process queued requests
    #
    # @param max_per_batch [Integer] Maximum requests to process
    # @return [Array] Results from processed requests
    def process_queue(max_per_batch: 10)
      results = []
      processed = 0

      while processed < max_per_batch
        request = @mutex.synchronize { @request_queue.shift }
        break unless request

        begin
          result = execute(&request[:block])
          results << { success: true, result: result }
        rescue StandardError => e
          results << { success: false, error: e }
        end

        processed += 1
      end

      results
    end

    private def wait_if_needed
      cleanup_old_requests

      if @request_times.size >= @max_requests
        wait_time = @request_times.first + @window_seconds - Time.now
        if wait_time > 0
          sleep(wait_time)
          cleanup_old_requests
        end
      end

      return unless @remaining <= 0 && @reset_at > Time.now

      wait_time = @reset_at - Time.now
      sleep(wait_time) if wait_time > 0
    end

    private def track_request
      @request_times << Time.now
      @remaining = [@remaining - 1, 0].max
    end

    private def cleanup_old_requests
      cutoff = Time.now - @window_seconds
      @request_times.reject! { |time| time < cutoff }
    end

    private def calculate_backoff(attempt, error = nil)
      base_wait = 2**attempt

      # Use server-provided retry-after if available
      base_wait = error.retry_after if error && error.respond_to?(:retry_after) && error.retry_after

      # Add jitter to prevent thundering herd
      if @enable_jitter
        jitter = rand * base_wait * 0.1
        base_wait + jitter
      else
        base_wait
      end
    end
  end

  # Middleware for automatic rate limiting
  class RateLimitMiddleware
    def initialize(app, rate_limiter)
      @app = app
      @rate_limiter = rate_limiter
    end

    def call(env)
      @rate_limiter.execute do
        response = @app.call(env)
        # Headers are automatically updated within execute block
        response
      end
    end
  end
end
