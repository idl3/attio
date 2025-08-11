# frozen_string_literal: true

RSpec.describe Attio::ConnectionPool do
  let(:connection) { double("connection") }
  let(:pool) { described_class.new(size: 2, timeout: 1) { connection } }
  
  describe "#initialize" do
    it "requires a block" do
      expect { described_class.new(size: 2) }
        .to raise_error(ArgumentError, "Block required to create connections")
    end
    
    it "sets size and timeout" do
      expect(pool.size).to eq(2)
      expect(pool.timeout).to eq(1)
    end
    
    it "initializes empty pool" do
      expect(pool.available).to be_empty
      expect(pool.allocated).to be_empty
    end
  end
  
  describe "#with" do
    it "checks out and returns connection" do
      expect(connection).to receive(:get).and_return("result")
      
      result = pool.with { |conn| conn.get }
      expect(result).to eq("result")
    end
    
    it "returns connection even if block raises" do
      expect { pool.with { raise "error" } }.to raise_error("error")
      
      # Connection should be available again
      pool.with { |conn| expect(conn).to eq(connection) }
    end
  end
  
  describe "#checkout" do
    it "creates connection on demand" do
      conn = pool.checkout
      expect(conn).to eq(connection)
    end
    
    it "reuses available connections" do
      conn1 = pool.checkout
      pool.checkin(conn1)
      
      conn2 = pool.checkout
      expect(conn2).to eq(conn1)
    end
    
    it "creates up to pool size" do
      conn1 = pool.checkout
      conn2 = pool.checkout
      
      expect(conn1).to eq(connection)
      expect(conn2).to eq(connection)
    end
    
    it "waits for available connection" do
      # Fill the pool from main thread
      conn1 = pool.checkout
      conn2 = pool.checkout
      
      start = Time.now
      # Thread that will release a connection after 0.1s
      thread = Thread.new do
        sleep 0.1
        # Return conn1 back to pool from main thread context
        pool.instance_eval { @mutex.synchronize { @allocated.delete(Thread.main); @available.push(conn1); @resource.signal } }
      end
      
      # This should wait until a connection is available
      conn = pool.checkout
      elapsed = Time.now - start
      
      expect(conn).to eq(connection)
      expect(elapsed).to be >= 0.1
      
      thread.join
    end
    
    it "raises timeout error when no connection available" do
      pool.checkout
      pool.checkout
      
      expect { pool.checkout }
        .to raise_error(Attio::ConnectionPool::TimeoutError)
    end
    
    it "raises error when shutting down" do
      pool.shutdown
      
      expect { pool.checkout }
        .to raise_error(Attio::ConnectionPool::PoolShuttingDownError)
    end
  end
  
  describe "#checkin" do
    it "returns connection to pool" do
      conn = pool.checkout
      expect(pool.available.size).to eq(0)
      
      pool.checkin(conn)
      expect(pool.available.size).to eq(1)
    end
    
    it "only accepts connections from current thread" do
      conn = pool.checkout
      
      Thread.new { pool.checkin(conn) }.join
      
      # Connection should still be allocated
      expect(pool.allocated).not_to be_empty
    end
    
    it "destroys connection when shutting down" do
      allow(connection).to receive(:close)
      
      conn = pool.checkout
      pool.shutdown
      pool.checkin(conn)
      
      expect(connection).to have_received(:close)
    end
  end
  
  describe "#shutdown" do
    it "closes all available connections" do
      allow(connection).to receive(:close)
      
      conn = pool.checkout
      pool.checkin(conn)
      
      pool.shutdown
      
      expect(connection).to have_received(:close)
    end
    
    it "sets shutting down flag" do
      pool.shutdown
      
      expect { pool.checkout }
        .to raise_error(Attio::ConnectionPool::PoolShuttingDownError)
    end
  end
  
  describe "#reset!" do
    it "closes all connections" do
      allow(connection).to receive(:close)
      
      conn = pool.checkout
      pool.checkin(conn)
      
      pool.reset!
      
      expect(connection).to have_received(:close)
      expect(pool.stats[:created]).to eq(0)
    end

    it "handles errors when closing connections" do
      error_connection = double("connection")
      allow(error_connection).to receive(:close).and_raise(StandardError, "close failed")
      
      pool = described_class.new(size: 1, timeout: 1) { error_connection }
      conn = pool.checkout
      pool.checkin(conn)
      
      expect { pool.reset! }.to output(/Error closing connection: close failed/).to_stderr
    end
  end
  
  describe "#stats" do
    it "returns pool statistics" do
      pool.checkout
      
      stats = pool.stats
      
      expect(stats[:size]).to eq(2)
      expect(stats[:allocated]).to eq(1)
      expect(stats[:available]).to eq(0)
      expect(stats[:created]).to eq(1)
      expect(stats[:requests]).to eq(1)
    end
  end
  
  describe "#utilization" do
    it "returns 0 when no connections created" do
      expect(pool.utilization).to eq(0.0)
    end
    
    it "calculates utilization percentage" do
      # Use a pool that creates unique connections
      unique_pool = described_class.new(size: 2, timeout: 1) { double("connection") }
      
      unique_pool.checkout
      expect(unique_pool.utilization).to eq(0.5)  # 1 of 2 connections in use
      
      # Checkout from another thread to get second connection
      thread = Thread.new { unique_pool.checkout; sleep(0.1) }
      sleep(0.05)  # Let thread checkout
      expect(unique_pool.utilization).to eq(1.0)  # 2 of 2 connections in use
      thread.kill
    end
  end
  
  describe "#healthy?" do
    it "returns true when healthy" do
      expect(pool.healthy?).to be true
    end
    
    it "returns false when shutting down" do
      pool.shutdown
      expect(pool.healthy?).to be false
    end
    
    it "returns false when too many timeouts" do
      2.times { pool.checkout }
      
      # Force timeouts
      10.times do
        begin
          pool.checkout
        rescue Attio::ConnectionPool::TimeoutError
          # Expected
        end
      end
      
      expect(pool.healthy?).to be false
    end
  end
end

RSpec.describe Attio::PooledHttpClient do
  let(:pool) { double("pool") }
  let(:client) { described_class.new(pool) }
  let(:connection) { double("connection") }
  
  %i[get post patch put delete].each do |method|
    describe "##{method}" do
      it "executes #{method} through pool" do
        allow(pool).to receive(:with).and_yield(connection)
        allow(connection).to receive(method).and_return("result")
        
        result = if method == :get || method == :delete
          client.send(method, "path")
        else
          client.send(method, "path", {})
        end
        
        expect(result).to eq("result")
        expect(pool).to have_received(:with)
      end
    end
  end
end