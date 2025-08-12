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
      def list(object:, filter: nil, sort: nil, limit: nil, offset: nil, **params)
        validate_required_string!(object, "Object type")

        # Build query parameters with filtering and sorting support
        query_params = build_query_params({
          filter: filter,
          sort: sort,
          limit: limit,
          offset: offset,
          **params,
        })

        request(:post, "objects/#{object}/records/query", query_params)
      end

      # List all records with automatic pagination
      # @param object [String] The object type to query
      # @param filter [Hash] Filtering criteria
      # @param sort [String] Sorting option
      # @param page_size [Integer] Number of records per page
      # @return [Enumerator] Enumerator that yields each record
      def list_all(object:, filter: nil, sort: nil, page_size: 50)
        validate_required_string!(object, "Object type")

        query_params = build_query_params({
          filter: filter,
          sort: sort,
        })

        paginate("objects/#{object}/records/query", query_params, page_size: page_size)
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
        validate_required_string!(object, "Object type")
        validate_id!(id, "Record")
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
        validate_required_string!(object, "Object type")
        validate_record_data!(data)
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
        validate_required_string!(object, "Object type")
        validate_id!(id, "Record")
        validate_record_data!(data)
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
        validate_required_string!(object, "Object type")
        validate_id!(id, "Record")
        request(:delete, "objects/#{object}/records/#{id}")
      end

      # Assert (upsert) a record based on a matching attribute.
      #
      # This method creates or updates a record based on a matching attribute,
      # providing upsert functionality. If a record with the matching attribute
      # value exists, it will be updated; otherwise, a new record will be created.
      #
      # @param object [String] The object type (e.g., 'people', 'companies')
      # @param matching_attribute [String] The attribute to match against for upsert
      # @param data [Hash] The record data to create or update
      #
      # @return [Hash] The created or updated record data
      # @raise [ArgumentError] if object, matching_attribute, or data is invalid
      #
      # @example Assert a person by email
      #   record = client.records.assert(
      #     object: 'people',
      #     matching_attribute: 'email',
      #     data: {
      #       name: 'Jane Doe',
      #       email: 'jane@example.com',
      #       company: { target_object: 'companies', target_record_id: 'company123' }
      #     }
      #   )
      def assert(object:, matching_attribute:, data:)
        validate_required_string!(object, "Object type")
        validate_required_string!(matching_attribute, "Matching attribute")
        validate_record_data!(data)

        request_body = {
          data: data,
          matching_attribute: matching_attribute,
        }

        request(:put, "objects/#{object}/records", request_body)
      end

      # Update a record using PUT (replace operation).
      #
      # This method performs a complete replacement of the record, unlike the
      # regular update method which uses PATCH. For multiselect fields, this
      # overwrites the values instead of appending to them.
      #
      # @param object [String] The object type (e.g., 'people', 'companies')
      # @param id [String] The record ID to replace
      # @param data [Hash] The complete record data to replace with
      #
      # @return [Hash] The updated record data
      # @raise [ArgumentError] if object, id, or data is invalid
      #
      # @example Replace a person's data
      #   record = client.records.update_with_put(
      #     object: 'people',
      #     id: 'abc123',
      #     data: {
      #       name: 'Jane Smith',
      #       email: 'jane.smith@example.com',
      #       tags: ['customer', 'vip']  # This will replace all existing tags
      #     }
      #   )
      def update_with_put(object:, id:, data:)
        validate_required_string!(object, "Object type")
        validate_id!(id, "Record")
        validate_record_data!(data)

        request_body = { data: data }
        request(:put, "objects/#{object}/records/#{id}", request_body)
      end

      # Validates that the data parameter is present and is a hash.
      #
      # @param data [Hash, nil] The data to validate
      # @raise [ArgumentError] if data is nil or not a hash
      # @api private
      private def validate_record_data!(data)
        raise ArgumentError, "Data is required" if data.nil?
        raise ArgumentError, "Data must be a hash" unless data.is_a?(Hash)
      end
    end
  end
end
