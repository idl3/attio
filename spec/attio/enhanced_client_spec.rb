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

      it "starts background stats reporter thread" do
        # Give the thread time to start
        sleep 0.1
        threads = Thread.list.select { |t| t.alive? && t != Thread.main }
        expect(threads.size).to be >= 1
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