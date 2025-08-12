# frozen_string_literal: true

module Attio
  module Resources
    # API resource for managing Attio attributes
    #
    # Attributes define custom fields that can be added to objects
    # and records in your Attio workspace.
    #
    # @example Listing attributes
    #   client.attributes.list(object: "people")
    #
    # @example Creating a custom attribute
    #   client.attributes.create(
    #     object: "deals",
    #     data: {
    #       title: "Deal Stage",
    #       api_slug: "deal_stage",
    #       type: "select",
    #       options: [
    #         { title: "Lead", value: "lead" },
    #         { title: "Qualified", value: "qualified" }
    #       ]
    #     }
    #   )
    class Attributes < Base
      def list(object:, **params)
        validate_object!(object)
        request(:get, "objects/#{object}/attributes", params)
      end

      def get(object:, id_or_slug:)
        validate_object!(object)
        validate_id_or_slug!(id_or_slug)
        request(:get, "objects/#{object}/attributes/#{id_or_slug}")
      end

      # Create a custom attribute for an object
      #
      # @param object [String] The object type or slug
      # @param data [Hash] The attribute configuration
      # @option data [String] :title The display title of the attribute
      # @option data [String] :api_slug The API slug for the attribute
      # @option data [String] :type The attribute type (text, number, select, date, etc.)
      # @option data [String] :description Optional description
      # @option data [Boolean] :is_required Whether the attribute is required
      # @option data [Boolean] :is_unique Whether the attribute must be unique
      # @option data [Boolean] :is_multiselect For select types, whether multiple values are allowed
      # @option data [Array<Hash>] :options For select types, the available options
      # @return [Hash] The created attribute
      # @example Create a select attribute
      #   client.attributes.create(
      #     object: "trips",
      #     data: {
      #       title: "Status",
      #       api_slug: "status",
      #       type: "select",
      #       options: [
      #         { title: "Pending", value: "pending" },
      #         { title: "Active", value: "active" }
      #       ]
      #     }
      #   )
      def create(object:, data:)
        validate_object!(object)
        validate_required_hash!(data, "Attribute data")

        # Wrap data in the expected format
        payload = { data: data }

        request(:post, "objects/#{object}/attributes", payload)
      end

      # Update an existing attribute
      #
      # @param object [String] The object type or slug
      # @param id_or_slug [String] The attribute ID or API slug
      # @param data [Hash] The attribute configuration updates
      # @option data [String] :title The display title of the attribute
      # @option data [String] :api_slug The API slug for the attribute
      # @option data [String] :description Optional description
      # @option data [Boolean] :is_required Whether the attribute is required
      # @option data [Boolean] :is_unique Whether the attribute must be unique
      # @option data [Boolean] :is_multiselect For select types, whether multiple values are allowed
      # @return [Hash] The updated attribute
      # @example Update an attribute's title
      #   client.attributes.update(
      #     object: "contacts",
      #     id_or_slug: "status",
      #     data: {
      #       title: "Contact Status",
      #       description: "The current status of the contact"
      #     }
      #   )
      def update(object:, id_or_slug:, data:)
        validate_object!(object)
        validate_id_or_slug!(id_or_slug)
        validate_required_hash!(data, "Attribute data")

        # Wrap data in the expected format
        payload = { data: data }

        request(:patch, "objects/#{object}/attributes/#{id_or_slug}", payload)
      end

      # List options for a select attribute
      #
      # @param object [String] The object type or slug
      # @param id_or_slug [String] The attribute ID or API slug
      # @param params [Hash] Additional query parameters
      # @option params [Integer] :limit Number of results to return
      # @option params [Integer] :offset Number of results to skip
      # @return [Hash] The list of attribute options
      # @example List options for a select attribute
      #   client.attributes.list_options(
      #     object: "deals",
      #     id_or_slug: "deal_stage"
      #   )
      def list_options(object:, id_or_slug:, **params)
        validate_object!(object)
        validate_id_or_slug!(id_or_slug)
        request(:get, "objects/#{object}/attributes/#{id_or_slug}/options", params)
      end

      # Create a new option for a select attribute
      #
      # @param object [String] The object type or slug
      # @param id_or_slug [String] The attribute ID or API slug
      # @param data [Hash] The option configuration
      # @option data [String] :title The display title of the option
      # @option data [String] :value The value of the option
      # @option data [String] :color Optional color for the option
      # @option data [Integer] :order Optional order for the option
      # @return [Hash] The created option
      # @example Create a new option
      #   client.attributes.create_option(
      #     object: "deals",
      #     id_or_slug: "deal_stage",
      #     data: {
      #       title: "Negotiation",
      #       value: "negotiation",
      #       color: "blue"
      #     }
      #   )
      def create_option(object:, id_or_slug:, data:)
        validate_object!(object)
        validate_id_or_slug!(id_or_slug)
        validate_required_hash!(data, "Option data")

        request(:post, "objects/#{object}/attributes/#{id_or_slug}/options", data)
      end

      # Update an option for a select attribute
      #
      # @param object [String] The object type or slug
      # @param id_or_slug [String] The attribute ID or API slug
      # @param option [String] The option ID or value
      # @param data [Hash] The option configuration updates
      # @option data [String] :title The display title of the option
      # @option data [String] :value The value of the option
      # @option data [String] :color Optional color for the option
      # @option data [Integer] :order Optional order for the option
      # @return [Hash] The updated option
      # @example Update an option's title
      #   client.attributes.update_option(
      #     object: "deals",
      #     id_or_slug: "deal_stage",
      #     option: "negotiation",
      #     data: {
      #       title: "In Negotiation",
      #       color: "orange"
      #     }
      #   )
      def update_option(object:, id_or_slug:, option:, data:)
        validate_object!(object)
        validate_id_or_slug!(id_or_slug)
        validate_option_id!(option)
        validate_required_hash!(data, "Option data")

        request(:patch, "objects/#{object}/attributes/#{id_or_slug}/options/#{option}", data)
      end

      # List statuses for a status attribute
      #
      # @param object [String] The object type or slug
      # @param id_or_slug [String] The attribute ID or API slug
      # @param params [Hash] Additional query parameters
      # @option params [Integer] :limit Number of results to return
      # @option params [Integer] :offset Number of results to skip
      # @return [Hash] The list of attribute statuses
      # @example List statuses for a status attribute
      #   client.attributes.list_statuses(
      #     object: "deals",
      #     id_or_slug: "deal_status"
      #   )
      def list_statuses(object:, id_or_slug:, **params)
        validate_object!(object)
        validate_id_or_slug!(id_or_slug)
        request(:get, "objects/#{object}/attributes/#{id_or_slug}/statuses", params)
      end

      # Create a new status for a status attribute
      #
      # @param object [String] The object type or slug
      # @param id_or_slug [String] The attribute ID or API slug
      # @param data [Hash] The status configuration
      # @option data [String] :title The display title of the status
      # @option data [String] :value The value of the status
      # @option data [String] :color Optional color for the status
      # @option data [Integer] :order Optional order for the status
      # @return [Hash] The created status
      # @example Create a new status
      #   client.attributes.create_status(
      #     object: "deals",
      #     id_or_slug: "deal_status",
      #     data: {
      #       title: "Under Review",
      #       value: "under_review",
      #       color: "yellow"
      #     }
      #   )
      def create_status(object:, id_or_slug:, data:)
        validate_object!(object)
        validate_id_or_slug!(id_or_slug)
        validate_required_hash!(data, "Status data")

        request(:post, "objects/#{object}/attributes/#{id_or_slug}/statuses", data)
      end

      # Update a status for a status attribute
      #
      # @param object [String] The object type or slug
      # @param id_or_slug [String] The attribute ID or API slug
      # @param status [String] The status ID or value
      # @param data [Hash] The status configuration updates
      # @option data [String] :title The display title of the status
      # @option data [String] :value The value of the status
      # @option data [String] :color Optional color for the status
      # @option data [Integer] :order Optional order for the status
      # @return [Hash] The updated status
      # @example Update a status's title
      #   client.attributes.update_status(
      #     object: "deals",
      #     id_or_slug: "deal_status",
      #     status: "under_review",
      #     data: {
      #       title: "Pending Review",
      #       color: "orange"
      #     }
      #   )
      def update_status(object:, id_or_slug:, status:, data:)
        validate_object!(object)
        validate_id_or_slug!(id_or_slug)
        validate_status_id!(status)
        validate_required_hash!(data, "Status data")

        request(:patch, "objects/#{object}/attributes/#{id_or_slug}/statuses/#{status}", data)
      end

      private def validate_object!(object)
        raise ArgumentError, "Object type is required" if object.nil? || object.to_s.strip.empty?
      end

      private def validate_id_or_slug!(id_or_slug)
        raise ArgumentError, "Attribute ID or slug is required" if id_or_slug.nil? || id_or_slug.to_s.strip.empty?
      end

      private def validate_option_id!(option)
        raise ArgumentError, "Option ID is required" if option.nil? || option.to_s.strip.empty?
      end

      private def validate_status_id!(status)
        raise ArgumentError, "Status ID is required" if status.nil? || status.to_s.strip.empty?
      end
    end
  end
end
