# frozen_string_literal: true

module Attio
  # Base error class for all Attio errors
  class Error < StandardError
    attr_reader :response, :code

    def initialize(message = nil, response: nil, code: nil)
      @response = response
      @code = code
      super(message)
    end
  end

  # Raised when authentication fails (401)
  class AuthenticationError < Error; end

  # Raised when a resource is not found (404)
  class NotFoundError < Error; end

  # Raised when validation fails (400/422)
  class ValidationError < Error; end

  # Raised when rate limit is exceeded (429)
  class RateLimitError < Error
    attr_reader :retry_after

    def initialize(message = nil, retry_after: nil, **options)
      @retry_after = retry_after
      super(message, **options)
    end
  end

  # Raised when server error occurs (5xx)
  class ServerError < Error; end

  # Raised for generic API errors
  class APIError < Error; end
end
