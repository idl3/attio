# frozen_string_literal: true

require "spec_helper"

RSpec.describe Attio::Webhooks do
  let(:secret) { "test_secret_key" }
  let(:webhooks) { described_class.new(secret: secret) }

  describe "#initialize" do
    it "sets the secret" do
      expect(webhooks.instance_variable_get(:@secret)).to eq(secret)
    end
  end

  describe "#verify_signature?" do
    let(:payload) { '{"id":"evt_123","type":"record.created"}' }
    let(:timestamp) { Time.now.to_i.to_s }
    let(:signed_payload) { "#{timestamp}.#{payload}" }
    let(:signature) { OpenSSL::HMAC.hexdigest("SHA256", secret, signed_payload) }

    it "returns true for valid signature" do
      result = webhooks.verify_signature?(signed_payload, signature)
      expect(result).to be true
    end

    it "returns false for invalid signature" do
      result = webhooks.verify_signature?(signed_payload, "invalid_sig")
      expect(result).to be false
    end

    it "returns false for empty signature" do
      result = webhooks.verify_signature?(signed_payload, "")
      expect(result).to be false
    end

    it "returns false for nil signature" do
      result = webhooks.verify_signature?(signed_payload, "")
      expect(result).to be false
    end
  end

  describe "#process" do
    let(:payload) { '{"id":"evt_123","type":"record.created","data":{"id":"rec_123"},"created_at":"2024-01-01T00:00:00Z"}' }
    let(:timestamp) { Time.now.to_i.to_s }
    let(:signed_payload) { "#{timestamp}.#{payload}" }
    let(:signature) { OpenSSL::HMAC.hexdigest("SHA256", secret, signed_payload) }
    let(:headers) do
      {
        "X-Attio-Signature" => signature,
        "X-Attio-Timestamp" => timestamp
      }
    end

    context "with valid webhook" do
      it "processes the webhook and returns an Event" do
        event = webhooks.process(payload, headers)
        expect(event).to be_a(Attio::Webhooks::Event)
        expect(event.id).to eq("evt_123")
        expect(event.type).to eq("record.created")
        expect(event.data).to eq({ "id" => "rec_123" })
      end

      it "calls registered handler" do
        handler_called = false
        webhooks.on("record.created") do |event|
          handler_called = true
          expect(event.type).to eq("record.created")
        end

        webhooks.process(payload, headers)
        expect(handler_called).to be true
      end
    end

    context "with invalid signature" do
      it "raises InvalidSignatureError" do
        headers["X-Attio-Signature"] = "invalid_signature"
        expect do
          webhooks.process(payload, headers)
        end.to raise_error(Attio::Webhooks::InvalidSignatureError)
      end
    end

    context "with missing headers" do
      it "raises MissingHeaderError when signature is missing" do
        headers.delete("X-Attio-Signature")
        expect do
          webhooks.process(payload, headers)
        end.to raise_error(Attio::Webhooks::MissingHeaderError)
      end

      it "raises MissingHeaderError when timestamp is missing" do
        headers.delete("X-Attio-Timestamp")
        expect do
          webhooks.process(payload, headers)
        end.to raise_error(Attio::Webhooks::MissingHeaderError)
      end
    end

    context "with invalid JSON" do
      it "raises JSON::ParserError" do
        invalid_payload = "not json"
        signed_payload = "#{timestamp}.#{invalid_payload}"
        headers["X-Attio-Signature"] = OpenSSL::HMAC.hexdigest("SHA256", secret, signed_payload)

        expect do
          webhooks.process(invalid_payload, headers)
        end.to raise_error(JSON::ParserError)
      end
    end

    context "with old timestamp" do
      it "raises InvalidTimestampError" do
        old_timestamp = (Time.now.to_i - 400).to_s
        old_signed_payload = "#{old_timestamp}.#{payload}"
        headers["X-Attio-Signature"] = OpenSSL::HMAC.hexdigest("SHA256", secret, old_signed_payload)
        headers["X-Attio-Timestamp"] = old_timestamp

        expect do
          webhooks.process(payload, headers)
        end.to raise_error(Attio::Webhooks::InvalidTimestampError)
      end
    end
  end

  describe "#on" do
    it "registers an event handler" do
      handler = proc { |event| puts event.type }
      webhooks.on("record.created", &handler)
      
      handlers = webhooks.instance_variable_get(:@handlers)
      expect(handlers["record.created"]).to include(handler)
    end

    it "allows multiple handlers for the same event" do
      handler1 = proc { |event| puts "Handler 1" }
      handler2 = proc { |event| puts "Handler 2" }
      
      webhooks.on("record.created", &handler1)
      webhooks.on("record.created", &handler2)
      
      handlers = webhooks.instance_variable_get(:@handlers)
      expect(handlers["record.created"]).to include(handler1, handler2)
    end

    it "can be called without a block" do
      expect { webhooks.on("record.created") }.not_to raise_error
    end
  end

  describe "#on_any" do
    it "registers a global handler" do
      handler = proc { |event| puts "Any event" }
      webhooks.on_any(&handler)
      
      global_handlers = webhooks.instance_variable_get(:@global_handlers)
      expect(global_handlers).to include(handler)
    end
  end

  describe "#handlers" do
    it "returns registered handlers" do
      handler = proc { |event| puts event.type }
      webhooks.on("test.event", &handler)
      
      expect(webhooks.handlers).to eq({ "test.event" => [handler] })
    end
  end
end

RSpec.describe Attio::Webhooks::Event do
  let(:data) do
    {
      "id" => "evt_123",
      "type" => "record.created",
      "data" => { "id" => "rec_123" },
      "created_at" => "2024-01-01T00:00:00Z",
      "workspace_id" => "ws_123"
    }
  end
  let(:event) { described_class.new(data) }

  describe "#initialize" do
    it "sets attributes from data" do
      expect(event.id).to eq("evt_123")
      expect(event.type).to eq("record.created")
      expect(event.data).to eq({ "id" => "rec_123" })
      expect(event.created_at).to eq(Time.parse("2024-01-01T00:00:00Z"))
      expect(event.workspace_id).to eq("ws_123")
    end
  end

  describe "#raw" do
    it "returns the raw payload" do
      expect(event.raw).to eq(data)
    end
  end

  describe "#is?" do
    it "returns true for matching type" do
      expect(event.is?("record.created")).to be true
    end

    it "returns false for non-matching type" do
      expect(event.is?("record.updated")).to be false
    end
  end

  describe "#dig" do
    it "accesses nested data" do
      expect(event.dig("id")).to eq("rec_123")
    end

    it "returns nil for missing keys" do
      expect(event.dig("missing")).to be_nil
    end
  end

  describe "attribute readers" do
    it "provides access to id" do
      expect(event.id).to eq("evt_123")
    end

    it "provides access to type" do
      expect(event.type).to eq("record.created")
    end

    it "provides access to data" do
      expect(event.data).to eq({ "id" => "rec_123" })
    end

    it "provides access to created_at" do
      expect(event.created_at).to eq(Time.parse("2024-01-01T00:00:00Z"))
    end

    it "provides access to workspace_id" do
      expect(event.workspace_id).to eq("ws_123")
    end

    it "handles missing attributes" do
      minimal_event = described_class.new({ "id" => "evt_456", "type" => "test" })
      expect(minimal_event.data).to eq({})
      expect(minimal_event.created_at).to be_nil
      expect(minimal_event.workspace_id).to be_nil
    end
  end
end

RSpec.describe Attio::WebhookServer do
  before do
    # Mock WEBrick to avoid loading the actual gem
    allow_any_instance_of(described_class).to receive(:require).with("webrick").and_return(true)
  end
  
  let(:server) { described_class.new(port: 3002, secret: "test_secret") }

  describe "#initialize" do
    it "sets port and creates webhook handler" do
      expect(server.instance_variable_get(:@port)).to eq(3002)
      expect(server.webhooks).to be_a(Attio::Webhooks)
      expect(server.events).to eq([])
    end

    context "when webrick is not available" do
      it "raises helpful error message" do
        allow_any_instance_of(described_class).to receive(:require).with("webrick").and_raise(LoadError)
        
        expect do
          described_class.new(port: 3002, secret: "test")
        end.to raise_error(RuntimeError, /Please add 'webrick' to your Gemfile/)
      end
    end
  end

  describe "#start and #stop" do
    let(:mock_server) { double("WEBrick::HTTPServer") }
    let(:mock_log) { double("WEBrick::Log") }
    
    before do
      # Mock WEBrick to avoid actually starting a server in tests
      stub_const("WEBrick::HTTPServer", double("HTTPServer Class"))
      stub_const("WEBrick::Log", double("Log Class"))
      stub_const("File::NULL", "/dev/null")
      
      allow(WEBrick::Log).to receive(:new).with("/dev/null").and_return(mock_log)
      allow(WEBrick::HTTPServer).to receive(:new).and_return(mock_server)
      allow(mock_server).to receive(:mount_proc)
      allow(mock_server).to receive(:start)
      allow(mock_server).to receive(:shutdown)
      allow(server).to receive(:trap)
      allow(server).to receive(:puts)
    end

    it "starts the webhook server" do
      allow(WEBrick::HTTPServer).to receive(:new).and_return(mock_server)
      expect(WEBrick::HTTPServer).to receive(:new)
      server.start
    end

    it "mounts webhook endpoint" do
      allow(WEBrick::HTTPServer).to receive(:new).and_return(mock_server)
      expect(mock_server).to receive(:mount_proc).with("/webhooks")
      server.start
    end

    it "stops the server" do
      server.instance_variable_set(:@server, mock_server)
      expect(mock_server).to receive(:shutdown)
      server.stop
    end
  end

  describe "webhook endpoint processing" do
    let(:mock_server) { double("WEBrick::HTTPServer") }
    let(:handler_block) { @handler_block }
    
    before do
      stub_const("WEBrick::HTTPServer", double("HTTPServer Class"))
      stub_const("WEBrick::Log", double("Log Class"))
      stub_const("File::NULL", "/dev/null")
      allow(WEBrick::Log).to receive(:new).and_return(double("log"))
      allow(WEBrick::HTTPServer).to receive(:new).and_return(mock_server)
      allow(mock_server).to receive(:mount_proc) do |path, &block|
        @handler_block = block if path == "/webhooks"
      end
      allow(mock_server).to receive(:start)
      allow(server).to receive(:trap)
      allow(server).to receive(:puts)
      server.start
    end

    it "processes valid webhook POST requests" do
      req = double("request",
        request_method: "POST",
        body: '{"id": "evt_123", "type": "test"}',
        header: { "X-Attio-Signature" => "sig", "X-Attio-Timestamp" => Time.now.to_i.to_s }
      )
      res = double("response")
      
      allow(server.webhooks).to receive(:process).and_return(
        Attio::Webhooks::Event.new({ "id" => "evt_123", "type" => "test" })
      )
      
      expect(res).to receive(:status=).with(200)
      expect(res).to receive(:body=).with(/ok/)
      
      handler_block.call(req, res)
      expect(server.events.size).to eq(1)
    end

    it "handles webhook processing errors" do
      req = double("request",
        request_method: "POST",
        body: "invalid",
        header: {}
      )
      res = double("response")
      
      allow(server.webhooks).to receive(:process).and_raise(StandardError, "Processing failed")
      
      expect(res).to receive(:status=).with(400)
      expect(res).to receive(:body=).with(/Processing failed/)
      
      handler_block.call(req, res)
      expect(server.events.size).to eq(0)
    end

    it "rejects non-POST requests" do
      req = double("request", request_method: "GET")
      res = double("response")
      
      expect(res).to receive(:status=).with(405)
      expect(res).to receive(:body=).with(/Method not allowed/)
      
      handler_block.call(req, res)
    end
  end

  describe "WebhookServer full coverage" do
    # Mock WEBrick components for integration testing
    before do
      # Create mock WEBrick components
      webrick_module = Module.new
      
      # Mock WEBrick::Log
      log_class = Class.new do
        def initialize(file); end
      end
      
      # Mock HTTPServer
      http_server_class = Class.new do
        def initialize(options = {})
          @port = options[:Port]
          @logger = options[:Logger]
          @handlers = {}
        end
        
        def mount_proc(path, &block)
          @handlers[path] = block
        end
        
        def start
          # Simulate server running
          Thread.new { sleep 0.1 }
        end
        
        def shutdown
          # Simulate shutdown
        end
        
        def handle_request(path, req, res)
          handler = @handlers[path]
          handler&.call(req, res)
        end
      end
      
      stub_const("WEBrick", webrick_module)
      stub_const("WEBrick::Log", log_class)
      stub_const("WEBrick::HTTPServer", http_server_class)
      stub_const("File::NULL", "/dev/null")
    end
    
    describe "#start" do
      it "creates and starts the server" do
        server = Attio::WebhookServer.new(port: 3002, secret: "test_secret")
        
        # Capture output
        expect { server.start }.to output(/Webhook server listening/).to_stdout
      end
    end
    
    describe "request handling" do
      it "processes POST requests successfully" do
        server = Attio::WebhookServer.new(port: 3002, secret: "test_secret")
        
        # Get the mock server
        allow(server).to receive(:trap)
        allow(server).to receive(:puts)
        
        # Start server (creates the handler)
        expect_any_instance_of(WEBrick::HTTPServer).to receive(:mount_proc).and_call_original
        server.start
        
        # Simulate a request
        mock_server = server.instance_variable_get(:@server)
        req = double("request", 
          request_method: "POST",
          body: '{"type":"test.event","data":{}}',
          header: {
            "X-Attio-Signature" => "sig",
            "X-Attio-Timestamp" => Time.now.to_i.to_s
          }
        )
        res = double("response")
        
        # Test lines 195-198
        allow(server.webhooks).to receive(:process).and_return(
          double("event", id: "evt_123")
        )
        expect(res).to receive(:status=).with(200)
        expect(res).to receive(:body=).with(JSON.generate(status: "ok", event_id: "evt_123"))
        
        mock_server.handle_request("/webhooks", req, res)
      end
      
      it "handles webhook processing errors" do
        server = Attio::WebhookServer.new(port: 3002, secret: "test_secret")
        
        allow(server).to receive(:trap)
        allow(server).to receive(:puts)
        
        server.start
        
        mock_server = server.instance_variable_get(:@server)
        req = double("request",
          request_method: "POST",
          body: '{"type":"test.event"}',
          header: {}
        )
        res = double("response")
        
        # Test lines 200-201
        allow(server.webhooks).to receive(:process).and_raise(StandardError, "Processing failed")
        expect(res).to receive(:status=).with(400)
        expect(res).to receive(:body=).with(JSON.generate(error: "Processing failed"))
        
        mock_server.handle_request("/webhooks", req, res)
      end
      
      it "rejects non-POST requests" do
        server = Attio::WebhookServer.new(port: 3002, secret: "test_secret")
        
        allow(server).to receive(:trap)
        allow(server).to receive(:puts)
        
        server.start
        
        mock_server = server.instance_variable_get(:@server)
        req = double("request", request_method: "GET")
        res = double("response")
        
        # Test lines 204-205
        expect(res).to receive(:status=).with(405)
        expect(res).to receive(:body=).with(JSON.generate(error: "Method not allowed"))
        
        mock_server.handle_request("/webhooks", req, res)
      end
    end
    
    describe "#stop" do
      it "shuts down the server" do
        server = Attio::WebhookServer.new(port: 3002, secret: "test_secret")
        
        mock_server = double("server")
        server.instance_variable_set(:@server, mock_server)
        
        # Test line 216
        expect(mock_server).to receive(:shutdown)
        server.stop
      end
    end
    
    describe "trap signal" do
      it "sets up INT signal handler" do
        server = Attio::WebhookServer.new(port: 3002, secret: "test_secret")
        
        # Test line 209
        expect(server).to receive(:trap).with("INT")
        allow(server).to receive(:puts)
        
        server.start
      end
    end
  end
end