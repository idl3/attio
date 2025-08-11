# frozen_string_literal: true

require "timeout"

module Attio
  # Thread-safe connection pool for high-throughput operations
  #
  # @example Basic usage
  #   pool = ConnectionPool.new(size: 5) do
  #     Attio::HttpClient.new(base_url: API_URL, headers: headers)
  #   end
  #
  #   pool.with do |connection|
  #     connection.get("records")
  #   end
  class ConnectionPool
    class TimeoutError < StandardError; end
    class PoolShuttingDownError < StandardError; end

    DEFAULT_SIZE = 5
    DEFAULT_TIMEOUT = 5

    attr_reader :size, :timeout, :available, :allocated

    # Initialize a new connection pool
    #
    # @param size [Integer] Maximum number of connections
    # @param timeout [Integer] Seconds to wait for available connection
    # @yield Block that creates a new connection
    def initialize(size: DEFAULT_SIZE, timeout: DEFAULT_TIMEOUT, &block)
      raise ArgumentError, "Block required to create connections" unless block_given?

      @size = size
      @timeout = timeout
      @create_block = block
      @available = []
      @allocated = {}
      @mutex = Mutex.new
      @resource = ConditionVariable.new
      @shutting_down = false
      @created = 0

      # Stats tracking
      @stats = {
        requests: 0,
        timeouts: 0,
        wait_time: 0,
        active: 0,
        created: 0,
        destroyed: 0,
      }
    end

    # Execute a block with a connection from the pool
    #
    # @yield [connection] Block to execute with connection
    # @return Result of the block
    def with
      connection = checkout
      begin
        yield connection
      ensure
        checkin(connection)
      end
    end

    # Check out a connection from the pool
    #
    # @return [Object] A connection from the pool
    # @raise [TimeoutError] if no connection available within timeout
    def checkout
      start_time = Time.now
      deadline = start_time + @timeout

      @mutex.synchronize do
        raise PoolShuttingDownError, "Pool is shutting down" if @shutting_down

        @stats[:requests] += 1

        loop do
          # Return available connection
          if (connection = @available.pop)
            @allocated[Thread.current] = connection
            @stats[:active] += 1
            @stats[:wait_time] += (Time.now - start_time)
            return connection
          end

          # Create new connection if under limit
          if @created < @size
            connection = create_connection
            @allocated[Thread.current] = connection
            @stats[:active] += 1
            @stats[:wait_time] += (Time.now - start_time)
            return connection
          end

          # Wait for available connection
          remaining = deadline - Time.now
          if remaining <= 0
            @stats[:timeouts] += 1
            raise TimeoutError, "Timed out waiting for connection after #{@timeout}s"
          end

          @resource.wait(@mutex, remaining)
        end
      end
    end

    # Return a connection to the pool
    #
    # @param connection [Object] Connection to return
    def checkin(connection)
      @mutex.synchronize do
        if @allocated[Thread.current] == connection
          @allocated.delete(Thread.current)
          @stats[:active] -= 1

          if @shutting_down
            destroy_connection(connection)
          else
            @available.push(connection)
            @resource.signal
          end
        end
      end
    end

    # Shutdown the pool and close all connections
    def shutdown
      @mutex.synchronize do
        @shutting_down = true

        # Close available connections
        while (connection = @available.pop)
          destroy_connection(connection)
        end

        # NOTE: allocated connections will be closed when checked in
        @resource.broadcast
      end
    end

    # Reset the pool by closing all connections
    def reset!
      @mutex.synchronize do
        # Close all available connections
        while (connection = @available.pop)
          destroy_connection(connection)
        end

        @created = 0
        @stats[:created] = 0
        @stats[:destroyed] = 0
      end
    end

    # Get pool statistics
    #
    # @return [Hash] Pool statistics
    def stats
      @mutex.synchronize do
        @stats.merge(
          size: @size,
          available: @available.size,
          allocated: @allocated.size,
          created: @created
        )
      end
    end

    # Current pool utilization (0.0 to 1.0)
    #
    # @return [Float] Utilization percentage
    def utilization
      @mutex.synchronize do
        return 0.0 if @size == 0

        @allocated.size.to_f / @size
      end
    end

    # Check if pool is healthy
    #
    # @return [Boolean] True if pool is functioning normally
    def healthy?
      return false if @shutting_down
      return true if @stats[:requests] == 0

      @stats[:timeouts] < (@stats[:requests] * 0.01)
    end

    private def create_connection
      connection = @create_block.call
      @created += 1
      @stats[:created] += 1
      connection
    end

    private def destroy_connection(connection)
      # Call close if connection responds to it
      connection.close if connection.respond_to?(:close)
      @stats[:destroyed] += 1
    rescue StandardError => e
      # Log but don't raise on close errors
      warn "Error closing connection: #{e.message}"
    end
  end

  # Wrapper for pooled HTTP connections
  class PooledHttpClient
    def initialize(pool)
      @pool = pool
    end

    def get(path, params = nil)
      @pool.with { |conn| conn.get(path, params) }
    end

    def post(path, body = {})
      @pool.with { |conn| conn.post(path, body) }
    end

    def patch(path, body = {})
      @pool.with { |conn| conn.patch(path, body) }
    end

    def put(path, body = {})
      @pool.with { |conn| conn.put(path, body) }
    end

    def delete(path, body = nil)
      @pool.with { |conn| conn.delete(path, body) }
    end
  end
end
