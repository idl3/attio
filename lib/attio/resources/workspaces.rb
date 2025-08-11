# frozen_string_literal: true

module Attio
  module Resources
    # API resource for managing workspace information
    #
    # Workspaces are the top-level organizational unit in Attio.
    #
    # @example Getting workspace information
    #   client.workspaces.get
    class Workspaces < Base
      def get
        request(:get, "workspace")
      end

      def members(**params)
        request(:get, "workspace/members", params)
      end
    end
  end
end
