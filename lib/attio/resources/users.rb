# frozen_string_literal: true

module Attio
  module Resources
    # API resource for managing workspace users
    #
    # Users are people who have access to your Attio workspace.
    #
    # @example Listing all users
    #   client.users.list
    class Users < Base
      def list(**params)
        request(:get, "users", params)
      end

      def get(id:)
        validate_id!(id)
        request(:get, "users/#{id}")
      end

      private def validate_id!(id)
        raise ArgumentError, "User ID is required" if id.nil? || id.to_s.strip.empty?
      end
    end
  end
end
