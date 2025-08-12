# frozen_string_literal: true

RSpec.describe Attio::HttpClient do
  let(:base_url) { "https://api.example.com" }
  let(:headers) { { "Authorization" => "Bearer token" } }
  let(:timeout) { 30 }
  let(:client) { described_class.new(base_url: base_url, headers: headers, timeout: timeout) }
  let(:rate_limiter) { instance_double(Attio::RateLimiter) }
  let(:client_with_rate_limiter) { described_class.new(base_url: base_url, headers: headers, timeout: timeout, rate_limiter: rate_limiter) }

  describe "#initialize" do
    it "sets the base URL" do
      expect(client.base_url).to eq(base_url)
    end

    it "sets the headers" do
      expect(client.headers).to eq(headers)
    end

    it "sets the timeout" do
      expect(client.timeout).to eq(timeout)
    end

    it "uses default timeout if not provided" do
      client = described_class.new(base_url: base_url, headers: headers)
      expect(client.timeout).to eq(Attio::HttpClient::DEFAULT_TIMEOUT)
    end

    it "accepts optional rate limiter" do
      client = described_class.new(base_url: base_url, headers: headers, rate_limiter: rate_limiter)
      expect(client.rate_limiter).to eq(rate_limiter)
    end

    it "defaults rate limiter to nil" do
      expect(client.rate_limiter).to be_nil
    end
  end

  describe "HTTP methods" do
    let(:path) { "test" }
    let(:params) { { foo: "bar" } }
    let(:body) { { data: "test" } }

    before do
      # Mock Typhoeus responses
      @response = double("Typhoeus::Response")
      allow(@response).to receive_messages(code: 200, body: '{"result":"success"}')

      @request = double("Typhoeus::Request")
      allow(@request).to receive(:run).and_return(@response)
      allow(Typhoeus::Request).to receive(:new).and_return(@request)
    end

    describe "#get" do
      it "makes a GET request with params" do
        expect(Typhoeus::Request).to receive(:new).with(
          "#{base_url}/#{path}",
          hash_including(method: :get, params: params)
        ).and_return(@request)

        result = client.get(path, params)
        expect(result).to eq({ "result" => "success" })
      end
    end

    describe "#post" do
      it "makes a POST request with body" do
        expect(Typhoeus::Request).to receive(:new).with(
          "#{base_url}/#{path}",
          hash_including(method: :post, body: body.to_json)
        ).and_return(@request)

        result = client.post(path, body)
        expect(result).to eq({ "result" => "success" })
      end
    end

    describe "#patch" do
      it "makes a PATCH request with body" do
        expect(Typhoeus::Request).to receive(:new).with(
          "#{base_url}/#{path}",
          hash_including(method: :patch, body: body.to_json)
        ).and_return(@request)

        result = client.patch(path, body)
        expect(result).to eq({ "result" => "success" })
      end
    end

    describe "#put" do
      it "makes a PUT request with body" do
        expect(Typhoeus::Request).to receive(:new).with(
          "#{base_url}/#{path}",
          hash_including(method: :put, body: body.to_json)
        ).and_return(@request)

        result = client.put(path, body)
        expect(result).to eq({ "result" => "success" })
      end
    end

    describe "#delete" do
      it "makes a DELETE request without body" do
        expect(Typhoeus::Request).to receive(:new).with(
          "#{base_url}/#{path}",
          hash_including(method: :delete)
        ).and_return(@request)

        result = client.delete(path)
        expect(result).to eq({ "result" => "success" })
      end

      it "makes a DELETE request with body" do
        expect(Typhoeus::Request).to receive(:new).with(
          "#{base_url}/#{path}",
          hash_including(method: :delete, body: body.to_json)
        ).and_return(@request)

        result = client.delete(path, body)
        expect(result).to eq({ "result" => "success" })
      end
    end
  end

  describe "error handling" do
    let(:path) { "test" }
    let(:response) { double("Typhoeus::Response") }
    let(:request) { double("Typhoeus::Request") }

    before do
      allow(request).to receive(:run).and_return(response)
      allow(Typhoeus::Request).to receive(:new).and_return(request)
    end

    context "when request times out" do
      it "raises TimeoutError" do
        allow(response).to receive_messages(code: 0, timed_out?: true)

        expect { client.get(path) }.to raise_error(Attio::HttpClient::TimeoutError, "Request timed out")
      end
    end

    context "when connection fails" do
      it "raises ConnectionError" do
        allow(response).to receive_messages(code: 0, timed_out?: false, return_message: "Connection refused")

        expect do
          client.get(path)
        end.to raise_error(Attio::HttpClient::ConnectionError, "Connection failed: Connection refused")
      end
    end

    context "when authentication fails" do
      it "raises AuthenticationError" do
        allow(response).to receive_messages(code: 401, body: '{"error":"Invalid API key"}')

        expect { client.get(path) }.to raise_error(Attio::AuthenticationError, "Invalid API key")
      end
    end

    context "when resource not found" do
      it "raises NotFoundError" do
        allow(response).to receive_messages(code: 404, body: '{"message":"Resource not found"}')

        expect { client.get(path) }.to raise_error(Attio::NotFoundError, "Resource not found")
      end
    end

    context "when validation fails" do
      it "raises ValidationError" do
        allow(response).to receive_messages(code: 422, body: '{"error":"Validation failed"}')

        expect { client.get(path) }.to raise_error(Attio::ValidationError, "Validation failed")
      end
    end

    context "when rate limited" do
      it "raises RateLimitError" do
        allow(response).to receive_messages(code: 429, body: '{"error":"Rate limit exceeded"}')
        allow(response).to receive(:headers).and_return({})

        expect { client.get(path) }.to raise_error(Attio::RateLimitError, "Rate limit exceeded")
      end

      it "includes retry_after when provided in headers" do
        allow(response).to receive_messages(code: 429, body: '{"error":"Rate limit exceeded"}')
        allow(response).to receive(:headers).and_return({ "Retry-After" => "120" })

        expect { client.get(path) }.to raise_error do |error|
          expect(error).to be_a(Attio::RateLimitError)
          expect(error.retry_after).to eq(120)
          expect(error.code).to eq(429)
        end
      end

      it "handles invalid retry_after header" do
        allow(response).to receive_messages(code: 429, body: '{"error":"Rate limit exceeded"}')
        allow(response).to receive(:headers).and_return({ "Retry-After" => "invalid" })

        expect { client.get(path) }.to raise_error do |error|
          expect(error).to be_a(Attio::RateLimitError)
          expect(error.retry_after).to eq(60) # Default fallback
        end
      end
    end

    context "when server error occurs" do
      it "raises ServerError" do
        allow(response).to receive_messages(code: 500, body: '{"error":"Internal server error"}')

        expect { client.get(path) }.to raise_error(Attio::ServerError, "Internal server error")
      end
    end

    context "when unexpected status code" do
      it "raises generic Error" do
        allow(response).to receive_messages(code: 418, body: '{"error":"I am a teapot"}')

        expect { client.get(path) }.to raise_error(Attio::Error, "Request failed with status 418: I am a teapot")
      end
    end

    context "when body is empty" do
      it "returns empty hash" do
        allow(response).to receive_messages(code: 200, body: "")

        expect(client.get(path)).to eq({})
      end
    end

    context "when body has invalid JSON" do
      it "raises Error" do
        allow(response).to receive_messages(code: 200, body: "invalid json")

        expect { client.get(path) }.to raise_error(Attio::Error, /Invalid JSON response/)
      end
    end

    context "when error response has non-JSON body" do
      it "uses body as error message" do
        allow(response).to receive_messages(code: 500, body: "Plain text error")

        expect { client.get(path) }.to raise_error(Attio::ServerError, "Plain text error")
      end
    end
  end

  describe "rate limiting integration" do
    let(:path) { "test" }
    let(:response) { double("Typhoeus::Response") }
    let(:request) { double("Typhoeus::Request") }

    before do
      allow(request).to receive(:run).and_return(response)
      allow(Typhoeus::Request).to receive(:new).and_return(request)
    end

    context "when rate limiter is present" do
      it "executes request through rate limiter" do
        allow(rate_limiter).to receive(:execute).and_yield
        allow(response).to receive_messages(code: 200, body: '{"result":"success"}')
        allow(response).to receive(:headers).and_return({
          "X-RateLimit-Limit" => "1000",
          "X-RateLimit-Remaining" => "999",
          "X-RateLimit-Reset" => "1642684800"
        })

        result = client_with_rate_limiter.get(path)

        expect(rate_limiter).to have_received(:execute)
        expect(result).to include(
          "result" => "success",
          "_headers" => {
            "x-ratelimit-limit" => "1000",
            "x-ratelimit-remaining" => "999",
            "x-ratelimit-reset" => "1642684800"
          }
        )
      end

      it "propagates rate limiter errors" do
        allow(rate_limiter).to receive(:execute).and_raise(Attio::RateLimitError.new("Rate limited by client"))

        expect { client_with_rate_limiter.get(path) }.to raise_error(Attio::RateLimitError, "Rate limited by client")
      end

      it "extracts rate limit headers from successful responses" do
        allow(rate_limiter).to receive(:execute).and_yield
        allow(response).to receive_messages(code: 200, body: '{"data":"test"}')
        allow(response).to receive(:headers).and_return({
          "Content-Type" => "application/json",
          "X-RateLimit-Limit" => "5000",
          "X-RateLimit-Remaining" => "4999",
          "X-RateLimit-Reset" => "1642684800",
          "Other-Header" => "ignored"
        })

        result = client_with_rate_limiter.get(path)

        expect(result["_headers"]).to eq({
          "x-ratelimit-limit" => "5000",
          "x-ratelimit-remaining" => "4999",
          "x-ratelimit-reset" => "1642684800"
        })
      end

      it "handles missing rate limit headers gracefully" do
        allow(rate_limiter).to receive(:execute).and_yield
        allow(response).to receive_messages(code: 200, body: '{"data":"test"}')
        allow(response).to receive(:headers).and_return({ "Content-Type" => "application/json" })

        result = client_with_rate_limiter.get(path)

        expect(result["_headers"]).to eq({})
      end
    end

    context "when rate limiter is not present" do
      it "does not add headers to response" do
        allow(response).to receive_messages(code: 200, body: '{"result":"success"}')

        result = client.get(path)

        expect(result).to eq({ "result" => "success" })
        expect(result).not_to have_key("_headers")
      end

      it "still handles 429 responses properly" do
        allow(response).to receive_messages(code: 429, body: '{"error":"Rate limit exceeded"}')
        allow(response).to receive(:headers).and_return({ "Retry-After" => "60" })

        expect { client.get(path) }.to raise_error do |error|
          expect(error).to be_a(Attio::RateLimitError)
          expect(error.retry_after).to eq(60)
        end
      end
    end
  end
end
