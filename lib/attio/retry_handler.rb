# frozen_string_literal: true

module Attio
  # Handles automatic retry logic for failed API requests
  #
  # This class implements exponential backoff retry strategy for
  # transient errors like timeouts and rate limits.
  #
  # @example Using the retry handler
  #   handler = RetryHandler.new(max_retries: 5)
  #   handler.with_retry { api_client.get("/endpoint") }
  class RetryHandler
    DEFAULT_MAX_RETRIES = 3
    DEFAULT_RETRY_DELAY = 1 # seconds
    DEFAULT_BACKOFF_FACTOR = 2
    RETRIABLE_ERRORS = [
      HttpClient::TimeoutError,
      HttpClient::ConnectionError,
      ServerError,
      RateLimitError,
    ].freeze

    attr_reader :max_retries, :retry_delay, :backoff_factor, :logger

    def initialize(max_retries: DEFAULT_MAX_RETRIES,
                   retry_delay: DEFAULT_RETRY_DELAY,
                   backoff_factor: DEFAULT_BACKOFF_FACTOR,
                   logger: nil)
      @max_retries = max_retries
      @retry_delay = retry_delay
      @backoff_factor = backoff_factor
      @logger = logger
    end

    def with_retry
      retries = 0
      delay = retry_delay

      begin
        yield
      rescue *RETRIABLE_ERRORS => e
        retries += 1

        if retries <= max_retries
          log_retry(e, retries, delay)
          sleep(delay)
          delay *= backoff_factor
          retry
        else
          log_failure(e, retries)
          raise
        end
      end
    end

    private def log_retry(error, attempt, delay)
      return unless logger

      logger.warn(
        "Retry attempt #{attempt}/#{max_retries}",
        error: error.class.name,
        message: error.message,
        delay: delay
      )
    end

    private def log_failure(error, attempts)
      return unless logger

      logger.error(
        "Max retries exceeded",
        error: error.class.name,
        message: error.message,
        attempts: attempts
      )
    end
  end
end
