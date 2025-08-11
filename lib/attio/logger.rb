# frozen_string_literal: true

require "logger"
require "json"

module Attio
  # Enhanced logger for structured logging with JSON formatting
  #
  # This logger extends Ruby's standard Logger to provide structured
  # logging with contextual information and JSON output.
  #
  # @example Basic usage
  #   logger = Attio::Logger.new(STDOUT)
  #   logger.info("API request", method: "GET", path: "/users")
  class Logger < ::Logger
    def initialize(logdev, level: ::Logger::INFO, formatter: nil)
      super(logdev)
      self.level = level
      self.formatter = formatter || default_formatter
    end

    def debug(message, **context)
      super(format_message(message, context))
    end

    def info(message, **context)
      super(format_message(message, context))
    end

    def warn(message, **context)
      super(format_message(message, context))
    end

    def error(message, **context)
      super(format_message(message, context))
    end

    private def format_message(message, context)
      return message if context.empty?

      {
        message: message,
        **context,
      }
    end

    private def default_formatter
      proc do |severity, datetime, progname, msg|
        data = {
          timestamp: datetime.iso8601,
          level: severity,
          progname: progname,
        }

        if msg.is_a?(Hash)
          data.merge!(msg)
        else
          data[:message] = msg
        end

        "#{JSON.generate(data)}\n"
      end
    end
  end

  # Specialized logger for API request/response logging
  #
  # This class provides sanitized logging of HTTP requests and responses,
  # automatically redacting sensitive information like API keys.
  #
  # @api private
  class RequestLogger
    attr_reader :logger, :log_level

    def initialize(logger:, log_level: :debug)
      @logger = logger
      @log_level = log_level
    end

    def log_request(method, url, headers, body)
      return unless logger

      logger.send(log_level, "API Request",
                  method: method.to_s.upcase,
                  url: url,
                  headers: sanitize_headers(headers),
                  body: sanitize_body(body))
    end

    def log_response(response, duration)
      return unless logger

      logger.send(log_level, "API Response",
                  status: response.code,
                  duration_ms: (duration * 1000).round(2),
                  headers: response.headers,
                  body_size: response.body&.bytesize)
    end

    private def sanitize_headers(headers)
      headers.transform_values do |value|
        if value.include?("Bearer")
          value.gsub(/Bearer\s+[\w\-]+/, "Bearer [REDACTED]")
        else
          value
        end
      end
    end

    private def sanitize_body(body)
      return nil unless body

      if body.is_a?(String) && body.length > 1000
        "#{body[0..1000]}... (truncated)"
      else
        body
      end
    end
  end
end
