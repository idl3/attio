# frozen_string_literal: true

require "openssl"
require "json"
require "time"

module Attio
  # Webhook handling for Attio events
  #
  # @example Configure webhooks
  #   webhooks = Attio::Webhooks.new(secret: ENV['ATTIO_WEBHOOK_SECRET'])
  #
  #   webhooks.on('record.created') do |event|
  #     puts "New record: #{event.data['id']}"
  #   end
  #
  #   # In your webhook endpoint
  #   webhooks.process(request.body.read, request.headers)
  class Webhooks
    class InvalidSignatureError < StandardError; end
    class InvalidTimestampError < StandardError; end
    class MissingHeaderError < StandardError; end

    # Default time window for timestamp validation (5 minutes)
    DEFAULT_TOLERANCE = 300

    attr_reader :secret, :handlers, :tolerance

    # Initialize webhook handler
    #
    # @param secret [String] Webhook signing secret from Attio
    # @param tolerance [Integer] Maximum age of webhook in seconds
    def initialize(secret:, tolerance: DEFAULT_TOLERANCE)
      @secret = secret
      @tolerance = tolerance
      @handlers = {}
      @global_handlers = []
    end

    # Register an event handler
    #
    # @param event_type [String] The event type to handle (e.g., 'record.created')
    # @yield [event] Block to execute when event is received
    # @yieldparam event [Event] The webhook event
    def on(event_type, &block)
      @handlers[event_type] ||= []
      @handlers[event_type] << block
    end

    # Register a global handler for all events
    #
    # @yield [event] Block to execute for any event
    def on_any(&block)
      @global_handlers << block
    end

    # Process incoming webhook
    #
    # @param payload [String] Raw request body
    # @param headers [Hash] Request headers
    # @return [Event] Processed webhook event
    # @raise [InvalidSignatureError] if signature verification fails
    # @raise [InvalidTimestampError] if timestamp is too old
    def process(payload, headers)
      verify_webhook!(payload, headers)

      event = Event.new(JSON.parse(payload))
      dispatch_event(event)
      event
    end

    # Verify webhook authenticity using HMAC-SHA256
    #
    # @param payload [String] Raw request body
    # @param signature [String] Signature from headers
    # @return [Boolean] True if valid
    def verify_signature?(payload, signature)
      expected = OpenSSL::HMAC.hexdigest(
        OpenSSL::Digest.new("sha256"),
        @secret,
        payload
      )

      # Use secure comparison to prevent timing attacks
      secure_compare?(expected, signature)
    end

    private def verify_webhook!(payload, headers)
      signature = extract_header(headers, "X-Attio-Signature")
      timestamp = extract_header(headers, "X-Attio-Timestamp")

      # Verify timestamp to prevent replay attacks
      verify_timestamp!(timestamp)

      # Verify signature
      signed_payload = "#{timestamp}.#{payload}"
      return if verify_signature?(signed_payload, signature)

      raise InvalidSignatureError, "Webhook signature verification failed"
    end

    private def extract_header(headers, name)
      # Handle different header formats (Rack, Rails, etc.)
      value = headers[name] ||
              headers[name.downcase] ||
              headers[name.upcase.gsub("-", "_")]

      raise MissingHeaderError, "Missing required header: #{name}" unless value

      value
    end

    private def verify_timestamp!(timestamp)
      webhook_time = Time.at(timestamp.to_i)
      current_time = Time.now

      return unless (current_time - webhook_time).abs > tolerance

      raise InvalidTimestampError,
            "Webhook timestamp outside of tolerance (#{tolerance}s)"
    end

    private def dispatch_event(event)
      # Call specific handlers
      @handlers[event.type].each { |handler| handler.call(event) } if @handlers[event.type]

      # Call global handlers
      @global_handlers.each { |handler| handler.call(event) }
    end

    private def secure_compare?(expected, actual)
      return false unless expected.bytesize == actual.bytesize

      expected_bytes = expected.unpack("C*")
      actual_bytes = actual.unpack("C*")
      result = 0

      expected_bytes.zip(actual_bytes) { |x, y| result |= x ^ y }
      result == 0
    end

    # Represents a webhook event
    class Event
      attr_reader :id, :type, :created_at, :data, :workspace_id, :raw

      def initialize(payload)
        @raw = payload
        @id = payload["id"]
        @type = payload["type"]
        @created_at = Time.parse(payload["created_at"]) if payload["created_at"]
        @data = payload["data"] || {}
        @workspace_id = payload["workspace_id"]
      end

      # Check if event is of a specific type
      #
      # @param type [String] Event type to check
      # @return [Boolean]
      def is?(type)
        @type == type
      end

      # Get nested data value
      #
      # @param path [String] Dot-separated path (e.g., 'record.id')
      # @return [Object] Value at path
      def dig(*path)
        @data.dig(*path)
      end
    end
  end

  # Webhook server for development/testing
  class WebhookServer
    attr_reader :port, :webhooks, :events

    def initialize(port: 3001, secret: "test_secret")
      begin
        require "webrick"
      rescue LoadError
        raise "Please add 'webrick' to your Gemfile to use WebhookServer"
      end
      @port = port
      @webhooks = Webhooks.new(secret: secret)
      @events = []
      @server = nil
    end

    def start
      @server = WEBrick::HTTPServer.new(Port: @port, Logger: WEBrick::Log.new(File::NULL))

      @server.mount_proc "/webhooks" do |req, res|
        if req.request_method == "POST"
          begin
            event = @webhooks.process(req.body, req.header)
            @events << event
            res.status = 200
            res.body = JSON.generate(status: "ok", event_id: event.id)
          rescue StandardError => e
            res.status = 400
            res.body = JSON.generate(error: e.message)
          end
        else
          res.status = 405
          res.body = JSON.generate(error: "Method not allowed")
        end
      end

      trap("INT") { stop }

      puts "Webhook server listening on http://localhost:#{@port}/webhooks"
      @server.start
    end

    def stop
      @server&.shutdown
    end
  end
end
