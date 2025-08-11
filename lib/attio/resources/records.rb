# frozen_string_literal: true

# Handles all record-related API operations.
#
# Records are the main data entities in Attio, representing things like
# people, companies, deals, etc. This class provides methods to create,
# read, update, delete, and query records.
#
# @example List records
#   records = client.records.list(object: 'people', filters: { name: 'John' })
#
# @example Create a record
#   record = client.records.create(
#     object: 'people',
#     data: { name: 'Jane Doe', email: 'jane@example.com' }
#   )
#
# @author Ernest Sim
# @since 1.0.0
module Attio
  module Resources
    class Records < Base
      # Query and list records for a specific object type.
      #
      # This method allows you to retrieve records with optional filtering,
      # sorting, and pagination parameters.
      #
      # @param object [String] The object type to query (e.g., 'people', 'companies')
      # @param params [Hash] Query parameters including filters, sorts, and pagination
      # @option params [Hash] :filters Filtering criteria
      # @option params [Array] :sorts Sorting options
      # @option params [Integer] :limit Number of records to return
      # @option params [String] :cursor Pagination cursor for next page
      #
      # @return [Hash] API response containing records and pagination info
      # @raise [ArgumentError] if object is nil or empty
      #
      # @example Basic listing
      #   records = client.records.list(object: 'people')
      #
      # @example With filters
      #   records = client.records.list(
      #     object: 'people',
      #     filters: { name: { contains: 'John' } },
      #     limit: 50
      #   )
      def list(object:, **params)
        validate_object!(object)
        request(:post, "objects/#{object}/records/query", params)
      end

      # Retrieve a specific record by ID.
      #
      # @param object [String] The object type (e.g., 'people', 'companies')
      # @param id [String] The record ID
      #
      # @return [Hash] The record data
      # @raise [ArgumentError] if object or id is nil or empty
      #
      # @example
      #   record = client.records.get(object: 'people', id: 'abc123')
      def get(object:, id:)
        validate_object!(object)
        validate_id!(id)
        request(:get, "objects/#{object}/records/#{id}")
      end

      # Create a new record.
      #
      # @param object [String] The object type to create the record in
      # @param data [Hash] The record data to create
      #
      # @return [Hash] The created record data
      # @raise [ArgumentError] if object is nil/empty or data is invalid
      #
      # @example Create a person
      #   record = client.records.create(
      #     object: 'people',
      #     data: {
      #       name: 'Jane Doe',
      #       email: 'jane@example.com',
      #       company: { target_object: 'companies', target_record_id: 'company123' }
      #     }
      #   )
      def create(object:, data:)
        validate_object!(object)
        validate_data!(data)
        request(:post, "objects/#{object}/records", data)
      end

      # Update an existing record.
      #
      # @param object [String] The object type
      # @param id [String] The record ID to update
      # @param data [Hash] The updated record data
      #
      # @return [Hash] The updated record data
      # @raise [ArgumentError] if object, id, or data is invalid
      #
      # @example Update a person's name
      #   record = client.records.update(
      #     object: 'people',
      #     id: 'abc123',
      #     data: { name: 'Jane Smith' }
      #   )
      def update(object:, id:, data:)
        validate_object!(object)
        validate_id!(id)
        validate_data!(data)
        request(:patch, "objects/#{object}/records/#{id}", data)
      end

      # Delete a record.
      #
      # @param object [String] The object type
      # @param id [String] The record ID to delete
      #
      # @return [Hash] Deletion confirmation
      # @raise [ArgumentError] if object or id is nil or empty
      #
      # @example
      #   client.records.delete(object: 'people', id: 'abc123')
      def delete(object:, id:)
        validate_object!(object)
        validate_id!(id)
        request(:delete, "objects/#{object}/records/#{id}")
      end

      private def validate_object!(object)
        raise ArgumentError, "Object type is required" if object.nil? || object.to_s.strip.empty?
      end

      # Validates that the ID parameter is present and not empty.
      #
      # @param id [String, nil] The record ID to validate
      # @raise [ArgumentError] if id is nil or empty
      # @api private
      private def validate_id!(id)
        raise ArgumentError, "Record ID is required" if id.nil? || id.to_s.strip.empty?
      end

      # Validates that the data parameter is present and is a hash.
      #
      # @param data [Hash, nil] The data to validate
      # @raise [ArgumentError] if data is nil or not a hash
      # @api private
      private def validate_data!(data)
        raise ArgumentError, "Data is required" if data.nil?
        raise ArgumentError, "Data must be a hash" unless data.is_a?(Hash)
      end
    end
  end
end
