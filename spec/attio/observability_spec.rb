# frozen_string_literal: true

RSpec.describe Attio::Observability::Instrumentation do
  let(:logger) { Logger.new(StringIO.new) }
  let(:instrumentation) do
    described_class.new(
      logger: logger,
      metrics_backend: :memory,
      trace_backend: :memory
    )
  end
  
  let(:metrics) { instrumentation.metrics }
  let(:traces) { instrumentation.traces }
  
  describe "#record_api_call" do
    it "logs the API call" do
      expect(logger).to receive(:info).with(/api_call/)
      
      instrumentation.record_api_call(
        method: :get,
        path: "records",
        duration: 0.5,
        status: 200
      )
    end
    
    it "records metrics" do
      instrumentation.record_api_call(
        method: :get,
        path: "records/123",
        duration: 0.5,
        status: 200
      )
      
      expect(metrics.counters).to include(match(/attio\.api\.calls/))
      expect(metrics.histograms).to include(match(/attio\.api\.duration/))
    end
    
    it "records errors" do
      instrumentation.record_api_call(
        method: :post,
        path: "records",
        duration: 0.1,
        error: StandardError.new("Failed")
      )
      
      expect(metrics.counters).to include(match(/attio\.api\.errors/))
    end
    
    it "records traces" do
      instrumentation.record_api_call(
        method: :get,
        path: "records",
        duration: 0.5,
        status: 200
      )
      
      expect(traces.spans).not_to be_empty
      span = traces.spans.last
      expect(span.name).to eq("attio.api.call")
      expect(span.attributes["http.method"]).to eq("get")
    end
    
    it "sanitizes paths for metrics" do
      instrumentation.record_api_call(
        method: :get,
        path: "records/abc-123-def/comments",
        duration: 0.1
      )
      
      # Check that IDs are replaced with :id
      expect(metrics.counters.keys.first).to include("records/:id/comments")
    end
  end
  
  describe "#record_rate_limit" do
    it "logs rate limit info" do
      expect(logger).to receive(:debug).with(/rate_limit/)
      
      instrumentation.record_rate_limit(
        remaining: 50,
        limit: 100,
        reset_at: Time.now + 3600
      )
    end
    
    it "records rate limit metrics" do
      instrumentation.record_rate_limit(
        remaining: 50,
        limit: 100,
        reset_at: Time.now + 3600
      )
      
      expect(metrics.gauges["attio.rate_limit.remaining:"]).to eq(50)
      expect(metrics.gauges["attio.rate_limit.utilization:"]).to eq(0.5)
    end
  end
  
  describe "#record_cache" do
    it "logs cache hits and misses" do
      expect(logger).to receive(:debug).twice
      
      instrumentation.record_cache(key: "records:123", hit: true)
      instrumentation.record_cache(key: "records:456", hit: false)
    end
    
    it "records cache metrics" do
      instrumentation.record_cache(key: "test", hit: true)
      instrumentation.record_cache(key: "test", hit: false)
      
      expect(metrics.counters["attio.cache.hits:"]).to eq(1)
      expect(metrics.counters["attio.cache.misses:"]).to eq(1)
    end
  end
  
  describe "#record_circuit_breaker" do
    it "logs state changes" do
      expect(logger).to receive(:warn).with(/circuit_breaker/)
      
      instrumentation.record_circuit_breaker(
        endpoint: "api/records",
        old_state: :closed,
        new_state: :open
      )
    end
    
    it "records state change metrics" do
      instrumentation.record_circuit_breaker(
        endpoint: "api/records",
        old_state: :closed,
        new_state: :open
      )
      
      expect(metrics.counters).to include(
        "attio.circuit_breaker.transitions:{:from=>:closed, :to=>:open}" => 1
      )
    end
  end
  
  describe "#record_pool_stats" do
    it "records pool metrics" do
      stats = {
        size: 10,
        available: 7,
        allocated: 3
      }
      
      instrumentation.record_pool_stats(stats)
      
      expect(metrics.gauges["attio.pool.size:"]).to eq(10)
      expect(metrics.gauges["attio.pool.available:"]).to eq(7)
      expect(metrics.gauges["attio.pool.allocated:"]).to eq(3)
      expect(metrics.gauges["attio.pool.utilization:"]).to eq(0.3)
    end
  end
  
  describe "#disable! / #enable!" do
    it "disables instrumentation" do
      instrumentation.disable!
      
      expect(logger).not_to receive(:info)
      
      instrumentation.record_api_call(
        method: :get,
        path: "test",
        duration: 0.1
      )
    end
    
    it "re-enables instrumentation" do
      instrumentation.disable!
      instrumentation.enable!
      
      expect(logger).to receive(:info)
      
      instrumentation.record_api_call(
        method: :get,
        path: "test",
        duration: 0.1
      )
    end
  end
end

RSpec.describe Attio::Observability::Metrics::Memory do
  let(:metrics) { described_class.new }
  
  describe "#increment" do
    it "increments counter" do
      metrics.increment("test.counter")
      metrics.increment("test.counter")
      
      expect(metrics.counters["test.counter:"]).to eq(2)
    end
    
    it "tracks tags" do
      metrics.increment("test", tags: { env: "prod" })
      
      expect(metrics.counters["test:{:env=>\"prod\"}"]).to eq(1)
    end
  end
  
  describe "#gauge" do
    it "sets gauge value" do
      metrics.gauge("test.gauge", 42)
      
      expect(metrics.gauges["test.gauge:"]).to eq(42)
    end
    
    it "overwrites previous value" do
      metrics.gauge("test", 10)
      metrics.gauge("test", 20)
      
      expect(metrics.gauges["test:"]).to eq(20)
    end
  end
  
  describe "#histogram" do
    it "records values" do
      metrics.histogram("test.hist", 10)
      metrics.histogram("test.hist", 20)
      metrics.histogram("test.hist", 30)
      
      expect(metrics.histograms["test.hist:"]).to eq([10, 20, 30])
    end
  end
  
  describe "#reset!" do
    it "clears all metrics" do
      metrics.increment("counter")
      metrics.gauge("gauge", 1)
      metrics.histogram("hist", 1)
      
      metrics.reset!
      
      expect(metrics.counters).to be_empty
      expect(metrics.gauges).to be_empty
      expect(metrics.histograms).to be_empty
    end
  end
end

RSpec.describe Attio::Observability::Traces::Memory do
  let(:traces) { described_class.new }
  
  describe "#span" do
    it "creates a span" do
      span = traces.span("test.operation")
      
      expect(span).to be_a(Attio::Observability::Traces::Memory::Span)
      expect(span.name).to eq("test.operation")
    end
    
    it "records spans" do
      traces.span("op1")
      traces.span("op2")
      
      expect(traces.spans.size).to eq(2)
    end
    
    it "yields span to block" do
      traces.span("test") do |span|
        span.set_attribute("key", "value")
      end
      
      expect(traces.spans.last.attributes["key"]).to eq("value")
    end
  end
  
  describe "#reset!" do
    it "clears spans" do
      traces.span("test")
      traces.reset!
      
      expect(traces.spans).to be_empty
    end
  end
end