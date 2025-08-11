# frozen_string_literal: true

RSpec.describe "Attio::CircuitBreaker edge cases" do
  let(:breaker) { Attio::CircuitBreaker.new(threshold: 2, timeout: 0.1, half_open_requests: 2) }

  describe "half-open state transitions" do
    it "transitions to closed when already met half-open requirements" do
      # Open the circuit
      2.times { breaker.call { raise StandardError } rescue nil }
      expect(breaker.state).to eq(:open)
      
      # Wait for timeout
      sleep 0.11
      
      # First call transitions to half-open and succeeds
      breaker.call { "success" }
      expect(breaker.state).to eq(:half_open)
      
      # Second call meets half_open_requests and transitions to closed
      breaker.call { "success" }
      expect(breaker.state).to eq(:closed)
      
      # Now open again
      2.times { breaker.call { raise StandardError } rescue nil }
      expect(breaker.state).to eq(:open)
      
      # Wait for timeout
      sleep 0.11
      
      # First call transitions to half-open
      breaker.call { "success" }
      expect(breaker.state).to eq(:half_open)
      
      # Manually set half_open_successes to already meet the threshold
      breaker.instance_variable_set(:@half_open_successes, 2)
      
      # This should see we already meet requirements and close immediately  
      # This exercises line 85-87 in circuit_breaker.rb
      breaker.call { "success" }
      expect(breaker.state).to eq(:closed)
    end
  end

  describe "stats tracking" do
    it "tracks rejections when circuit is open" do
      # Open the circuit
      2.times { breaker.call { raise StandardError } rescue nil }
      
      # Try to call when open (should be rejected)
      expect { breaker.call { "test" } }.to raise_error(Attio::CircuitBreaker::OpenCircuitError)
      
      stats = breaker.stats
      expect(stats[:rejections]).to be > 0
    end
  end
end