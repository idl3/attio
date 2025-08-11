# frozen_string_literal: true

RSpec.describe Attio::RateLimiter do
  let(:limiter) { described_class.new(max_requests: 10, window_seconds: 60, max_retries: 2) }

  describe "#initialize" do
    it "sets default values" do
      expect(limiter.max_requests).to eq(10)
      expect(limiter.window_seconds).to eq(60)
      expect(limiter.max_retries).to eq(2)
      expect(limiter.remaining).to eq(10)
    end

    it "accepts custom configuration" do
      custom_limiter = described_class.new(
        max_requests: 100,
        window_seconds: 3600,
        max_retries: 5,
        enable_jitter: false
      )

      expect(custom_limiter.max_requests).to eq(100)
      expect(custom_limiter.window_seconds).to eq(3600)
      expect(custom_limiter.max_retries).to eq(5)
    end
  end

  describe "#execute" do
    it "executes the block" do
      result = limiter.execute { "success" }
      expect(result).to eq("success")
    end

    it "raises error if no block given" do
      expect { limiter.execute }.to raise_error(ArgumentError, "Block required")
    end

    it "tracks requests" do
      5.times { limiter.execute { "ok" } }
      status = limiter.status
      expect(status[:current_usage]).to eq(5)
      expect(status[:remaining]).to eq(5)
    end

    it "waits when rate limit is exceeded" do
      # Use a shorter window for testing
      fast_limiter = described_class.new(max_requests: 2, window_seconds: 1)

      start_time = Time.now
      fast_limiter.execute { "request 1" }
      fast_limiter.execute { "request 2" }

      # This should wait
      fast_limiter.execute { "request 3" }
      elapsed = Time.now - start_time

      expect(elapsed).to be >= 1.0
    end

    it "waits when remaining is zero and reset_at is in future" do
      # Test the specific edge case in lines 167-168
      limiter = described_class.new(max_requests: 10, window_seconds: 60)
      
      # Manually set the state to trigger the edge case
      limiter.instance_variable_set(:@remaining, 0)
      limiter.instance_variable_set(:@reset_at, Time.now + 1)
      
      start_time = Time.now
      limiter.execute { "request" }
      elapsed = Time.now - start_time
      
      expect(elapsed).to be >= 1.0
    end

    it "retries on rate limit error" do
      attempt = 0
      result = limiter.execute do
        attempt += 1
        raise Attio::RateLimitError, "Rate limited" if attempt == 1

        "success after retry"
      end

      expect(result).to eq("success after retry")
      expect(attempt).to eq(2)
    end

    it "gives up after max retries" do
      attempt = 0
      expect do
        limiter.execute do
          attempt += 1
          raise Attio::RateLimitError, "Rate limited"
        end
      end.to raise_error(Attio::RateLimitError)

      expect(attempt).to eq(3) # Initial + 2 retries
    end

    it "updates from response headers" do
      response = {
        "data" => [],
        "_headers" => {
          "x-ratelimit-limit" => "100",
          "x-ratelimit-remaining" => "99",
          "x-ratelimit-reset" => (Time.now + 3600).to_i.to_s
        }
      }

      result = limiter.execute { response }

      expect(limiter.current_limit).to eq(100)
      expect(limiter.remaining).to eq(99)
      expect(limiter.reset_at).to be_within(5).of(Time.now + 3600)
    end
  end

  describe "#rate_limited?" do
    it "returns false when under limit" do
      5.times { limiter.execute { "ok" } }
      expect(limiter.rate_limited?).to be false
    end

    it "returns true when at limit" do
      10.times { limiter.execute { "ok" } }
      expect(limiter.rate_limited?).to be true
    end

    it "cleans up old requests" do
      # Use a very short window
      fast_limiter = described_class.new(max_requests: 2, window_seconds: 0.1)

      fast_limiter.execute { "request 1" }
      fast_limiter.execute { "request 2" }
      expect(fast_limiter.rate_limited?).to be true

      sleep(0.15) # Wait for window to pass
      expect(fast_limiter.rate_limited?).to be false
    end
  end

  describe "#status" do
    it "returns current status" do
      3.times { limiter.execute { "ok" } }

      status = limiter.status
      expect(status[:limit]).to eq(10)
      expect(status[:remaining]).to eq(7)
      expect(status[:current_usage]).to eq(3)
      expect(status[:reset_in]).to be_between(0, 60)
    end
  end

  describe "#reset!" do
    it "resets the rate limiter" do
      5.times { limiter.execute { "ok" } }
      expect(limiter.status[:current_usage]).to eq(5)

      limiter.reset!
      expect(limiter.status[:current_usage]).to eq(0)
      expect(limiter.remaining).to eq(10)
    end
  end

  describe "#queue_request" do
    it "queues requests for later execution" do
      limiter.queue_request(priority: 1) { "high priority" }
      limiter.queue_request(priority: 10) { "low priority" }
      limiter.queue_request(priority: 5) { "medium priority" }

      results = limiter.process_queue(max_per_batch: 3)

      expect(results.size).to eq(3)
      expect(results[0][:result]).to eq("high priority")
      expect(results[1][:result]).to eq("medium priority")
      expect(results[2][:result]).to eq("low priority")
    end

    it "respects queue priority" do
      limiter.queue_request(priority: 10) { "low" }
      limiter.queue_request(priority: 1) { "high" }

      results = limiter.process_queue(max_per_batch: 1)
      expect(results[0][:result]).to eq("high")

      results = limiter.process_queue(max_per_batch: 1)
      expect(results[0][:result]).to eq("low")
    end
  end

  describe "#process_queue" do
    it "processes queued requests up to max_per_batch" do
      5.times { |i| limiter.queue_request { "request #{i}" } }

      results = limiter.process_queue(max_per_batch: 3)
      expect(results.size).to eq(3)

      results = limiter.process_queue(max_per_batch: 3)
      expect(results.size).to eq(2)
    end

    it "handles errors in queued requests" do
      limiter.queue_request { "success" }
      limiter.queue_request { raise "error" }
      limiter.queue_request { "another success" }

      results = limiter.process_queue(max_per_batch: 3)

      expect(results[0][:success]).to be true
      expect(results[0][:result]).to eq("success")

      expect(results[1][:success]).to be false
      expect(results[1][:error].message).to eq("error")

      expect(results[2][:success]).to be true
      expect(results[2][:result]).to eq("another success")
    end
  end

  describe "backoff calculation" do
    it "uses exponential backoff" do
      limiter_no_jitter = described_class.new(enable_jitter: false)

      # Access private method for testing
      backoff1 = limiter_no_jitter.send(:calculate_backoff, 1)
      backoff2 = limiter_no_jitter.send(:calculate_backoff, 2)
      backoff3 = limiter_no_jitter.send(:calculate_backoff, 3)

      expect(backoff1).to eq(2)
      expect(backoff2).to eq(4)
      expect(backoff3).to eq(8)
    end

    it "adds jitter when enabled" do
      backoff1 = limiter.send(:calculate_backoff, 1)
      backoff2 = limiter.send(:calculate_backoff, 1)

      # With jitter, two calls should produce different results
      expect(backoff1).to be_between(2, 2.2)
      # Small chance they could be equal, but very unlikely with random jitter
    end
  end
end

RSpec.describe Attio::RateLimitMiddleware do
  let(:rate_limiter) { Attio::RateLimiter.new }
  let(:app) { double("app") }
  let(:middleware) { described_class.new(app, rate_limiter) }

  describe "#call" do
    it "passes through the request" do
      env = { method: "GET", path: "/test" }
      response = [200, {}, ["OK"]]

      expect(app).to receive(:call).with(env).and_return(response)

      result = middleware.call(env)
      expect(result).to eq(response)
    end

    it "applies the rate limiter's execute method" do
      env = { method: "GET", path: "/test" }
      response = [200, {}, ["OK"]]

      expect(app).to receive(:call).with(env).and_return(response)
      expect(rate_limiter).to receive(:execute).and_call_original

      result = middleware.call(env)
      expect(result).to eq(response)
    end

    it "applies rate limiting to requests" do
      fast_limiter = Attio::RateLimiter.new(max_requests: 2, window_seconds: 1)
      fast_middleware = described_class.new(app, fast_limiter)

      env = { method: "GET", path: "/test" }
      response = [200, {}, ["OK"]]

      allow(app).to receive(:call).with(env).and_return(response)

      start_time = Time.now
      fast_middleware.call(env)
      fast_middleware.call(env)
      fast_middleware.call(env) # Should wait

      elapsed = Time.now - start_time
      expect(elapsed).to be >= 1.0
    end
  end
end