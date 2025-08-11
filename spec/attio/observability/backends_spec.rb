# frozen_string_literal: true

RSpec.describe "Attio::Observability Backends" do
  describe Attio::Observability::Metrics::StatsD do
    context "when statsd-ruby is not available" do
      it "raises helpful error message" do
        instance = described_class.allocate
        allow(instance).to receive(:require).with("statsd-ruby").and_raise(LoadError)
        
        expect { instance.send(:initialize) }
          .to raise_error(RuntimeError, "Please add 'statsd-ruby' to your Gemfile")
      end
    end
  end

  describe Attio::Observability::Metrics::Datadog do
    context "when dogstatsd-ruby is not available" do
      it "raises helpful error message" do
        instance = described_class.allocate
        allow(instance).to receive(:require).with("datadog/statsd").and_raise(LoadError)
        
        expect { instance.send(:initialize) }
          .to raise_error(RuntimeError, "Please add 'dogstatsd-ruby' to your Gemfile")
      end
    end
  end

  describe Attio::Observability::Metrics::Prometheus do
    context "when prometheus-client is not available" do
      it "raises helpful error message" do
        instance = described_class.allocate
        allow(instance).to receive(:require).with("prometheus/client").and_raise(LoadError)
        
        expect { instance.send(:initialize) }
          .to raise_error(RuntimeError, "Please add 'prometheus-client' to your Gemfile")
      end
    end
  end

  describe Attio::Observability::Traces::OpenTelemetry do
    context "when opentelemetry-sdk is not available" do
      it "raises helpful error message" do
        instance = described_class.allocate
        allow(instance).to receive(:require).with("opentelemetry-sdk").and_raise(LoadError)
        
        expect { instance.send(:initialize) }
          .to raise_error(RuntimeError, "Please add 'opentelemetry-sdk' to your Gemfile")
      end
    end
  end

  describe Attio::Observability::Traces::DatadogAPM do
    context "when datadog is not available" do
      it "raises helpful error message" do
        instance = described_class.allocate
        allow(instance).to receive(:require).with("datadog").and_raise(LoadError)
        
        expect { instance.send(:initialize) }
          .to raise_error(RuntimeError, "Please add 'datadog' to your Gemfile")
      end
    end
  end

  describe Attio::Observability::Middleware do
    let(:app) { double("App") }
    let(:instrumentation) { instance_double(Attio::Observability::Instrumentation) }
    let(:middleware) { described_class.new(app, instrumentation) }

    describe "#call" do
      let(:env) do
        {
          method: :get,
          url: double("URL", path: "/api/records")
        }
      end

      it "records successful API calls" do
        response = double("Response", status: 200)
        allow(app).to receive(:call).and_return(response)

        expect(instrumentation).to receive(:record_api_call).with(
          hash_including(
            method: :get,
            path: "/api/records",
            status: 200
          )
        )

        result = middleware.call(env)
        expect(result).to eq(response)
      end

      it "records failed API calls" do
        error = StandardError.new("API Error")
        allow(app).to receive(:call).and_raise(error)

        expect(instrumentation).to receive(:record_api_call).with(
          hash_including(
            method: :get,
            path: "/api/records",
            error: error
          )
        )

        expect { middleware.call(env) }.to raise_error(StandardError)
      end
    end
  end

  describe "Metrics.for factory" do
    it "creates memory backend" do
      backend = Attio::Observability::Metrics.for(:memory)
      expect(backend).to be_a(Attio::Observability::Metrics::Memory)
    end

    it "raises error for unknown backend" do
      expect { Attio::Observability::Metrics.for(:unknown) }
        .to raise_error(ArgumentError, "Unknown metrics backend: unknown")
    end
  end

  describe "Traces.for factory" do
    it "creates memory backend" do
      backend = Attio::Observability::Traces.for(:memory)
      expect(backend).to be_a(Attio::Observability::Traces::Memory)
    end

    it "raises error for unknown backend" do
      expect { Attio::Observability::Traces.for(:unknown) }
        .to raise_error(ArgumentError, "Unknown trace backend: unknown")
    end
  end
end