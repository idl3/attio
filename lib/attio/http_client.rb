# frozen_string_literal: true

require "typhoeus"
require "json"

module Attio
  # HTTP client for making API requests to Attio
  #
  # This class handles the low-level HTTP communication with the Attio API,
  # including request execution, response parsing, and error handling.
  #
  # @api private
  class HttpClient
    DEFAULT_TIMEOUT = 30

    attr_reader :base_url, :headers, :timeout, :rate_limiter

    def initialize(base_url:, headers: {}, timeout: DEFAULT_TIMEOUT, rate_limiter: nil)
      @base_url = base_url
      @headers = headers
      @timeout = timeout
      @rate_limiter = rate_limiter
    end

    def get(path, params = nil)
      if params && !params.empty?
        execute_request(:get, path, params: params)
      else
        execute_request(:get, path)
      end
    end

    def post(path, body = {})
      execute_request(:post, path, body: body.to_json)
    end

    def patch(path, body = {})
      execute_request(:patch, path, body: body.to_json)
    end

    def put(path, body = {})
      execute_request(:put, path, body: body.to_json)
    end

    def delete(path, params = nil)
      if params
        execute_request(:delete, path, body: params.to_json)
      else
        execute_request(:delete, path)
      end
    end

    private def execute_request(method, path, options = {})
      # Use rate limiter if available
      return @rate_limiter.execute { perform_request(method, path, options) } if @rate_limiter

      perform_request(method, path, options)
    end

    private def perform_request(method, path, options = {})
      url = "#{base_url}/#{path}"

      request_options = {
        method: method,
        headers: headers.merge("Content-Type" => "application/json"),
        timeout: timeout,
        connecttimeout: timeout,
        # SSL/TLS security settings
        ssl_verifypeer: true,
        ssl_verifyhost: 2,
        followlocation: false, # Prevent following redirects for security
      }.merge(options)

      request = Typhoeus::Request.new(url, request_options)
      response = request.run

      handle_response(response)
    end

    private def handle_response(response)
      return handle_connection_error(response) if response.code == 0

      if (200..299).cover?(response.code)
        result = parse_json(response.body)
        # Add headers to result for rate limiter to process
        result["_headers"] = extract_rate_limit_headers(response) if @rate_limiter
        return result
      end

      handle_error_response(response)
    end

    private def handle_connection_error(response)
      raise TimeoutError, "Request timed out" if response.timed_out?

      raise ConnectionError, "Connection failed: #{response.return_message}"
    end

    private def handle_error_response(response)
      error_class = error_class_for_status(response.code)
      message = parse_error_message(response)

      # Handle rate limit errors specially
      if response.code == 429
        retry_after = extract_retry_after(response)
        raise RateLimitError.new(message, retry_after: retry_after, response: response, code: response.code)
      end

      # Add status code to message for generic errors
      message = "Request failed with status #{response.code}: #{message}" if error_class == Error

      raise error_class, message
    end

    private def error_class_for_status(status)
      error_map = {
        401 => AuthenticationError,
        404 => NotFoundError,
        422 => ValidationError,
        429 => RateLimitError,
      }
      return error_map[status] if error_map.key?(status)
      return ServerError if (500..599).cover?(status)

      Error
    end

    private def parse_json(body)
      return {} if body.nil? || body.empty?

      JSON.parse(body)
    rescue JSON::ParserError => e
      raise Error, "Invalid JSON response: #{e.message}"
    end

    private def parse_error_message(response)
      body = begin
        parse_json(response.body)
      rescue StandardError
        response.body
      end

      if body.is_a?(Hash)
        body["error"] || body["message"] || body.to_s
      else
        body.to_s
      end
    end

    private def extract_rate_limit_headers(response)
      headers = {}
      response.headers.each do |key, value|
        case key.downcase
        when "x-ratelimit-limit"
          headers["x-ratelimit-limit"] = value
        when "x-ratelimit-remaining"
          headers["x-ratelimit-remaining"] = value
        when "x-ratelimit-reset"
          headers["x-ratelimit-reset"] = value
        end
      end
      headers
    end

    private def extract_retry_after(response)
      retry_after = response.headers["retry-after"] || response.headers["Retry-After"]
      return nil unless retry_after

      # Try parsing as integer (seconds) first
      parsed = retry_after.to_i
      # If to_i returns 0 but the string isn't "0", it means parsing failed
      return parsed if parsed > 0 || retry_after == "0"

      # If not a valid integer, could be HTTP date, default to 60 seconds
      60
    rescue StandardError
      # If not an integer, could be HTTP date, default to 60 seconds
      60
    end

    class TimeoutError < Error; end
    class ConnectionError < Error; end
  end
end
