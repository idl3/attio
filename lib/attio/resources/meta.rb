# frozen_string_literal: true

module Attio
  module Resources
    # Meta resource for API metadata and identification
    #
    # @example Identify the current API key
    #   client.meta.identify
    #   # => { "workspace" => { "id" => "...", "name" => "..." }, "user" => { ... } }
    #
    # @example Get API status
    #   client.meta.status
    #   # => { "status" => "operational", "version" => "v2" }
    class Meta < Base
      # Identify the current API key and get workspace/user information
      #
      # @return [Hash] Information about the authenticated workspace and user
      def identify
        request(:get, "meta/identify")
      end

      # Get API status and version information
      #
      # @return [Hash] API status and version details
      def status
        request(:get, "meta/status")
      end

      # Get rate limit information for the current API key
      #
      # @return [Hash] Current rate limit status
      def rate_limits
        request(:get, "meta/rate_limits")
      end

      # Get workspace configuration and settings
      #
      # @return [Hash] Workspace configuration details
      def workspace_config
        request(:get, "meta/workspace_config")
      end

      # Validate an API key without making changes
      #
      # @return [Hash] Validation result with key permissions
      def validate_key
        request(:post, "meta/validate", {})
      end

      # Get available API endpoints and their documentation
      #
      # @return [Hash] List of available endpoints with descriptions
      def endpoints
        request(:get, "meta/endpoints")
      end

      # Get workspace usage statistics
      #
      # @return [Hash] Usage statistics including record counts, API calls, etc.
      def usage_stats
        request(:get, "meta/usage")
      end

      # Get feature flags and capabilities for the workspace
      #
      # @return [Hash] Enabled features and capabilities
      def features
        request(:get, "meta/features")
      end
    end
  end
end
