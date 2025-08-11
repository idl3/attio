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
    end
  end
end
