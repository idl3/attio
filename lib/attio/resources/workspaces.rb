# frozen_string_literal: true

module Attio
  module Resources
    # API resource for managing workspace information
    #
    # Workspaces are the top-level organizational unit in Attio.
    # Note: The workspace information is retrieved via the Meta API (/v2/self)
    #
    # @example Getting workspace information
    #   client.workspaces.get
    class Workspaces < Base
      # Get current workspace information
      #
      # This method retrieves workspace info from the /v2/self endpoint
      # which provides workspace context along with token information.
      #
      # @return [Hash] Workspace information from the self endpoint
      def get
        request(:get, "self")
      end

      # @deprecated Use client.workspace_members.list instead
      def members(**params)
        warn "[DEPRECATION] `workspaces.members` is deprecated. Use `workspace_members.list` instead."
        request(:get, "workspace_members", params)
      end
    end
  end
end
