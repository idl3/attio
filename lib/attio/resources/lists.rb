# frozen_string_literal: true

module Attio
  module Resources
    # API resource for managing Attio lists and list entries
    #
    # Lists are custom collections for organizing records in your workspace.
    #
    # @example Listing all lists
    #   client.lists.list
    #
    # @example Adding an entry to a list
    #   client.lists.create_entry(id: "list_id", data: { record_id: "rec_123" })
    class Lists < Base
      def list(**params)
        request(:get, "lists", params)
      end

      def get(id:)
        validate_id!(id, "List")
        request(:get, "lists/#{id}")
      end

      def entries(id:, **params)
        validate_id!(id, "List")
        request(:get, "lists/#{id}/entries", params)
      end

      def create_entry(id:, data:)
        validate_id!(id, "List")
        validate_list_entry_data!(data)
        request(:post, "lists/#{id}/entries", data)
      end

      def get_entry(list_id:, entry_id:)
        validate_id!(list_id, "List")
        validate_id!(entry_id, "Entry")
        request(:get, "lists/#{list_id}/entries/#{entry_id}")
      end

      def delete_entry(list_id:, entry_id:)
        validate_id!(list_id, "List")
        validate_id!(entry_id, "Entry")
        request(:delete, "lists/#{list_id}/entries/#{entry_id}")
      end

      # Create a new list.
      #
      # Creates a new list with the specified configuration. The list can be
      # associated with a parent object type and configured with various options.
      #
      # @param data [Hash] The list configuration data
      # @option data [String] :name The name of the list (required)
      # @option data [String] :parent_object The parent object type for the list
      # @option data [Boolean] :is_public Whether the list is publicly accessible
      # @option data [String] :description Optional description for the list
      #
      # @return [Hash] The created list data
      # @raise [ArgumentError] if data is invalid
      #
      # @example Create a simple list
      #   list = client.lists.create(
      #     data: {
      #       name: "VIP Customers",
      #       parent_object: "people",
      #       is_public: true
      #     }
      #   )
      def create(data:)
        validate_list_data!(data)
        request(:post, "lists", { data: data })
      end

      # Update an existing list.
      #
      # Updates the configuration of an existing list. You can modify the name,
      # description, visibility, and other list properties.
      #
      # @param id_or_slug [String] The list ID or slug
      # @param data [Hash] The list configuration updates
      # @option data [String] :name New name for the list
      # @option data [Boolean] :is_public New visibility setting
      # @option data [String] :description New description for the list
      #
      # @return [Hash] The updated list data
      # @raise [ArgumentError] if id_or_slug or data is invalid
      #
      # @example Update list name and visibility
      #   list = client.lists.update(
      #     id_or_slug: "list_123",
      #     data: {
      #       name: "Premium Customers",
      #       is_public: false
      #     }
      #   )
      def update(id_or_slug:, data:)
        validate_id!(id_or_slug, "List")
        validate_list_data!(data)
        request(:patch, "lists/#{id_or_slug}", { data: data })
      end

      # Query list entries with advanced filtering and sorting.
      #
      # Provides advanced querying capabilities for list entries, supporting
      # complex filters, sorting, and pagination. This is more powerful than
      # the basic entries method as it supports structured queries.
      #
      # @param id_or_slug [String] The list ID or slug
      # @param filter [Hash, String, nil] Optional filter criteria for querying entries
      # @param sort [Hash, Array, String, nil] Optional sorting configuration
      # @param limit [Integer, nil] Maximum number of entries to return
      # @param offset [Integer, nil] Number of entries to skip for pagination
      #
      # @return [Hash] Query results with entries and pagination info
      # @raise [ArgumentError] if id_or_slug is invalid
      #
      # @example Query with filters
      #   entries = client.lists.query_entries(
      #     id_or_slug: "vip_customers",
      #     filter: { created_at: { gte: "2023-01-01" } },
      #     sort: { created_at: "desc" },
      #     limit: 50
      #   )
      #
      # @example Query all entries without filters
      #   entries = client.lists.query_entries(id_or_slug: "list_123")
      def query_entries(id_or_slug:, filter: nil, sort: nil, limit: nil, offset: nil)
        validate_id!(id_or_slug, "List")

        query_params = build_query_params({
          filter: filter,
          sort: sort,
          limit: limit,
          offset: offset,
        })

        request(:post, "lists/#{id_or_slug}/entries/query", query_params)
      end

      # Assert (upsert) a list entry.
      #
      # Creates or updates a list entry based on a matching attribute. This is an
      # upsert operation that will create a new entry if no match is found, or update
      # an existing entry if a match is found based on the specified matching attribute.
      #
      # Required scopes: list_entry:read-write, list_configuration:read
      #
      # @param id_or_slug [String] The list ID or slug
      # @param matching_attribute [String] The attribute to match against for upsert
      # @param data [Hash] The entry data to create or update
      # @option data [String] :record_id The ID of the record to add to the list
      # @option data [Hash] :values Optional field values for the entry
      # @option data [String] :notes Optional notes for the entry
      #
      # @return [Hash] The created or updated entry data
      # @raise [ArgumentError] if parameters are invalid
      #
      # @example Assert entry with record ID
      #   entry = client.lists.assert_entry(
      #     id_or_slug: "vip_customers",
      #     matching_attribute: "record_id",
      #     data: {
      #       record_id: "rec_123",
      #       values: { priority: "high" },
      #       notes: "Premium customer"
      #     }
      #   )
      #
      # @example Assert entry with custom matching
      #   entry = client.lists.assert_entry(
      #     id_or_slug: "lead_list",
      #     matching_attribute: "email",
      #     data: {
      #       email: "john@example.com",
      #       values: { status: "qualified" }
      #     }
      #   )
      def assert_entry(id_or_slug:, matching_attribute:, data:)
        validate_id!(id_or_slug, "List")
        validate_required_string!(matching_attribute, "Matching attribute")
        validate_list_entry_data!(data)

        request_body = {
          data: data,
          matching_attribute: matching_attribute,
        }

        request(:put, "lists/#{id_or_slug}/entries", request_body)
      end

      # Update an existing list entry.
      #
      # Updates the data for an existing list entry. This method requires the
      # entry ID and will update only the provided fields, leaving other fields
      # unchanged.
      #
      # @param id_or_slug [String] The list ID or slug
      # @param entry_id [String] The entry ID to update
      # @param data [Hash] The entry data to update
      # @option data [Hash] :values Field values to update
      # @option data [String] :notes Updated notes for the entry
      #
      # @return [Hash] The updated entry data
      # @raise [ArgumentError] if parameters are invalid
      #
      # @example Update entry values
      #   entry = client.lists.update_entry(
      #     id_or_slug: "vip_customers",
      #     entry_id: "ent_456",
      #     data: {
      #       values: { priority: "medium", last_contacted: "2024-01-15" },
      #       notes: "Updated contact information"
      #     }
      #   )
      #
      # @example Update only notes
      #   entry = client.lists.update_entry(
      #     id_or_slug: "lead_list",
      #     entry_id: "ent_789",
      #     data: { notes: "Follow up scheduled" }
      #   )
      def update_entry(id_or_slug:, entry_id:, data:)
        validate_id!(id_or_slug, "List")
        validate_id!(entry_id, "Entry")
        validate_list_entry_data!(data)

        request_body = { data: data }

        request(:patch, "lists/#{id_or_slug}/entries/#{entry_id}", request_body)
      end

      private def validate_list_entry_data!(data)
        raise ArgumentError, "Data is required" if data.nil?
        raise ArgumentError, "Data must be a hash" unless data.is_a?(Hash)
      end

      # Validates that the list data parameter is present and valid.
      #
      # @param data [Hash, nil] The data to validate
      # @raise [ArgumentError] if data is nil or not a hash
      # @api private
      private def validate_list_data!(data)
        raise ArgumentError, "Data is required" if data.nil?
        raise ArgumentError, "Data must be a hash" unless data.is_a?(Hash)
      end
    end
  end
end
