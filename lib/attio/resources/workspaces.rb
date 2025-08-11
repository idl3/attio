module Attio
  module Resources
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