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

    attr_reader :base_url, :headers, :timeout

    def initialize(base_url:, headers: {}, timeout: DEFAULT_TIMEOUT)
      @base_url = base_url
      @headers = headers
      @timeout = timeout
    end

    def get(path, params = {})
      execute_request(:get, path, params: params)
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

    def delete(path)
      execute_request(:delete, path)
    end

    private def execute_request(method, path, options = {})
      url = "#{base_url}/#{path}"

      request_options = {
        method: method,
        headers: headers.merge("Content-Type" => "application/json"),
        timeout: timeout,
        connecttimeout: timeout,
      }.merge(options)

      request = Typhoeus::Request.new(url, request_options)
      response = request.run

      handle_response(response)
    end

    private def handle_response(response)
      return handle_connection_error(response) if response.code == 0
      return parse_json(response.body) if (200..299).cover?(response.code)

      handle_error_response(response)
    end

    private def handle_connection_error(response)
      raise TimeoutError, "Request timed out" if response.timed_out?

      raise ConnectionError, "Connection failed: #{response.return_message}"
    end

    private def handle_error_response(response)
      error_class = error_class_for_status(response.code)
      message = parse_error_message(response)

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

    class TimeoutError < Error; end
    class ConnectionError < Error; end
  end
end
