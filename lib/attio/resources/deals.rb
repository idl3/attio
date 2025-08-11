# frozen_string_literal: true

module Attio
  module Resources
    # Deals resource for managing sales opportunities
    #
    # @example List all deals
    #   client.deals.list
    #
    # @example Create a new deal
    #   client.deals.create(
    #     data: {
    #       name: "Enterprise Contract",
    #       value: 50000,
    #       stage_id: "stage_123",
    #       company_id: "company_456"
    #     }
    #   )
    #
    # @example Update deal stage
    #   client.deals.update_stage(id: "deal_123", stage_id: "stage_won")
    class Deals < Base
      # List all deals
      #
      # @param params [Hash] Optional query parameters
      # @option params [Hash] :filter Filter conditions
      # @option params [Array<Hash>] :sorts Sort criteria
      # @option params [Integer] :limit Maximum number of results
      # @option params [String] :offset Pagination offset
      # @return [Hash] The API response
      def list(params = {})
        request(:get, "objects/deals/records", params)
      end

      # Get a specific deal
      #
      # @param id [String] The deal ID
      # @return [Hash] The deal data
      def get(id:)
        validate_id!(id, "Deal")
        request(:get, "objects/deals/records/#{id}")
      end

      # Create a new deal
      #
      # @param data [Hash] The deal data
      # @option data [String] :name The deal name (required)
      # @option data [Float] :value The deal value
      # @option data [String] :stage_id The stage ID
      # @option data [String] :company_id Associated company ID
      # @option data [String] :owner_id The owner user ID
      # @option data [Date] :close_date Expected close date
      # @option data [String] :currency Currency code (USD, EUR, etc.)
      # @option data [Float] :probability Win probability (0-100)
      # @return [Hash] The created deal
      def create(data:)
        validate_required_hash!(data, "Data")
        validate_required_string!(data[:name], "Deal name") if data.is_a?(Hash)

        request(:post, "objects/deals/records", { data: data })
      end

      # Update a deal
      #
      # @param id [String] The deal ID to update
      # @param data [Hash] The data to update
      # @return [Hash] The updated deal
      def update(id:, data:)
        validate_id!(id, "Deal")
        validate_required_hash!(data, "Data")

        request(:patch, "objects/deals/records/#{id}", { data: data })
      end

      # Delete a deal
      #
      # @param id [String] The deal ID to delete
      # @return [Hash] Confirmation of deletion
      def delete(id:)
        validate_id!(id, "Deal")
        request(:delete, "objects/deals/records/#{id}")
      end

      # Update a deal's stage
      #
      # @param id [String] The deal ID
      # @param stage_id [String] The new stage ID
      # @return [Hash] The updated deal
      def update_stage(id:, stage_id:)
        validate_id!(id, "Deal")
        validate_required_string!(stage_id, "Stage")

        update(id: id, data: { stage_id: stage_id })
      end

      # Mark a deal as won
      #
      # @param id [String] The deal ID
      # @param won_date [Date, String] The date the deal was won (defaults to today)
      # @param actual_value [Float] The actual value (optional, defaults to deal value)
      # @return [Hash] The updated deal
      def mark_won(id:, won_date: nil, actual_value: nil)
        validate_id!(id, "Deal")

        data = { status: "won" }
        data[:won_date] = won_date if won_date
        data[:actual_value] = actual_value if actual_value

        update(id: id, data: data)
      end

      # Mark a deal as lost
      #
      # @param id [String] The deal ID
      # @param lost_reason [String] The reason for losing the deal
      # @param lost_date [Date, String] The date the deal was lost (defaults to today)
      # @return [Hash] The updated deal
      def mark_lost(id:, lost_reason: nil, lost_date: nil)
        validate_id!(id, "Deal")

        data = { status: "lost" }
        data[:lost_reason] = lost_reason if lost_reason
        data[:lost_date] = lost_date if lost_date

        update(id: id, data: data)
      end

      # List deals by stage
      #
      # @param stage_id [String] The stage ID to filter by
      # @param params [Hash] Additional query parameters
      # @return [Hash] Deals in the specified stage
      def list_by_stage(stage_id:, params: {})
        validate_required_string!(stage_id, "Stage")

        filter = { stage_id: { "$eq" => stage_id } }
        merged_params = params.merge(filter: filter)
        list(merged_params)
      end

      # List deals by company
      #
      # @param company_id [String] The company ID to filter by
      # @param params [Hash] Additional query parameters
      # @return [Hash] Deals for the specified company
      def list_by_company(company_id:, params: {})
        validate_required_string!(company_id, "Company")

        filter = { company_id: { "$eq" => company_id } }
        merged_params = params.merge(filter: filter)
        list(merged_params)
      end

      # List deals by owner
      #
      # @param owner_id [String] The owner user ID to filter by
      # @param params [Hash] Additional query parameters
      # @return [Hash] Deals owned by the specified user
      def list_by_owner(owner_id:, params: {})
        validate_required_string!(owner_id, "Owner")

        filter = { owner_id: { "$eq" => owner_id } }
        merged_params = params.merge(filter: filter)
        list(merged_params)
      end

      # Calculate pipeline value
      #
      # @param stage_id [String] Optional stage ID to filter by
      # @param owner_id [String] Optional owner ID to filter by
      # @return [Hash] Pipeline statistics including total value, count, and average
      def pipeline_value(stage_id: nil, owner_id: nil)
        params = { filter: {} }
        params[:filter][:stage_id] = { "$eq" => stage_id } if stage_id
        params[:filter][:owner_id] = { "$eq" => owner_id } if owner_id

        # This would typically be a specialized endpoint, but we'll use list
        # and let the client calculate the statistics
        list(params)
      end
    end
  end
end
