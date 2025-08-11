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

      private def validate_object!(object)
        raise ArgumentError, "Object type is required" if object.nil? || object.to_s.strip.empty?
      end

      private def validate_id_or_slug!(id_or_slug)
        raise ArgumentError, "Attribute ID or slug is required" if id_or_slug.nil? || id_or_slug.to_s.strip.empty?
      end
    end
  end
end
