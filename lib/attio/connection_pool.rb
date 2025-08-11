# frozen_string_literal: true

module Attio
  # Thread-safe connection pool for managing HTTP connections
  #
  # This class provides a pool of connections that can be shared
  # across threads for improved performance and resource management.
  #
  # @example Creating a connection pool
  #   pool = ConnectionPool.new(size: 10) { HttpClient.new }
  #
  # @example Using a connection from the pool
  #   pool.with_connection do |conn|
  #     conn.get("/endpoint")
  #   end
  class ConnectionPool
    DEFAULT_POOL_SIZE = 5
    DEFAULT_TIMEOUT = 5 # seconds to wait for connection

    attr_reader :size, :timeout

    def initialize(size: DEFAULT_POOL_SIZE, timeout: DEFAULT_TIMEOUT, &block)
      @size = size
      @timeout = timeout
      @available = Queue.new
      @key = :"#{object_id}_connection"
      @block = block
      @mutex = Mutex.new

      size.times { @available << create_connection }
    end

    def with_connection
      connection = checkout
      begin
        yield connection
      ensure
        checkin(connection)
      end
    end

    def checkout
      deadline = Time.now + timeout

      loop do
        return @available.pop(true) if @available.size.positive?

        raise TimeoutError, "Couldn't acquire connection within #{timeout} seconds" if Time.now >= deadline

        sleep(0.01)
      end
    rescue ThreadError
      raise TimeoutError, "No connections available"
    end

    def checkin(connection)
      @mutex.synchronize do
        @available << connection if connection
      end
    end

    def shutdown
      @mutex.synchronize do
        @available.close
        while (connection = begin
          @available.pop(true)
        rescue StandardError
          nil
        end)
          connection.close if connection.respond_to?(:close)
        end
      end
    end

    private def create_connection
      @block.call
    end

    class TimeoutError < StandardError; end
  end
end
