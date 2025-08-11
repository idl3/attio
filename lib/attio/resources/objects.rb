# frozen_string_literal: true

module Attio
  module Resources
    # API resource for managing Attio objects
    #
    # Objects define the schema and structure for different types of
    # records in your Attio workspace (e.g., people, companies).
    #
    # @example Listing all objects
    #   client.objects.list
    class Objects < Base
      def list(**params)
        request(:get, "objects", params)
      end

      def get(id_or_slug:)
        validate_id_or_slug!(id_or_slug)
        request(:get, "objects/#{id_or_slug}")
      end

      private def validate_id_or_slug!(id_or_slug)
        raise ArgumentError, "Object ID or slug is required" if id_or_slug.nil? || id_or_slug.to_s.strip.empty?
      end
    end
  end
end
