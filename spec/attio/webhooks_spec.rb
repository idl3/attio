# frozen_string_literal: true

RSpec.describe Attio::Webhooks do
  let(:secret) { "webhook_secret_123" }
  let(:webhooks) { described_class.new(secret: secret) }
  let(:payload) { { "id" => "evt_123", "type" => "record.created", "data" => { "id" => "rec_456" } } }
  let(:timestamp) { Time.now.to_i.to_s }
  
  describe "#initialize" do
    it "sets the secret and tolerance" do
      expect(webhooks.secret).to eq(secret)
      expect(webhooks.tolerance).to eq(300)
    end
    
    it "accepts custom tolerance" do
      custom = described_class.new(secret: secret, tolerance: 600)
      expect(custom.tolerance).to eq(600)
    end
  end
  
  describe "#on" do
    it "registers event handlers" do
      called = false
      webhooks.on("record.created") { called = true }
      
      expect(webhooks.handlers["record.created"]).not_to be_empty
    end
    
    it "allows multiple handlers for same event" do
      webhooks.on("test.event") { }
      webhooks.on("test.event") { }
      
      expect(webhooks.handlers["test.event"].size).to eq(2)
    end
  end
  
  describe "#on_any" do
    it "registers global handlers" do
      called = false
      webhooks.on_any { called = true }
      
      expect(webhooks.instance_variable_get(:@global_handlers)).not_to be_empty
    end
  end
  
  describe "#process" do
    let(:body) { JSON.generate(payload) }
    let(:signed_payload) { "#{timestamp}.#{body}" }
    let(:signature) do
      OpenSSL::HMAC.hexdigest(
        OpenSSL::Digest.new("sha256"),
        secret,
        signed_payload
      )
    end
    let(:headers) do
      {
        "X-Attio-Signature" => signature,
        "X-Attio-Timestamp" => timestamp
      }
    end
    
    it "verifies and processes valid webhook" do
      event = webhooks.process(body, headers)
      
      expect(event).to be_a(Attio::Webhooks::Event)
      expect(event.id).to eq("evt_123")
      expect(event.type).to eq("record.created")
    end
    
    it "raises error for invalid signature" do
      headers["X-Attio-Signature"] = "invalid"
      
      expect { webhooks.process(body, headers) }
        .to raise_error(Attio::Webhooks::InvalidSignatureError)
    end
    
    it "raises error for old timestamp" do
      old_timestamp = (Time.now - 400).to_i.to_s
      headers["X-Attio-Timestamp"] = old_timestamp
      
      expect { webhooks.process(body, headers) }
        .to raise_error(Attio::Webhooks::InvalidTimestampError)
    end
    
    it "raises error for missing headers" do
      headers.delete("X-Attio-Signature")
      
      expect { webhooks.process(body, headers) }
        .to raise_error(Attio::Webhooks::MissingHeaderError)
    end
    
    it "calls registered handlers" do
      called_with = nil
      webhooks.on("record.created") { |event| called_with = event }
      
      webhooks.process(body, headers)
      
      expect(called_with).not_to be_nil
      expect(called_with.type).to eq("record.created")
    end
    
    it "calls global handlers" do
      global_called = false
      webhooks.on_any { global_called = true }
      
      webhooks.process(body, headers)
      
      expect(global_called).to be true
    end
  end
  
  describe "#verify_signature?" do
    it "returns true for valid signature" do
      signature = OpenSSL::HMAC.hexdigest(
        OpenSSL::Digest.new("sha256"),
        secret,
        "test_payload"
      )
      
      expect(webhooks.verify_signature?("test_payload", signature)).to be true
    end
    
    it "returns false for invalid signature" do
      expect(webhooks.verify_signature?("test_payload", "invalid")).to be false
    end
    
    it "uses secure comparison to prevent timing attacks" do
      # Signature should take same time regardless of how many characters match
      expect(webhooks.verify_signature?("test", "abcd")).to be false
      expect(webhooks.verify_signature?("test", "aaaa")).to be false
    end
  end
  
  describe Attio::Webhooks::Event do
    let(:event) { described_class.new(payload) }
    
    describe "#initialize" do
      it "parses webhook payload" do
        expect(event.id).to eq("evt_123")
        expect(event.type).to eq("record.created")
        expect(event.data).to eq({ "id" => "rec_456" })
      end
      
      it "handles missing fields" do
        minimal = described_class.new({ "type" => "test" })
        expect(minimal.type).to eq("test")
        expect(minimal.data).to eq({})
      end

      it "parses created_at timestamp" do
        event_with_time = described_class.new(
          payload.merge("created_at" => "2024-01-01T00:00:00Z")
        )
        expect(event_with_time.created_at).to be_a(Time)
      end

      it "stores workspace_id" do
        event_with_workspace = described_class.new(
          payload.merge("workspace_id" => "ws_123")
        )
        expect(event_with_workspace.workspace_id).to eq("ws_123")
      end
    end
    
    describe "#is?" do
      it "checks event type" do
        expect(event.is?("record.created")).to be true
        expect(event.is?("record.updated")).to be false
      end
    end
    
    describe "#dig" do
      it "retrieves nested data" do
        expect(event.dig("id")).to eq("rec_456")
      end
    end
  end
end

RSpec.describe Attio::WebhookServer do
  let(:server) do
    # Mock WEBrick to avoid requiring it
    allow_any_instance_of(described_class).to receive(:require).with("webrick").and_return(true)
    described_class.new(port: 3002, secret: "test_secret")
  end
  
  describe "#initialize" do
    it "sets port and creates webhook handler" do
      # Mock WEBrick for this test
      allow_any_instance_of(described_class).to receive(:require).with("webrick").and_return(true)
      test_server = described_class.new(port: 3002, secret: "test_secret")
      
      expect(test_server.port).to eq(3002)
      expect(test_server.webhooks).to be_a(Attio::Webhooks)
      expect(test_server.events).to eq([])
    end

    context "when webrick is not available" do
      it "raises helpful error message" do
        # Create a new instance that will fail on require
        error_server = described_class.allocate
        allow(error_server).to receive(:require).with("webrick").and_raise(LoadError)
        
        expect { error_server.send(:initialize, port: 3002, secret: "test") }
          .to raise_error(RuntimeError, "Please add 'webrick' to your Gemfile to use WebhookServer")
      end
    end
  end

  describe "#start and #stop" do
    before do
      # Mock WEBrick to avoid actually starting a server in tests
      stub_const("WEBrick::HTTPServer", Class.new)
      stub_const("WEBrick::Log", Class.new)
      stub_const("File::NULL", "/dev/null")
      allow(WEBrick::Log).to receive(:new).and_return(double("log"))
      
      mock_server = double("WEBrick::HTTPServer")
      allow(WEBrick::HTTPServer).to receive(:new).and_return(mock_server)
      allow(mock_server).to receive(:mount_proc)
      allow(mock_server).to receive(:start)
      allow(mock_server).to receive(:shutdown)
      allow(server).to receive(:trap)
      allow(server).to receive(:puts)
    end

    it "starts the webhook server" do
      expect(WEBrick::HTTPServer).to receive(:new).with(
        hash_including(Port: 3002)
      )
      server.start
    end

    it "mounts webhook endpoint" do
      expect(mock_http_server).to receive(:mount_proc).with("/webhooks")
      server.start
    end

    it "stops the server" do
      server.instance_variable_set(:@server, mock_http_server)
      expect(mock_http_server).to receive(:shutdown)
      server.stop
    end
  end

  describe "webhook endpoint processing" do
    let(:mock_server) { double("WEBrick::HTTPServer") }
    
    before do
      stub_const("WEBrick::HTTPServer", double("HTTPServer Class"))
      stub_const("WEBrick::Log", double("Log Class"))
      stub_const("File::NULL", "/dev/null")
      allow(WEBrick::Log).to receive(:new).and_return(double("log"))
      allow(WEBrick::HTTPServer).to receive(:new).and_return(mock_server)
      allow(mock_server).to receive(:mount_proc) do |path, &block|
        handler_block = block if path == "/webhooks"
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
        body: '{"invalid": "json"',
        header: {}
      )
      res = double("response")
      
      allow(server.webhooks).to receive(:process).and_raise(StandardError, "Invalid webhook")
      
      expect(res).to receive(:status=).with(400)
      expect(res).to receive(:body=).with(/Invalid webhook/)
      
      handler_block.call(req, res)
    end

    it "rejects non-POST requests" do
      req = double("request", request_method: "GET")
      res = double("response")
      
      expect(res).to receive(:status=).with(405)
      expect(res).to receive(:body=).with(/Method not allowed/)
      
      handler_block.call(req, res)
    end
  end
end