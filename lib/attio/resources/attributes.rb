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

      private def validate_object!(object)
        raise ArgumentError, "Object type is required" if object.nil? || object.to_s.strip.empty?
      end

      private def validate_id_or_slug!(id_or_slug)
        raise ArgumentError, "Attribute ID or slug is required" if id_or_slug.nil? || id_or_slug.to_s.strip.empty?
      end
    end
  end
end
