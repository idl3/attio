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

RSpec.describe "Attio::Observability factories" do
  describe "Metrics.for" do
    it "raises helpful error when statsd-ruby gem is not available" do
      allow_any_instance_of(Attio::Observability::Metrics::StatsD).to receive(:require).with("statsd-ruby").and_raise(LoadError)
      
      expect { Attio::Observability::Metrics.for(:statsd) }.to raise_error(RuntimeError, /Please add 'statsd-ruby' to your Gemfile/)
    end
    
    it "creates StatsD backend when gem is available" do
      # Mock the gem
      statsd_class = Class.new do
        def initialize(host, port); end
        def increment(metric, tags: nil); end
        def gauge(metric, value, tags: nil); end
        def histogram(metric, value, tags: nil); end
      end
      stub_const("::Statsd", statsd_class)
      allow_any_instance_of(Attio::Observability::Metrics::StatsD).to receive(:require).with("statsd-ruby").and_return(true)
      
      backend = Attio::Observability::Metrics.for(:statsd)
      expect(backend).to be_a(Attio::Observability::Metrics::StatsD)
    end

    it "raises helpful error when dogstatsd-ruby gem is not available" do
      allow_any_instance_of(Attio::Observability::Metrics::Datadog).to receive(:require).with("datadog/statsd").and_raise(LoadError)
      
      expect { Attio::Observability::Metrics.for(:datadog) }.to raise_error(RuntimeError, /Please add 'dogstatsd-ruby' to your Gemfile/)
    end
    
    it "creates Datadog backend when gem is available" do
      # Mock the gem
      datadog_module = Module.new
      statsd_class = Class.new do
        def initialize(host, port); end
        def increment(metric, tags: nil); end
        def gauge(metric, value, tags: nil); end
        def histogram(metric, value, tags: nil); end
      end
      stub_const("::Datadog", datadog_module)
      stub_const("::Datadog::Statsd", statsd_class)
      allow_any_instance_of(Attio::Observability::Metrics::Datadog).to receive(:require).with("datadog/statsd").and_return(true)
      
      backend = Attio::Observability::Metrics.for(:datadog)
      expect(backend).to be_a(Attio::Observability::Metrics::Datadog)
    end

    it "raises helpful error when prometheus-client gem is not available" do
      allow_any_instance_of(Attio::Observability::Metrics::Prometheus).to receive(:require).with("prometheus/client").and_raise(LoadError)
      
      expect { Attio::Observability::Metrics.for(:prometheus) }.to raise_error(RuntimeError, /Please add 'prometheus-client' to your Gemfile/)
    end
    
    it "creates Prometheus backend when gem is available" do
      # Mock the gem
      prometheus_module = Module.new
      client_module = Module.new do
        def self.registry
          # registry will be set by test
        end
      end
      counter_double = double("counter", increment: nil)
      gauge_double = double("gauge", set: nil)
      histogram_double = double("histogram", observe: nil)
      registry = Class.new do
        define_method(:counter) { |name, docstring:, labels: []| counter_double }
        define_method(:gauge) { |name, docstring:, labels: []| gauge_double }
        define_method(:histogram) { |name, docstring:, labels: []| histogram_double }
      end
      stub_const("::Prometheus", prometheus_module)
      stub_const("::Prometheus::Client", client_module)
      allow(client_module).to receive(:registry).and_return(registry.new)
      allow_any_instance_of(Attio::Observability::Metrics::Prometheus).to receive(:require).with("prometheus/client").and_return(true)
      
      backend = Attio::Observability::Metrics.for(:prometheus)
      expect(backend).to be_a(Attio::Observability::Metrics::Prometheus)
    end

    it "creates Memory backend" do
      backend = Attio::Observability::Metrics.for(:memory)
      expect(backend).to be_a(Attio::Observability::Metrics::Memory)
    end

    it "raises for unknown backend" do
      expect { Attio::Observability::Metrics.for(:unknown) }.to raise_error(ArgumentError, /Unknown metrics backend/)
    end
  end

  describe "Traces.for" do
    it "raises helpful error when opentelemetry-sdk gem is not available" do
      allow_any_instance_of(Attio::Observability::Traces::OpenTelemetry).to receive(:require).with("opentelemetry-sdk").and_raise(LoadError)
      
      expect { Attio::Observability::Traces.for(:opentelemetry) }.to raise_error(RuntimeError, /Please add 'opentelemetry-sdk' to your Gemfile/)
    end
    
    it "creates OpenTelemetry backend when gem is available" do
      # Mock the gem
      opentelemetry_module = Module.new do
        def self.tracer_provider
          # provider will be set by test
        end
      end
      tracer_provider = double("provider", tracer: double("tracer", in_span: nil))
      stub_const("::OpenTelemetry", opentelemetry_module)
      allow(opentelemetry_module).to receive(:tracer_provider).and_return(tracer_provider)
      allow_any_instance_of(Attio::Observability::Traces::OpenTelemetry).to receive(:require).with("opentelemetry-sdk").and_return(true)
      
      backend = Attio::Observability::Traces.for(:opentelemetry)
      expect(backend).to be_a(Attio::Observability::Traces::OpenTelemetry)
    end

    it "raises helpful error when datadog gem is not available" do
      allow_any_instance_of(Attio::Observability::Traces::DatadogAPM).to receive(:require).with("datadog").and_raise(LoadError)
      
      expect { Attio::Observability::Traces.for(:datadog) }.to raise_error(RuntimeError, /Please add 'datadog' to your Gemfile/)
    end
    
    it "creates DatadogAPM backend when gem is available" do
      # Mock the gem
      datadog_module = Module.new
      span_double = double("span")
      tracing_module = Module.new do
        define_singleton_method(:trace) do |name, &block|
          block.call(span_double) if block
        end
      end
      stub_const("::Datadog", datadog_module)
      stub_const("::Datadog::Tracing", tracing_module)
      allow_any_instance_of(Attio::Observability::Traces::DatadogAPM).to receive(:require).with("datadog").and_return(true)
      
      backend = Attio::Observability::Traces.for(:datadog)
      expect(backend).to be_a(Attio::Observability::Traces::DatadogAPM)
    end

    it "creates Memory backend" do
      backend = Attio::Observability::Traces.for(:memory)
      expect(backend).to be_a(Attio::Observability::Traces::Memory)
    end

    it "raises for unknown backend" do
      expect { Attio::Observability::Traces.for(:unknown) }.to raise_error(ArgumentError, /Unknown trace backend/)
    end
  end
end

RSpec.describe "Attio::Observability backend implementations" do
  describe "StatsD" do
    before do
      # Mock the gem being available
      statsd_class = Class.new do
        def initialize(host, port); end
        def increment(metric, tags: nil); end
        def gauge(metric, value, tags: nil); end
        def histogram(metric, value, tags: nil); end
      end
      stub_const("::Statsd", statsd_class)
      allow_any_instance_of(Attio::Observability::Metrics::StatsD).to receive(:require).with("statsd-ruby").and_return(true)
    end

    it "creates client and calls methods" do
      backend = Attio::Observability::Metrics::StatsD.new
      expect { backend.increment("test") }.not_to raise_error
      expect { backend.gauge("test", 1) }.not_to raise_error
      expect { backend.histogram("test", 1) }.not_to raise_error
    end
  end

  describe "Datadog" do
    before do
      datadog_module = Module.new
      statsd_class = Class.new do
        def initialize(host, port); end
        def increment(metric, tags: nil); end
        def gauge(metric, value, tags: nil); end
        def histogram(metric, value, tags: nil); end
      end
      stub_const("::Datadog", datadog_module)
      stub_const("::Datadog::Statsd", statsd_class)
      allow_any_instance_of(Attio::Observability::Metrics::Datadog).to receive(:require).with("datadog/statsd").and_return(true)
    end

    it "creates client and calls methods" do
      backend = Attio::Observability::Metrics::Datadog.new
      expect { backend.increment("test") }.not_to raise_error
      expect { backend.gauge("test", 1) }.not_to raise_error
      expect { backend.histogram("test", 1) }.not_to raise_error
    end
  end

  describe "Prometheus" do
    before do
      prometheus_module = Module.new
      client_module = Module.new do
        def self.registry
          # registry will be set by test
        end
      end
      counter_double = double("counter", increment: nil)
      gauge_double = double("gauge", set: nil)
      histogram_double = double("histogram", observe: nil)
      registry = Class.new do
        define_method(:counter) { |name, docstring:, labels: []| counter_double }
        define_method(:gauge) { |name, docstring:, labels: []| gauge_double }
        define_method(:histogram) { |name, docstring:, labels: []| histogram_double }
      end
      stub_const("::Prometheus", prometheus_module)
      stub_const("::Prometheus::Client", client_module)
      allow(client_module).to receive(:registry).and_return(registry.new)
      allow_any_instance_of(Attio::Observability::Metrics::Prometheus).to receive(:require).with("prometheus/client").and_return(true)
    end

    it "creates client and calls methods" do
      backend = Attio::Observability::Metrics::Prometheus.new
      expect { backend.increment("test") }.not_to raise_error
      expect { backend.gauge("test", 1) }.not_to raise_error
      expect { backend.histogram("test", 1) }.not_to raise_error
    end
  end

  describe "OpenTelemetry" do
    before do
      opentelemetry_module = Module.new do
        def self.tracer_provider
          # provider will be set by test
        end
      end
      tracer_provider = double("provider", tracer: double("tracer", in_span: nil))
      stub_const("::OpenTelemetry", opentelemetry_module)
      allow(opentelemetry_module).to receive(:tracer_provider).and_return(tracer_provider)
      allow_any_instance_of(Attio::Observability::Traces::OpenTelemetry).to receive(:require).with("opentelemetry-sdk").and_return(true)
    end

    it "creates tracer and spans" do
      backend = Attio::Observability::Traces::OpenTelemetry.new
      expect { backend.span("test") { |span| span } }.not_to raise_error
    end
  end

  describe "DatadogAPM" do
    before do
      datadog_module = Module.new
      span_double = double("span")
      tracing_module = Module.new do
        define_singleton_method(:trace) do |name, &block|
          block.call(span_double) if block
        end
      end
      stub_const("::Datadog", datadog_module)
      stub_const("::Datadog::Tracing", tracing_module)
      allow_any_instance_of(Attio::Observability::Traces::DatadogAPM).to receive(:require).with("datadog").and_return(true)
    end

    it "creates tracer and spans" do
      backend = Attio::Observability::Traces::DatadogAPM.new
      expect { backend.span("test") { |span| span } }.not_to raise_error
    end
  end
end

RSpec.describe Attio::Observability::Middleware do
  let(:app) { double("app") }
  let(:instrumentation) { instance_double(Attio::Observability::Instrumentation) }
  let(:middleware) { described_class.new(app, instrumentation) }
  let(:env) do
    {
      method: :get,
      url: double("url", path: "/api/records")
    }
  end

  describe "#call" do
    context "when request succeeds" do
      let(:response) { double("response", status: 200) }

      before do
        allow(app).to receive(:call).with(env).and_return(response)
      end

      it "calls the app" do
        allow(instrumentation).to receive(:record_api_call)
        expect(app).to receive(:call).with(env)
        middleware.call(env)
      end

      it "records successful API call" do
        expect(instrumentation).to receive(:record_api_call).with(
          hash_including(
            method: :get,
            path: "/api/records",
            status: 200
          )
        )
        middleware.call(env)
      end

      it "returns the response" do
        allow(instrumentation).to receive(:record_api_call)
        expect(middleware.call(env)).to eq(response)
      end
    end

    context "when request fails" do
      let(:error) { StandardError.new("Connection failed") }

      before do
        allow(app).to receive(:call).with(env).and_raise(error)
      end

      it "records API call with error" do
        expect(instrumentation).to receive(:record_api_call).with(
          hash_including(
            method: :get,
            path: "/api/records",
            error: error
          )
        )
        expect { middleware.call(env) }.to raise_error(StandardError)
      end

      it "re-raises the error" do
        allow(instrumentation).to receive(:record_api_call)
        expect { middleware.call(env) }.to raise_error(error)
      end
    end
  end
end