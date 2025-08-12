# frozen_string_literal: true

# Base class for all API resource classes.
#
# This class provides common functionality and request handling
# for all Attio API resource implementations.
#
# @api private
# @author Ernest Sim
# @since 1.0.0
module Attio
  module Resources
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

      # Common validation methods that can be used by all resource classes

      # Validates that an ID parameter is present and not empty
      # @param id [String] The ID to validate
      # @param resource_name [String] The resource name for the error message
      # @raise [ArgumentError] if id is nil or empty
      private def validate_id!(id, resource_name = "Resource")
        return unless id.nil? || id.to_s.strip.empty?

        raise ArgumentError, "#{resource_name} ID is required"
      end

      # Validates that data is not empty
      # @param data [Hash] The data to validate
      # @param operation [String] The operation name for the error message
      # @raise [ArgumentError] if data is empty
      private def validate_data!(data, operation = "Operation")
        raise ArgumentError, "#{operation} data is required" if data.nil? || data.empty?
      end

      # Validates that a string parameter is present and not empty
      # @param value [String] The value to validate
      # @param field_name [String] The field name for the error message
      # @raise [ArgumentError] if value is nil or empty
      private def validate_required_string!(value, field_name)
        return unless value.nil? || value.to_s.strip.empty?

        raise ArgumentError, "#{field_name} is required"
      end

      # Validates that a hash parameter is present
      # @param value [Hash] The hash to validate
      # @param field_name [String] The field name for the error message
      # @raise [ArgumentError] if value is nil or not a hash
      private def validate_required_hash!(value, field_name)
        return if value.is_a?(Hash) && !value.nil?

        raise ArgumentError, "#{field_name} must be a hash"
      end

      # Validates parent object and record ID together
      # @param parent_object [String] The parent object type
      # @param parent_record_id [String] The parent record ID
      # @raise [ArgumentError] if either is missing
      private def validate_parent!(parent_object, parent_record_id)
        validate_required_string!(parent_object, "Parent object")
        validate_required_string!(parent_record_id, "Parent record ID")
      end

      private def request(method, path, params = {}, _headers = {})
        # Path is already safely constructed by the resource methods
        connection = client.connection

        case method
        when :get
          handle_get_request(connection, path, params)
        when :post
          handle_post_request(connection, path, params)
        when :patch
          connection.patch(path, params)
        when :put
          connection.put(path, params)
        when :delete
          handle_delete_request(connection, path, params)
        else
          raise ArgumentError, "Unsupported HTTP method: #{method}"
        end
      end

      private def handle_get_request(connection, path, params)
        params.empty? ? connection.get(path) : connection.get(path, params)
      end

      private def handle_post_request(connection, path, params)
        params.empty? ? connection.post(path) : connection.post(path, params)
      end

      private def handle_delete_request(connection, path, params)
        params.empty? ? connection.delete(path) : connection.delete(path, params)
      end

      # Paginate through all results for a given endpoint
      # @param path [String] The API endpoint path
      # @param params [Hash] Query parameters including filters
      # @param page_size [Integer] Number of items per page (default: 50)
      # @return [Enumerator] Yields each item from all pages
      private def paginate(path, params = {}, page_size: 50)
        Enumerator.new do |yielder|
          offset = 0
          loop do
            page_params = params.merge(limit: page_size, offset: offset)
            # Use POST for query endpoints, GET for others
            method = path.end_with?("/query") ? :post : :get
            response = request(method, path, page_params)

            data = response["data"] || []
            data.each { |item| yielder << item }

            # Stop if we got fewer items than requested (last page)
            break if data.size < page_size

            offset += page_size
          end
        end
      end

      # Build query parameters with filtering and sorting support
      # @param options [Hash] Options including filter, sort, limit, offset
      # @return [Hash] Formatted query parameters
      private def build_query_params(options = {})
        params = {}

        # Add filtering
        add_filter_param(params, options[:filter]) if options[:filter]

        # Add standard parameters
        %i[sort limit offset].each do |key|
          params[key] = options[key] if options[key]
        end

        # Add any other parameters
        options.each do |key, value|
          next if %i[filter sort limit offset].include?(key)

          params[key] = value
        end

        params
      end

      private def add_filter_param(params, filter)
        params[:filter] = filter.is_a?(String) ? filter : filter.to_json
      end
    end
  end
end
