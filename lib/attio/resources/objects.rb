module Attio
  module Resources
    class Objects < Base
      def list(**params)
        request(:get, "objects", params)
      end

      def get(id_or_slug:)
        validate_id_or_slug!(id_or_slug)
        request(:get, "objects/#{id_or_slug}")
      end

      private

      def validate_id_or_slug!(id_or_slug)
        raise ArgumentError, "Object ID or slug is required" if id_or_slug.nil? || id_or_slug.to_s.strip.empty?
      end
    end
  end
end