# frozen_string_literal: true

RSpec.describe Attio::CircuitBreaker do
  let(:breaker) { described_class.new(threshold: 2, timeout: 1, half_open_requests: 2) }
  
  describe "#initialize" do
    it "sets configuration" do
      expect(breaker.state).to eq(:closed)
      expect(breaker.failure_count).to eq(0)
    end
  end
  
  describe "#call" do
    context "when circuit is closed" do
      it "executes the block" do
        result = breaker.call { "success" }
        expect(result).to eq("success")
      end
      
      it "records successes" do
        breaker.call { "success" }
        expect(breaker.success_count).to eq(1)
      end
      
      it "records failures" do
        expect { breaker.call { raise StandardError, "fail" } }
          .to raise_error(StandardError)
        
        expect(breaker.failure_count).to eq(1)
      end
      
      it "opens circuit after threshold failures" do
        2.times do
          expect { breaker.call { raise StandardError } }
            .to raise_error(StandardError)
        end
        
        expect(breaker.state).to eq(:open)
      end
    end
    
    context "when circuit is open" do
      before do
        2.times { breaker.call { raise StandardError } rescue nil }
      end
      
      it "raises OpenCircuitError immediately" do
        expect { breaker.call { "success" } }
          .to raise_error(Attio::CircuitBreaker::OpenCircuitError)
      end
      
      it "includes time until retry in error message" do
        expect { breaker.call { "success" } }
          .to raise_error(/\d+s until retry/)
      end
      
      it "transitions to half-open after timeout" do
        sleep 1.1
        
        result = breaker.call { "success" }
        expect(result).to eq("success")
        expect(breaker.state).to eq(:half_open)
      end
    end
    
    context "when circuit is half-open" do
      before do
        2.times { breaker.call { raise StandardError } rescue nil }
        sleep 1.1
        breaker.call { "success" } # Enter half-open
      end
      
      it "allows limited requests" do
        result = breaker.call { "success" }
        expect(result).to eq("success")
      end
      
      it "closes circuit after enough successes" do
        breaker.call { "success" }
        expect(breaker.state).to eq(:closed)
      end
      
      it "reopens circuit on failure" do
        expect { breaker.call { raise StandardError } }
          .to raise_error(StandardError)
        
        expect(breaker.state).to eq(:open)
      end
    end
  end
  
  describe "#trip!" do
    it "manually opens the circuit" do
      breaker.trip!
      expect(breaker.state).to eq(:open)
    end
  end
  
  describe "#reset!" do
    it "resets the circuit to closed" do
      2.times { breaker.call { raise StandardError } rescue nil }
      
      breaker.reset!
      
      expect(breaker.state).to eq(:closed)
      expect(breaker.failure_count).to eq(0)
    end
  end
  
  describe "#allow_request?" do
    it "returns true when closed" do
      expect(breaker.allow_request?).to be true
    end
    
    it "returns false when open" do
      breaker.trip!
      expect(breaker.allow_request?).to be false
    end
    
    it "returns true when open but timeout passed" do
      2.times { breaker.call { raise StandardError } rescue nil }
      sleep 1.1
      
      expect(breaker.allow_request?).to be true
    end
  end
  
  describe "#stats" do
    it "returns circuit breaker statistics" do
      breaker.call { "success" }
      breaker.call { raise StandardError } rescue nil
      
      stats = breaker.stats
      
      expect(stats[:state]).to eq(:closed)
      expect(stats[:requests]).to eq(2)
      expect(stats[:successes]).to eq(1)
      expect(stats[:failures]).to eq(1)
    end
  end
  
  describe "#time_until_retry" do
    it "returns 0 when circuit is closed" do
      expect(breaker.time_until_retry).to eq(0)
    end
    
    it "returns remaining time when open" do
      breaker.trip!
      breaker.instance_variable_set(:@last_failure_time, Time.now)
      
      expect(breaker.time_until_retry).to be_between(0, 1)
    end
  end
  
  describe "state change notifications" do
    it "calls on_state_change callback" do
      states = []
      breaker.on_state_change = ->(old, new) { states << [old, new] }
      
      2.times { breaker.call { raise StandardError } rescue nil }
      
      expect(states).to eq([[:closed, :open]])
    end
  end
end

RSpec.describe Attio::CircuitBreakerClient do
  let(:client) { double("HttpClient") }
  let(:breaker) { Attio::CircuitBreaker.new(threshold: 2, timeout: 1) }
  let(:wrapped_client) { described_class.new(client, breaker) }

  %i[get post patch put delete].each do |method|
    describe "##{method}" do
      it "executes through circuit breaker" do
        allow(client).to receive(method).and_return({ "success" => true })
        
        result = if method == :get || method == :delete
          wrapped_client.send(method, "test")
        else
          wrapped_client.send(method, "test", { data: "test" })
        end
        
        expect(result).to eq({ "success" => true })
      end

      it "opens circuit on repeated failures" do
        allow(client).to receive(method).and_raise(StandardError)
        
        2.times do
          args = method == :get || method == :delete ? ["test"] : ["test", {}]
          expect { wrapped_client.send(method, *args) }.to raise_error(StandardError)
        end
        
        expect(breaker.state).to eq(:open)
        
        args = method == :get || method == :delete ? ["test"] : ["test", {}]
        expect { wrapped_client.send(method, *args) }
          .to raise_error(Attio::CircuitBreaker::OpenCircuitError)
      end
    end
  end
end

RSpec.describe Attio::CompositeCircuitBreaker do
  let(:composite) { described_class.new(threshold: 2, timeout: 1) }
  
  describe "#for_endpoint" do
    it "creates circuit breaker per endpoint" do
      breaker1 = composite.for_endpoint("api/records")
      breaker2 = composite.for_endpoint("api/users")
      
      expect(breaker1).not_to eq(breaker2)
    end
    
    it "returns same breaker for same endpoint" do
      breaker1 = composite.for_endpoint("api/records")
      breaker2 = composite.for_endpoint("api/records")
      
      expect(breaker1).to eq(breaker2)
    end
    
    it "accepts custom config per endpoint" do
      breaker = composite.for_endpoint("api/critical", threshold: 1)
      
      breaker.call { raise StandardError } rescue nil
      
      expect(breaker.state).to eq(:open)
    end
  end
  
  describe "#call" do
    it "executes with circuit breaker for endpoint" do
      result = composite.call("api/records") { "success" }
      expect(result).to eq("success")
    end
    
    it "isolates failures per endpoint" do
      2.times do
        composite.call("api/records") { raise StandardError } rescue nil
      end
      
      # api/records should be open
      expect { composite.call("api/records") { "test" } }
        .to raise_error(Attio::CircuitBreaker::OpenCircuitError)
      
      # api/users should still work
      result = composite.call("api/users") { "success" }
      expect(result).to eq("success")
    end
  end
  
  describe "#states" do
    it "returns all circuit states" do
      composite.for_endpoint("api/records")
      composite.for_endpoint("api/users").trip!
      
      states = composite.states
      
      expect(states["api/records"]).to eq(:closed)
      expect(states["api/users"]).to eq(:open)
    end
  end
  
  describe "#stats" do
    it "returns statistics for all endpoints" do
      composite.call("api/records") { "success" }
      composite.call("api/users") { raise StandardError } rescue nil
      
      stats = composite.stats
      
      expect(stats["api/records"][:successes]).to eq(1)
      expect(stats["api/users"][:failures]).to eq(1)
    end
  end
  
  describe "#reset_all!" do
    it "resets all circuit breakers" do
      composite.for_endpoint("api/records").trip!
      composite.for_endpoint("api/users").trip!
      
      composite.reset_all!
      
      states = composite.states
      expect(states.values).to all(eq(:closed))
    end
  end
end