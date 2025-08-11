# frozen_string_literal: true

RSpec.describe Attio::Resources::Deals do
  let(:connection) { instance_double(Attio::HttpClient) }
  let(:client) { instance_double(Attio::Client, connection: connection) }
  let(:deals) { described_class.new(client) }

  describe "#list" do
    it "lists all deals" do
      expect(connection).to receive(:get)
        .with("objects/deals/records")
        .and_return({ "data" => [] })

      result = deals.list
      expect(result).to eq({ "data" => [] })
    end

    it "lists deals with filters and sorts" do
      params = {
        filter: { value: { "$gte" => 10_000 } },
        sorts: [{ attribute: "value", direction: "desc" }],
        limit: 20
      }

      expect(connection).to receive(:get)
        .with("objects/deals/records", params)
        .and_return({ "data" => [] })

      result = deals.list(params)
      expect(result).to eq({ "data" => [] })
    end
  end

  describe "#get" do
    it "gets a specific deal" do
      deal_id = "deal_123"
      expect(connection).to receive(:get)
        .with("objects/deals/records/#{deal_id}")
        .and_return({ "id" => deal_id, "name" => "Big Deal" })

      result = deals.get(id: deal_id)
      expect(result).to eq({ "id" => deal_id, "name" => "Big Deal" })
    end

    it "raises error for nil deal_id" do
      expect { deals.get(id: nil) }
        .to raise_error(ArgumentError, "Deal ID is required")
    end

    it "raises error for empty deal_id" do
      expect { deals.get(id: "") }
        .to raise_error(ArgumentError, "Deal ID is required")
    end
  end

  describe "#create" do
    it "creates a new deal" do
      data = {
        name: "Enterprise Contract",
        value: 50_000,
        stage_id: "stage_123",
        company_id: "company_456"
      }

      expect(connection).to receive(:post)
        .with("objects/deals/records", { data: data })
        .and_return({ "id" => "deal_789", "name" => "Enterprise Contract" })

      result = deals.create(data: data)
      expect(result).to eq({ "id" => "deal_789", "name" => "Enterprise Contract" })
    end

    it "creates a deal with all fields" do
      data = {
        name: "Complex Deal",
        value: 100_000,
        stage_id: "stage_123",
        company_id: "company_456",
        owner_id: "user_789",
        close_date: "2024-12-31",
        currency: "USD",
        probability: 75
      }

      expect(connection).to receive(:post)
        .with("objects/deals/records", { data: data })
        .and_return({ "id" => "deal_999" })

      result = deals.create(data: data)
      expect(result).to eq({ "id" => "deal_999" })
    end

    it "raises error for nil data" do
      expect { deals.create(data: nil) }
        .to raise_error(ArgumentError, "Data must be a hash")
    end

    it "raises error for missing deal name" do
      expect { deals.create(data: { value: 1000 }) }
        .to raise_error(ArgumentError, "Deal name is required")
    end
  end

  describe "#update" do
    it "updates a deal" do
      deal_id = "deal_123"
      data = { value: 75_000, probability: 90 }

      expect(connection).to receive(:patch)
        .with("objects/deals/records/#{deal_id}", { data: data })
        .and_return({ "id" => deal_id, "value" => 75_000 })

      result = deals.update(id: deal_id, data: data)
      expect(result).to eq({ "id" => deal_id, "value" => 75_000 })
    end

    it "raises error for nil deal_id" do
      expect { deals.update(id: nil, data: {}) }
        .to raise_error(ArgumentError, "Deal ID is required")
    end

    it "raises error for nil data" do
      expect { deals.update(id: "deal_123", data: nil) }
        .to raise_error(ArgumentError, "Data must be a hash")
    end
  end

  describe "#delete" do
    it "deletes a deal" do
      deal_id = "deal_123"

      expect(connection).to receive(:delete)
        .with("objects/deals/records/#{deal_id}")
        .and_return({ "success" => true })

      result = deals.delete(id: deal_id)
      expect(result).to eq({ "success" => true })
    end

    it "raises error for nil deal_id" do
      expect { deals.delete(id: nil) }
        .to raise_error(ArgumentError, "Deal ID is required")
    end
  end

  describe "#update_stage" do
    it "updates a deal's stage" do
      deal_id = "deal_123"
      stage_id = "stage_won"

      expect(connection).to receive(:patch)
        .with("objects/deals/records/#{deal_id}", { data: { stage_id: stage_id } })
        .and_return({ "id" => deal_id, "stage_id" => stage_id })

      result = deals.update_stage(id: deal_id, stage_id: stage_id)
      expect(result).to eq({ "id" => deal_id, "stage_id" => stage_id })
    end

    it "raises error for nil stage_id" do
      expect { deals.update_stage(id: "deal_123", stage_id: nil) }
        .to raise_error(ArgumentError, "Stage is required")
    end

    it "raises error for empty stage_id" do
      expect { deals.update_stage(id: "deal_123", stage_id: "") }
        .to raise_error(ArgumentError, "Stage is required")
    end
  end

  describe "#mark_won" do
    it "marks a deal as won" do
      deal_id = "deal_123"

      expect(connection).to receive(:patch)
        .with("objects/deals/records/#{deal_id}", { data: { status: "won" } })
        .and_return({ "id" => deal_id, "status" => "won" })

      result = deals.mark_won(id: deal_id)
      expect(result).to eq({ "id" => deal_id, "status" => "won" })
    end

    it "marks a deal as won with date and actual value" do
      deal_id = "deal_123"
      won_date = "2024-01-15"
      actual_value = 45_000

      expected_data = { status: "won", won_date: won_date, actual_value: actual_value }

      expect(connection).to receive(:patch)
        .with("objects/deals/records/#{deal_id}", { data: expected_data })
        .and_return({ "id" => deal_id, "status" => "won" })

      result = deals.mark_won(id: deal_id, won_date: won_date, actual_value: actual_value)
      expect(result).to eq({ "id" => deal_id, "status" => "won" })
    end

    it "raises error for nil deal_id" do
      expect { deals.mark_won(id: nil) }
        .to raise_error(ArgumentError, "Deal ID is required")
    end
  end

  describe "#mark_lost" do
    it "marks a deal as lost" do
      deal_id = "deal_123"

      expect(connection).to receive(:patch)
        .with("objects/deals/records/#{deal_id}", { data: { status: "lost" } })
        .and_return({ "id" => deal_id, "status" => "lost" })

      result = deals.mark_lost(id: deal_id)
      expect(result).to eq({ "id" => deal_id, "status" => "lost" })
    end

    it "marks a deal as lost with reason and date" do
      deal_id = "deal_123"
      lost_reason = "Budget constraints"
      lost_date = "2024-01-10"

      expected_data = { status: "lost", lost_reason: lost_reason, lost_date: lost_date }

      expect(connection).to receive(:patch)
        .with("objects/deals/records/#{deal_id}", { data: expected_data })
        .and_return({ "id" => deal_id, "status" => "lost" })

      result = deals.mark_lost(id: deal_id, lost_reason: lost_reason, lost_date: lost_date)
      expect(result).to eq({ "id" => deal_id, "status" => "lost" })
    end

    it "raises error for nil deal_id" do
      expect { deals.mark_lost(id: nil) }
        .to raise_error(ArgumentError, "Deal ID is required")
    end
  end

  describe "#list_by_stage" do
    it "lists deals by stage" do
      stage_id = "stage_negotiation"
      expected_params = { filter: { stage_id: { "$eq" => stage_id } } }

      expect(connection).to receive(:get)
        .with("objects/deals/records", expected_params)
        .and_return({ "data" => [] })

      result = deals.list_by_stage(stage_id: stage_id)
      expect(result).to eq({ "data" => [] })
    end

    it "lists deals by stage with additional params" do
      stage_id = "stage_qualified"
      additional_params = { limit: 10, sorts: [{ attribute: "value", direction: "desc" }] }
      expected_params = additional_params.merge(filter: { stage_id: { "$eq" => stage_id } })

      expect(connection).to receive(:get)
        .with("objects/deals/records", expected_params)
        .and_return({ "data" => [] })

      result = deals.list_by_stage(stage_id: stage_id, params: additional_params)
      expect(result).to eq({ "data" => [] })
    end

    it "raises error for nil stage_id" do
      expect { deals.list_by_stage(stage_id: nil) }
        .to raise_error(ArgumentError, "Stage is required")
    end
  end

  describe "#list_by_company" do
    it "lists deals by company" do
      company_id = "company_456"
      expected_params = { filter: { company_id: { "$eq" => company_id } } }

      expect(connection).to receive(:get)
        .with("objects/deals/records", expected_params)
        .and_return({ "data" => [] })

      result = deals.list_by_company(company_id: company_id)
      expect(result).to eq({ "data" => [] })
    end

    it "raises error for nil company_id" do
      expect { deals.list_by_company(company_id: nil) }
        .to raise_error(ArgumentError, "Company is required")
    end
  end

  describe "#list_by_owner" do
    it "lists deals by owner" do
      owner_id = "user_789"
      expected_params = { filter: { owner_id: { "$eq" => owner_id } } }

      expect(connection).to receive(:get)
        .with("objects/deals/records", expected_params)
        .and_return({ "data" => [] })

      result = deals.list_by_owner(owner_id: owner_id)
      expect(result).to eq({ "data" => [] })
    end

    it "raises error for nil owner_id" do
      expect { deals.list_by_owner(owner_id: nil) }
        .to raise_error(ArgumentError, "Owner is required")
    end
  end

  describe "#pipeline_value" do
    it "gets pipeline value for all deals" do
      expect(connection).to receive(:get)
        .with("objects/deals/records", { filter: {} })
        .and_return({ "data" => [] })

      result = deals.pipeline_value
      expect(result).to eq({ "data" => [] })
    end

    it "gets pipeline value by stage" do
      stage_id = "stage_proposal"
      expected_params = { filter: { stage_id: { "$eq" => stage_id } } }

      expect(connection).to receive(:get)
        .with("objects/deals/records", expected_params)
        .and_return({ "data" => [] })

      result = deals.pipeline_value(stage_id: stage_id)
      expect(result).to eq({ "data" => [] })
    end

    it "gets pipeline value by owner" do
      owner_id = "user_123"
      expected_params = { filter: { owner_id: { "$eq" => owner_id } } }

      expect(connection).to receive(:get)
        .with("objects/deals/records", expected_params)
        .and_return({ "data" => [] })

      result = deals.pipeline_value(owner_id: owner_id)
      expect(result).to eq({ "data" => [] })
    end

    it "gets pipeline value by stage and owner" do
      stage_id = "stage_qualified"
      owner_id = "user_456"
      expected_params = {
        filter: {
          stage_id: { "$eq" => stage_id },
          owner_id: { "$eq" => owner_id }
        }
      }

      expect(connection).to receive(:get)
        .with("objects/deals/records", expected_params)
        .and_return({ "data" => [] })

      result = deals.pipeline_value(stage_id: stage_id, owner_id: owner_id)
      expect(result).to eq({ "data" => [] })
    end
  end
end