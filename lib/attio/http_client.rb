require 'typhoeus'
require 'json'

module Attio
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

    private

    def execute_request(method, path, options = {})
      url = "#{base_url}/#{path}"
      
      request_options = {
        method: method,
        headers: headers.merge('Content-Type' => 'application/json'),
        timeout: timeout,
        connecttimeout: timeout
      }.merge(options)

      request = Typhoeus::Request.new(url, request_options)
      response = request.run

      handle_response(response)
    end

    def handle_response(response)
      case response.code
      when 0
        # Timeout or connection error
        if response.timed_out?
          raise TimeoutError, "Request timed out"
        else
          raise ConnectionError, "Connection failed: #{response.return_message}"
        end
      when 200..299
        parse_json(response.body)
      when 401
        raise AuthenticationError, parse_error_message(response)
      when 404
        raise NotFoundError, parse_error_message(response)
      when 422
        raise ValidationError, parse_error_message(response)
      when 429
        raise RateLimitError, parse_error_message(response)
      when 500..599
        raise ServerError, parse_error_message(response)
      else
        raise Error, "Request failed with status #{response.code}: #{parse_error_message(response)}"
      end
    end

    def parse_json(body)
      return {} if body.nil? || body.empty?
      JSON.parse(body)
    rescue JSON::ParserError => e
      raise Error, "Invalid JSON response: #{e.message}"
    end

    def parse_error_message(response)
      body = parse_json(response.body) rescue response.body
      
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