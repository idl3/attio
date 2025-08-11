module Attio
  module Resources
    # Base class for all API resource classes.
    # 
    # This class provides common functionality and request handling
    # for all Attio API resource implementations.
    # 
    # @api private
    # @author Ernest Sim
    # @since 1.0.0
    class Base
      # @return [Client] The API client instance
      attr_reader :client

      # Initialize a new resource instance.
      # 
      # @param client [Client] The API client instance
      # @raise [ArgumentError] if client is nil
      def initialize(client)
        raise ArgumentError, "Client is required" unless client
        @client = client
      end

      private

      # Make an HTTP request to the API.
      # 
      # @param method [Symbol] The HTTP method (:get, :post, :patch, :put, :delete)
      # @param path [String] The API endpoint path
      # @param params [Hash] Request parameters (default: {})
      # 
      # @return [Hash] The API response
      # @raise [ArgumentError] if method is unsupported
      # 
      # @api private
      def request(method, path, params = {})
        case method
        when :get
          client.connection.get(path, params)
        when :post
          client.connection.post(path, params)
        when :patch
          client.connection.patch(path, params)
        when :put
          client.connection.put(path, params)
        when :delete
          client.connection.delete(path)
        else
          raise ArgumentError, "Unsupported HTTP method: #{method}"
        end
      end

    end
  end
end