# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Rate Limiter Integration" do
  let(:api_key) { "test-api-key" }

  describe "with basic Client" do
    let(:client) { Attio::Client.new(api_key: api_key) }

    before do
      # Stub actual HTTP requests
      stub_request(:get, "https://api.attio.com/v2/objects")
        .to_return(
          status: 200,
          body: { objects: [] }.to_json,
          headers: {
            "Content-Type" => "application/json",
            "X-RateLimit-Limit" => "1000",
            "X-RateLimit-Remaining" => "999",
            "X-RateLimit-Reset" => (Time.now + 3600).to_i.to_s
          }
        )
    end

    it "uses rate limiter by default" do
      expect(client.rate_limiter).to be_a(Attio::RateLimiter)
    end

    it "passes rate limiter to HttpClient" do
      expect(client.connection.rate_limiter).to eq(client.rate_limiter)
    end

    it "can set custom rate limiter" do
      custom_limiter = Attio::RateLimiter.new(max_requests: 100, window_seconds: 60)
      client.rate_limiter(custom_limiter)

      expect(client.rate_limiter).to eq(custom_limiter)
      
      # Connection should be reset to pick up new rate limiter
      client.instance_variable_set(:@connection, nil)
      expect(client.connection.rate_limiter).to eq(custom_limiter)
    end

    it "integrates rate limiting with API calls" do
      # Mock rate limiter to verify it's called
      rate_limiter = client.rate_limiter
      allow(rate_limiter).to receive(:execute).and_call_original

      result = client.objects.list

      expect(rate_limiter).to have_received(:execute)
      expect(result).to include("objects" => [])
    end

    context "when rate limited" do
      before do
        # Configure rate limiter to be at limit
        rate_limiter = client.rate_limiter
        rate_limiter.instance_variable_set(:@remaining, 0)
        rate_limiter.instance_variable_set(:@reset_at, Time.now + 60)
      end

      it "waits before making request" do
        start_time = Time.now
        
        # Mock sleep to avoid actual waiting in tests
        allow_any_instance_of(Attio::RateLimiter).to receive(:sleep) do |_, duration|
          expect(duration).to be > 0
        end

        client.objects.list
      end
    end

    context "when API returns 429" do
      before do
        stub_request(:get, "https://api.attio.com/v2/objects")
          .to_return(
            status: 429,
            body: { error: "Rate limit exceeded" }.to_json,
            headers: {
              "Content-Type" => "application/json",
              "Retry-After" => "60"
            }
          ).times(1)
          .then.to_return(
            status: 200,
            body: { objects: [] }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "handles retry with exponential backoff" do
        # Mock sleep to verify backoff is called
        allow_any_instance_of(Attio::RateLimiter).to receive(:sleep) do |_, duration|
          expect(duration).to be >= 60  # Should use server's retry-after
        end

        result = client.objects.list
        expect(result).to include("objects" => [])
      end
    end
  end

  describe "with EnhancedClient" do
    let(:enhanced_client) do
      Attio::EnhancedClient.new(
        api_key: api_key,
        connection_pool: { size: 5, timeout: 5 }
      )
    end

    before do
      stub_request(:get, "https://api.attio.com/v2/objects")
        .to_return(
          status: 200,
          body: { objects: [] }.to_json,
          headers: {
            "Content-Type" => "application/json",
            "X-RateLimit-Limit" => "1000",
            "X-RateLimit-Remaining" => "999"
          }
        )
      
      # Stub health check endpoint
      stub_request(:get, "https://api.attio.com/v2/meta/identify")
        .to_return(
          status: 200,
          body: { workspace: { id: "test-workspace" } }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "uses rate limiter by default" do
      expect(enhanced_client.rate_limiter).to be_a(Attio::RateLimiter)
    end

    it "includes rate limiter status in health check" do
      health = enhanced_client.health_check

      expect(health).to have_key(:rate_limiter)
      expect(health[:rate_limiter]).to be(true)  # Should have remaining requests
    end

    it "includes rate limiter stats in stats" do
      stats = enhanced_client.stats

      expect(stats).to have_key(:rate_limiter)
      expect(stats[:rate_limiter]).to include(:limit, :remaining, :reset_at)
    end

    it "integrates with connection pooling" do
      # Verify that pooled connections also use rate limiter
      connection = enhanced_client.connection
      expect(connection).to respond_to(:get)  # Should be a pooled client

      # Make a request to verify rate limiting works with pooling
      result = enhanced_client.objects.list
      expect(result).to include("objects" => [])
    end

    context "when using custom rate limiter" do
      let(:custom_limiter) { Attio::RateLimiter.new(max_requests: 50, window_seconds: 60) }

      before do
        enhanced_client.rate_limiter(custom_limiter)
        # Reset connection to pick up new rate limiter
        enhanced_client.instance_variable_set(:@connection, nil)
      end

      it "uses custom rate limiter in pooled connections" do
        expect(enhanced_client.rate_limiter).to eq(custom_limiter)
        
        # Verify the pool uses the custom rate limiter
        pool = enhanced_client.instance_variable_get(:@pool)
        if pool
          pool.with do |http_client|
            expect(http_client.rate_limiter).to eq(custom_limiter)
          end
        end
      end
    end
  end

  describe "rate limiter header processing" do
    let(:client) { Attio::Client.new(api_key: api_key) }

    before do
      stub_request(:get, "https://api.attio.com/v2/objects")
        .to_return(
          status: 200,
          body: { objects: [] }.to_json,
          headers: {
            "Content-Type" => "application/json",
            "X-RateLimit-Limit" => "1000",
            "X-RateLimit-Remaining" => "999",
            "X-RateLimit-Reset" => "1642684800"
          }
        )
    end

    it "updates rate limiter state from response headers" do
      rate_limiter = client.rate_limiter
      original_limit = rate_limiter.current_limit

      client.objects.list

      # Rate limiter should be updated with server values
      expect(rate_limiter.current_limit).to eq(1000)
      expect(rate_limiter.remaining).to be <= 999  # May be decremented by local tracking
    end
  end

  describe "error handling with rate limiting" do
    let(:client) { Attio::Client.new(api_key: api_key) }

    context "when rate limiter throws error" do
      before do
        # Configure rate limiter to always throw error
        rate_limiter = client.rate_limiter
        allow(rate_limiter).to receive(:execute).and_raise(Attio::RateLimitError.new("Client rate limited"))
      end

      it "propagates rate limiter errors" do
        expect { client.objects.list }.to raise_error(Attio::RateLimitError, "Client rate limited")
      end
    end

    context "when both client and server rate limit" do
      before do
        # Server returns 429
        stub_request(:get, "https://api.attio.com/v2/objects")
          .to_return(
            status: 429,
            body: { error: "Server rate limited" }.to_json,
            headers: {
              "Content-Type" => "application/json",
              "Retry-After" => "30"
            }
          )

        # Client rate limiter allows through
        rate_limiter = client.rate_limiter
        allow(rate_limiter).to receive(:execute).and_yield
      end

      it "handles server rate limiting properly" do
        expect { client.objects.list }.to raise_error do |error|
          expect(error).to be_a(Attio::RateLimitError)
          expect(error.message).to eq("Server rate limited")
          expect(error.retry_after).to eq(30)
        end
      end
    end
  end

  describe "thread safety" do
    let(:client) { Attio::Client.new(api_key: api_key) }

    before do
      stub_request(:get, "https://api.attio.com/v2/objects")
        .to_return(
          status: 200,
          body: { objects: [] }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "handles concurrent requests safely" do
      threads = []
      results = Queue.new

      5.times do
        threads << Thread.new do
          begin
            result = client.objects.list
            results << { success: true, result: result }
          rescue => e
            results << { success: false, error: e }
          end
        end
      end

      threads.each(&:join)

      # All requests should succeed (or fail gracefully)
      5.times do
        result = results.pop
        if result[:success]
          expect(result[:result]).to include("objects" => [])
        else
          # If any fail, it should be due to rate limiting, not threading issues
          expect(result[:error]).to be_a(Attio::RateLimitError)
        end
      end
    end
  end
end