# frozen_string_literal: true

module Attio
  module Resources
    # Meta resource for getting information about the API token and workspace
    #
    # The Meta resource provides a single endpoint (/v2/self) that returns
    # information about the current access token, workspace, and permissions.
    #
    # @example Get token and workspace information
    #   meta_info = client.meta.identify
    #   puts "Workspace: #{meta_info['data']['workspace_name']}"
    #   puts "Token active: #{meta_info['data']['active']}"
    #
    # @example Check if token is active
    #   if client.meta.active?
    #     puts "Token is valid and active"
    #   end
    #
    # @example Get workspace details
    #   workspace = client.meta.workspace
    #   puts "Working in: #{workspace['name']} (#{workspace['id']})"
    #
    # @example Check permissions
    #   if client.meta.permission?("record_permission:read-write")
    #     # Can read and write records
    #   end
    class Meta < Base
      # Get information about the current access token and workspace
      #
      # This is the primary method that calls the /v2/self endpoint.
      # Returns full token metadata including workspace info and permissions.
      #
      # @return [Hash] Token and workspace information
      # @example
      #   info = client.meta.identify
      #   # => { "data" => { "active" => true, "workspace_name" => "My Workspace", ... } }
      def identify
        request(:get, "self")
      end

      # Alias methods for convenience and clarity
      alias self identify
      alias get identify

      # Check if the current token is active
      #
      # @return [Boolean] true if token is active, false otherwise
      # @example
      #   if client.meta.active?
      #     # Proceed with API calls
      #   else
      #     # Token is inactive or invalid
      #   end
      def active?
        response = identify
        response.dig("data", "active") || false
      end

      # Get the workspace information
      #
      # Returns workspace details if token is active, nil otherwise.
      #
      # @return [Hash, nil] Workspace details or nil if token inactive
      # @example
      #   workspace = client.meta.workspace
      #   # => { "id" => "uuid", "name" => "My Workspace", "slug" => "my-workspace", "logo_url" => nil }
      def workspace
        response = identify
        return nil unless response.dig("data", "active")

        {
          "id" => response.dig("data", "workspace_id"),
          "name" => response.dig("data", "workspace_name"),
          "slug" => response.dig("data", "workspace_slug"),
          "logo_url" => response.dig("data", "workspace_logo_url"),
        }
      end

      # Get the token's permissions/scopes
      #
      # Parses the space-separated scope string into an array.
      #
      # @return [Array<String>] List of permission scopes
      # @example
      #   permissions = client.meta.permissions
      #   # => ["comment:read-write", "list_configuration:read", "note:read-write"]
      def permissions
        response = identify
        scope = response.dig("data", "scope") || ""
        scope.split
      end

      # Check if token has a specific permission
      #
      # @param permission [String] The permission to check (e.g., "comment:read-write")
      # @return [Boolean] true if permission is granted
      # @example
      #   if client.meta.permission?("record_permission:read-write")
      #     # Can manage records
      #   end
      def permission?(permission)
        permissions.include?(permission)
      end

      # Alias for backward compatibility
      alias has_permission? permission?

      # Get token expiration and metadata
      #
      # Returns detailed token information including expiration,
      # issue time, client ID, and who authorized it.
      #
      # @return [Hash] Token metadata
      # @example
      #   info = client.meta.token_info
      #   # => { "active" => true, "type" => "Bearer", "expires_at" => nil, ... }
      def token_info
        response = identify
        return { "active" => false } unless response.dig("data", "active")

        {
          "active" => true,
          "type" => response.dig("data", "token_type"),
          "expires_at" => response.dig("data", "exp"),
          "issued_at" => response.dig("data", "iat"),
          "client_id" => response.dig("data", "client_id"),
          "authorized_by" => response.dig("data", "authorized_by_workspace_member_id"),
        }
      end
    end
  end
end
