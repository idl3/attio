# frozen_string_literal: true

RSpec.describe Attio::EnhancedClient do
  let(:api_key) { "test-api-key" }
  let(:client) { described_class.new(api_key: api_key) }

  describe "#initialize" do
    it "creates a basic client without optional features" do
      expect(client).to be_a(Attio::Client)
      expect(client.instance_variable_get(:@pool)).to be_nil
      expect(client.instance_variable_get(:@circuit_breaker)).to be_nil
    end

    context "with connection pool" do
      let(:client) do
        described_class.new(
          api_key: api_key,
          connection_pool: { size: 5, timeout: 2 }
        )
      end

      it "creates a connection pool" do
        pool = client.instance_variable_get(:@pool)
        expect(pool).to be_a(Attio::ConnectionPool)
        expect(pool.size).to eq(5)
      end
    end

    context "with circuit breaker" do
      let(:client) do
        described_class.new(
          api_key: api_key,
          circuit_breaker: { threshold: 3, timeout: 30 }
        )
      end

      it "creates a circuit breaker" do
        breaker = client.instance_variable_get(:@circuit_breaker)
        expect(breaker).to be_a(Attio::CircuitBreaker)
      end

      it "sets up state change callback" do
        breaker = client.instance_variable_get(:@circuit_breaker)
        expect(breaker.on_state_change).to be_a(Proc)
      end
    end

    context "with instrumentation" do
      let(:logger) { Logger.new(StringIO.new) }
      let(:client) do
        described_class.new(
          api_key: api_key,
          instrumentation: { logger: logger, metrics: :memory }
        )
      end

      it "creates instrumentation" do
        instrumentation = client.instance_variable_get(:@instrumentation)
        expect(instrumentation).to be_a(Attio::Observability::Instrumentation)
      end
    end
    
    context "with instrumentation and connection pool" do
      let(:logger) { Logger.new(StringIO.new) }
      let(:client) do
        described_class.new(
          api_key: api_key,
          connection_pool: { size: 2 },
          instrumentation: { logger: logger, metrics: :memory }
        )
      end
      
      it "starts background thread to report pool stats" do
        # Mock the sleep to return immediately so we can test the stats recording
        allow_any_instance_of(Object).to receive(:sleep).and_call_original
        allow_any_instance_of(Object).to receive(:sleep).with(60).and_return(nil)
        
        # Expect the instrumentation to record pool stats
        instrumentation = client.instance_variable_get(:@instrumentation)
        pool = client.instance_variable_get(:@pool)
        
        expect(instrumentation).to receive(:record_pool_stats).with(pool.stats).at_least(:once)
        
        # Give the thread time to start and execute
        sleep 0.1
        
        # Check that the stats thread was created
        stats_thread = client.instance_variable_get(:@stats_thread)
        expect(stats_thread).to be_a(Thread)
        expect(stats_thread.alive?).to be true
        
        # Clean up the background thread
        client.shutdown!
      end
    end

    context "with webhooks" do
      let(:client) do
        described_class.new(
          api_key: api_key,
          webhook_secret: "secret123"
        )
      end

      it "creates webhook handler" do
        webhooks = client.instance_variable_get(:@webhooks)
        expect(webhooks).to be_a(Attio::Webhooks)
      end
    end

    context "with all features" do
      let(:client) do
        described_class.new(
          api_key: api_key,
          connection_pool: { size: 10 },
          circuit_breaker: { threshold: 5 },
          instrumentation: { metrics: :memory },
          webhook_secret: "secret"
        )
      end

      it "creates all components" do
        expect(client.instance_variable_get(:@pool)).to be_a(Attio::ConnectionPool)
        expect(client.instance_variable_get(:@circuit_breaker)).to be_a(Attio::CircuitBreaker)
        expect(client.instance_variable_get(:@instrumentation)).to be_a(Attio::Observability::Instrumentation)
        expect(client.instance_variable_get(:@webhooks)).to be_a(Attio::Webhooks)
      end
    end
  end

  describe "#connection" do
    context "without pool" do
      it "returns standard HTTP client" do
        connection = client.connection
        expect(connection).to be_a(Attio::HttpClient)
      end
    end

    context "with pool" do
      let(:client) do
        described_class.new(
          api_key: api_key,
          connection_pool: { size: 2 }
        )
      end

      it "returns pooled HTTP client" do
        connection = client.connection
        expect(connection).to be_a(Attio::PooledHttpClient)
      end
    end

    context "with pool and circuit breaker" do
      let(:client) do
        described_class.new(
          api_key: api_key,
          connection_pool: { size: 2 },
          circuit_breaker: { threshold: 3 }
        )
      end

      it "wraps pooled client with circuit breaker" do
        connection = client.connection
        expect(connection).to be_a(Attio::CircuitBreakerClient)
      end
    end

    context "with pool and instrumentation" do
      let(:client) do
        described_class.new(
          api_key: api_key,
          connection_pool: { size: 2 },
          instrumentation: { metrics: :memory }
        )
      end

      it "wraps pooled client with instrumentation" do
        connection = client.connection
        # The connection is an anonymous class instance
        expect(connection.class.superclass).to eq(Object)
        expect(connection.instance_variable_get(:@instrumentation)).to be_a(Attio::Observability::Instrumentation)
      end
    end
  end

  describe "#execute" do
    context "without circuit breaker" do
      it "executes block directly" do
        result = client.execute { "test" }
        expect(result).to eq("test")
      end
    end

    context "with circuit breaker" do
      let(:client) do
        described_class.new(
          api_key: api_key,
          circuit_breaker: { threshold: 2 }
        )
      end

      it "executes block through circuit breaker" do
        result = client.execute { "test" }
        expect(result).to eq("test")
      end

      context "with endpoint specified" do
        it "creates composite breaker for endpoint" do
          result = client.execute(endpoint: "api/records") { "test" }
          expect(result).to eq("test")
          
          composite = client.instance_variable_get(:@composite_breaker)
          expect(composite).to be_a(Attio::CompositeCircuitBreaker)
        end
      end
    end
  end

  describe "#health_check" do
    let(:client) do
      described_class.new(
        api_key: api_key,
        connection_pool: { size: 2 },
        circuit_breaker: { threshold: 3 }
      )
    end

    before do
      allow(client).to receive(:check_api_health).and_return(true)
    end

    it "returns health status for all components" do
      health = client.health_check
      expect(health).to include(
        api: true,
        pool: true,
        circuit_breaker: :healthy,
        rate_limiter: true
      )
    end

    context "when API is down" do
      before do
        allow(client).to receive(:check_api_health).and_return(false)
      end

      it "returns false for api health" do
        health = client.health_check
        expect(health[:api]).to eq(false)
      end
    end

    context "when circuit is open" do
      before do
        breaker = client.instance_variable_get(:@circuit_breaker)
        allow(breaker).to receive(:state).and_return(:open)
      end

      it "returns unhealthy for circuit breaker" do
        health = client.health_check
        expect(health[:circuit_breaker]).to eq(:unhealthy)
      end
    end

    context "when circuit is half-open" do
      before do
        breaker = client.instance_variable_get(:@circuit_breaker)
        allow(breaker).to receive(:state).and_return(:half_open)
      end

      it "returns recovering for circuit breaker" do
        health = client.health_check
        expect(health[:circuit_breaker]).to eq(:recovering)
      end
    end
  end

  describe "#stats" do
    let(:client) do
      described_class.new(
        api_key: api_key,
        connection_pool: { size: 2 },
        circuit_breaker: { threshold: 3 },
        instrumentation: { metrics: :memory }
      )
    end

    it "returns statistics from all components" do
      stats = client.stats
      expect(stats).to include(:pool, :circuit_breaker, :rate_limiter, :instrumentation)
      expect(stats[:pool]).to include(:size, :available)
      expect(stats[:circuit_breaker]).to include(:state, :requests)
      expect(stats[:rate_limiter]).to include(:remaining, :limit)
    end
  end

  describe "connection pool HTTP client creation" do
    it "creates actual HttpClient instances in the pool" do
      # Mock the HttpClient class
      http_client_class = Class.new do
        def initialize(base_url:, headers:, timeout:, rate_limiter: nil)
          @base_url = base_url
          @headers = headers
          @timeout = timeout
          @rate_limiter = rate_limiter
        end
        
        def get(path)
          { "data" => [] }
        end
      end
      stub_const("Attio::HttpClient", http_client_class)
      
      client = described_class.new(
        api_key: api_key,
        connection_pool: { size: 2, timeout: 1 }
      )
      
      # Force pool creation by using the connection
      pool = client.instance_variable_get(:@pool)
      expect(pool).to be_a(Attio::ConnectionPool)
      
      # Use the pool to get a connection and verify it's the right type
      pool.with do |http_client|
        expect(http_client).to be_a(http_client_class)
        expect(http_client.instance_variable_get(:@base_url)).to eq("https://api.attio.com/v2")
        expect(http_client.instance_variable_get(:@timeout)).to eq(30)
      end
    end
  end

  describe "circuit breaker state change callback" do
    it "records state changes when instrumentation is present" do
      instrumentation = instance_double(Attio::Observability::Instrumentation)
      allow(instrumentation).to receive(:record_circuit_breaker)
      
      client = described_class.new(
        api_key: api_key,
        circuit_breaker: { threshold: 2, timeout: 1 }
      )
      client.instance_variable_set(:@instrumentation, instrumentation)
      
      breaker = client.instance_variable_get(:@circuit_breaker)
      callback = breaker.instance_variable_get(:@on_state_change)
      
      expect(instrumentation).to receive(:record_circuit_breaker).with(
        endpoint: "api",
        old_state: :closed,
        new_state: :open
      )
      callback.call(:closed, :open)
    end
  end

  describe "#check_api_health (private)" do
    let(:connection) { instance_double(Attio::HttpClient) }
    
    it "returns false when API call fails" do
      client = described_class.new(api_key: api_key)
      
      allow(client).to receive(:connection).and_return(connection)
      allow(connection).to receive(:get).with("self").and_raise(StandardError)
      
      result = client.send(:check_api_health)
      expect(result).to be false
    end

    it "returns true when API call succeeds" do
      client = described_class.new(api_key: api_key)
      
      allow(client).to receive(:connection).and_return(connection)
      allow(connection).to receive(:get).with("self").and_return({ "data" => { "active" => true } })
      
      result = client.send(:check_api_health)
      expect(result).to be true
    end
  end

  describe "#default_headers (private)" do
    it "returns proper headers hash" do
      client = described_class.new(api_key: api_key)
      
      headers = client.send(:default_headers)
      expect(headers).to include(
        "Authorization" => "Bearer #{api_key}",
        "Accept" => "application/json",
        "Content-Type" => "application/json"
      )
      expect(headers["User-Agent"]).to match(/Attio Ruby Client/)
    end
  end

  describe "#shutdown!" do
    let(:client) do
      described_class.new(
        api_key: api_key,
        connection_pool: { size: 2 },
        instrumentation: { metrics: :memory }
      )
    end

    it "shuts down pool and disables instrumentation" do
      pool = client.instance_variable_get(:@pool)
      instrumentation = client.instance_variable_get(:@instrumentation)
      
      expect(pool).to receive(:shutdown)
      expect(instrumentation).to receive(:disable!)
      
      client.shutdown!
    end

    it "gracefully stops background stats thread" do
      # Give the background thread time to start
      sleep 0.1
      
      stats_thread = client.instance_variable_get(:@stats_thread)
      expect(stats_thread).to be_a(Thread)
      expect(stats_thread.alive?).to be true
      
      # Shutdown should stop the thread
      client.shutdown!
      
      # Wait a bit and check thread is dead
      sleep 0.1
      expect(stats_thread.alive?).to be false
    end
  end

  describe "background thread error handling" do
    let(:logger) { Logger.new(StringIO.new) }
    let(:client) do
      described_class.new(
        api_key: api_key,
        connection_pool: { size: 2 },
        instrumentation: { logger: logger, metrics: :memory }
      )
    end

    it "handles errors in background stats collection and continues running" do
      # Mock pool stats to raise an error
      pool = client.instance_variable_get(:@pool)
      
      allow(pool).to receive(:stats).and_raise(StandardError, "Mock error")
      allow_any_instance_of(Object).to receive(:sleep).and_call_original
      allow_any_instance_of(Object).to receive(:sleep).with(60).and_return(nil)
      
      # Expect error to be logged (allow multiple occurrences since thread is running continuously)
      expect(logger).to receive(:error).with(/Background stats thread error/).at_least(:once)
      
      # Give the thread time to start and hit the error
      sleep 0.1
      
      # Thread should still be alive after the error
      stats_thread = client.instance_variable_get(:@stats_thread)
      expect(stats_thread.alive?).to be true
      
      # Clean up
      client.shutdown!
    end
  end

  describe "instrumented client wrapper" do
    let(:client) do
      described_class.new(
        api_key: api_key,
        connection_pool: { size: 2 },
        instrumentation: { metrics: :memory }
      )
    end

    let(:connection) { client.connection }
    let(:instrumentation) { client.instance_variable_get(:@instrumentation) }

    before do
      # Mock the underlying pool and client
      pool = client.instance_variable_get(:@pool)
      http_client = double("HttpClient")
      allow(pool).to receive(:with).and_yield(http_client)
      allow(http_client).to receive(:get).and_return({ "data" => [] })
      allow(http_client).to receive(:post).and_return({ "id" => "123" })
      allow(http_client).to receive(:patch).and_return({ "updated" => true })
      allow(http_client).to receive(:put).and_return({ "replaced" => true })
      allow(http_client).to receive(:delete).and_return({ "deleted" => true })
    end

    %i[get post patch put delete].each do |method|
      describe "##{method}" do
        it "records successful API calls" do
          expect(instrumentation).to receive(:record_api_call).with(
            hash_including(
              method: method,
              path: "test",
              duration: anything
            )
          )
          
          args = method == :get ? ["test"] : ["test", { data: "test" }]
          connection.send(method, *args)
        end

        it "records API errors" do
          pool = client.instance_variable_get(:@pool)
          http_client = double("HttpClient")
          allow(pool).to receive(:with).and_yield(http_client)
          allow(http_client).to receive(method).and_raise(StandardError, "API Error")

          expect(instrumentation).to receive(:record_api_call).with(
            hash_including(
              method: method,
              path: "test",
              error: instance_of(StandardError)
            )
          )
          
          args = method == :get ? ["test"] : ["test", { data: "test" }]
          expect { connection.send(method, *args) }.to raise_error(StandardError)
        end
      end
    end
  end

  describe ".enhanced_client factory method" do
    it "creates an enhanced client" do
      client = Attio.enhanced_client(
        api_key: "test-key",
        connection_pool: { size: 5 }
      )
      expect(client).to be_a(Attio::EnhancedClient)
      expect(client.instance_variable_get(:@pool)).to be_a(Attio::ConnectionPool)
    end
  end
end