module Attio
  module Resources
    class Users < Base
      def list(**params)
        request(:get, "users", params)
      end

      def get(id:)
        validate_id!(id)
        request(:get, "users/#{id}")
      end

      private

      def validate_id!(id)
        raise ArgumentError, "User ID is required" if id.nil? || id.to_s.strip.empty?
      end
    end
  end
end