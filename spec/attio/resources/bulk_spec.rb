# frozen_string_literal: true

RSpec.describe Attio::Resources::Bulk do
  let(:connection) { instance_double(Attio::HttpClient) }
  let(:client) { instance_double(Attio::Client, connection: connection) }
  let(:bulk) { described_class.new(client) }

  describe "#create_records" do
    it "bulk creates records in a single batch" do
      records = [
        { name: "Acme Corp", domain: "acme.com" },
        { name: "Tech Co", domain: "techco.com" }
      ]

      expected_body = {
        records: records.map { |r| { data: r } },
        partial_success: false,
        return_records: true
      }

      expected_response = {
        "success" => true,
        "records" => records.map.with_index { |r, i| r.merge("id" => "company_#{i}") },
        "statistics" => { "created" => 2, "failed" => 0 }
      }

      expect(connection).to receive(:post)
        .with("objects/companies/records/bulk", expected_body)
        .and_return(expected_response)

      result = bulk.create_records(object: "companies", records: records)

      expect(result["success"]).to be true
      expect(result["records"].size).to eq(2)
      expect(result["statistics"]["created"]).to eq(2)
    end

    it "handles multiple batches when exceeding MAX_BATCH_SIZE" do
      records = Array.new(150) { |i| { name: "Company #{i}" } }

      # First batch
      expect(connection).to receive(:post)
        .with("objects/companies/records/bulk", hash_including(records: anything))
        .and_return({
          "success" => true,
          "records" => Array.new(100) { |i| { "id" => "company_#{i}" } },
          "statistics" => { "created" => 100, "failed" => 0 }
        })

      # Second batch
      expect(connection).to receive(:post)
        .with("objects/companies/records/bulk", hash_including(records: anything))
        .and_return({
          "success" => true,
          "records" => Array.new(50) { |i| { "id" => "company_#{i + 100}" } },
          "statistics" => { "created" => 50, "failed" => 0 }
        })

      result = bulk.create_records(object: "companies", records: records)

      expect(result["total_batches"]).to eq(2)
      expect(result["records"].size).to eq(150)
      expect(result["statistics"]["created"]).to eq(150)
    end

    it "accepts partial_success option" do
      records = [{ name: "Test Co" }]

      expected_body = {
        records: [{ data: records.first }],
        partial_success: true,
        return_records: true
      }

      expect(connection).to receive(:post)
        .with("objects/companies/records/bulk", expected_body)
        .and_return({ "success" => true, "records" => [] })

      bulk.create_records(object: "companies", records: records, options: { partial_success: true })
    end

    it "raises error for nil records" do
      expect { bulk.create_records(object: "companies", records: nil) }
        .to raise_error(ArgumentError, "Records array is required for bulk create")
    end

    it "raises error for empty records" do
      expect { bulk.create_records(object: "companies", records: []) }
        .to raise_error(ArgumentError, "Records array cannot be empty for bulk create")
    end

    it "raises error for non-hash records" do
      expect { bulk.create_records(object: "companies", records: ["not a hash"]) }
        .to raise_error(ArgumentError, "Record at index 0 must be a hash")
    end

    it "raises error for too many records" do
      records = Array.new(1001) { { name: "Company" } }
      expect { bulk.create_records(object: "companies", records: records) }
        .to raise_error(ArgumentError, "Too many records (max 1000)")
    end
  end

  describe "#update_records" do
    it "bulk updates records" do
      updates = [
        { id: "person_123", data: { title: "CEO" } },
        { id: "person_456", data: { title: "CTO" } }
      ]

      expected_body = {
        updates: updates,
        partial_success: false,
        return_records: true
      }

      expected_response = {
        "success" => true,
        "records" => updates.map { |u| u[:data].merge("id" => u[:id]) },
        "statistics" => { "updated" => 2, "failed" => 0 }
      }

      expect(connection).to receive(:patch)
        .with("objects/people/records/bulk", expected_body)
        .and_return(expected_response)

      result = bulk.update_records(object: "people", updates: updates)

      expect(result["success"]).to be true
      expect(result["records"].size).to eq(2)
      expect(result["statistics"]["updated"]).to eq(2)
    end

    it "validates update structure" do
      expect { bulk.update_records(object: "people", updates: [{ data: { title: "CEO" } }]) }
        .to raise_error(ArgumentError, "Update at index 0 must have an :id")

      expect { bulk.update_records(object: "people", updates: [{ id: "person_123" }]) }
        .to raise_error(ArgumentError, "Update at index 0 must have :data")
    end

    it "raises error for nil updates" do
      expect { bulk.update_records(object: "people", updates: nil) }
        .to raise_error(ArgumentError, "Updates array is required for bulk update")
    end

    it "raises error for empty updates" do
      expect { bulk.update_records(object: "people", updates: []) }
        .to raise_error(ArgumentError, "Updates array cannot be empty for bulk update")
    end
  end

  describe "#delete_records" do
    it "bulk deletes records" do
      ids = ["company_123", "company_456", "company_789"]

      expected_body = {
        ids: ids,
        partial_success: false
      }

      expected_response = {
        "success" => true,
        "statistics" => { "deleted" => 3, "failed" => 0 }
      }

      expect(connection).to receive(:delete)
        .with("objects/companies/records/bulk", expected_body)
        .and_return(expected_response)

      result = bulk.delete_records(object: "companies", ids: ids)

      expect(result["success"]).to be true
      expect(result["statistics"]["deleted"]).to eq(3)
    end

    it "validates IDs" do
      expect { bulk.delete_records(object: "companies", ids: [nil, "company_123"]) }
        .to raise_error(ArgumentError, "ID at index 0 cannot be nil or empty")

      expect { bulk.delete_records(object: "companies", ids: ["", "company_123"]) }
        .to raise_error(ArgumentError, "ID at index 0 cannot be nil or empty")
    end

    it "raises error for nil ids" do
      expect { bulk.delete_records(object: "companies", ids: nil) }
        .to raise_error(ArgumentError, "IDs array is required for bulk operation")
    end

    it "raises error for empty ids" do
      expect { bulk.delete_records(object: "companies", ids: []) }
        .to raise_error(ArgumentError, "IDs array cannot be empty for bulk operation")
    end
  end

  describe "#upsert_records" do
    it "bulk upserts records based on match attribute" do
      records = [
        { email: "john@example.com", name: "John Doe", title: "CEO" },
        { email: "jane@example.com", name: "Jane Smith", title: "CTO" }
      ]

      expected_body = {
        records: records.map { |r| { data: r } },
        match_attribute: "email",
        partial_success: false,
        return_records: true
      }

      expected_response = {
        "success" => true,
        "records" => records.map.with_index { |r, i| r.merge("id" => "person_#{i}") },
        "statistics" => { "created" => 1, "updated" => 1, "failed" => 0 }
      }

      expect(connection).to receive(:put)
        .with("objects/people/records/bulk", expected_body)
        .and_return(expected_response)

      result = bulk.upsert_records(
        object: "people",
        records: records,
        match_attribute: "email"
      )

      expect(result["success"]).to be true
      expect(result["records"].size).to eq(2)
      expect(result["statistics"]["created"]).to eq(1)
      expect(result["statistics"]["updated"]).to eq(1)
    end

    it "raises error for nil match_attribute" do
      expect { bulk.upsert_records(object: "people", records: [{ email: "test@example.com" }], match_attribute: nil) }
        .to raise_error(ArgumentError, "Match attribute is required")
    end

    it "raises error for empty match_attribute" do
      expect { bulk.upsert_records(object: "people", records: [{ email: "test@example.com" }], match_attribute: "") }
        .to raise_error(ArgumentError, "Match attribute is required")
    end
  end

  describe "#add_list_entries" do
    it "bulk adds entries to a list" do
      list_id = "list_123"
      entries = [
        { record_id: "company_456" },
        { record_id: "company_789" }
      ]

      expected_body = {
        entries: entries,
        partial_success: false
      }

      expected_response = {
        "success" => true,
        "records" => entries.map.with_index { |e, i| e.merge("id" => "entry_#{i}") },
        "statistics" => { "created" => 2, "failed" => 0 }
      }

      expect(connection).to receive(:post)
        .with("lists/#{list_id}/entries/bulk", expected_body)
        .and_return(expected_response)

      result = bulk.add_list_entries(list_id: list_id, entries: entries)

      expect(result["success"]).to be true
      expect(result["records"].size).to eq(2)
      expect(result["statistics"]["created"]).to eq(2)
    end

    it "raises error for nil list_id" do
      expect { bulk.add_list_entries(list_id: nil, entries: [{ record_id: "company_123" }]) }
        .to raise_error(ArgumentError, "List ID is required")
    end

    it "raises error for nil entries" do
      expect { bulk.add_list_entries(list_id: "list_123", entries: nil) }
        .to raise_error(ArgumentError, "Records array is required for bulk add to list")
    end
  end

  describe "#remove_list_entries" do
    it "bulk removes entries from a list" do
      list_id = "list_123"
      entry_ids = ["entry_456", "entry_789"]

      expected_body = {
        entry_ids: entry_ids,
        partial_success: false
      }

      expected_response = {
        "success" => true,
        "statistics" => { "deleted" => 2, "failed" => 0 }
      }

      expect(connection).to receive(:delete)
        .with("lists/#{list_id}/entries/bulk", expected_body)
        .and_return(expected_response)

      result = bulk.remove_list_entries(list_id: list_id, entry_ids: entry_ids)

      expect(result["success"]).to be true
      expect(result["statistics"]["deleted"]).to eq(2)
    end

    it "raises error for nil list_id" do
      expect { bulk.remove_list_entries(list_id: nil, entry_ids: ["entry_123"]) }
        .to raise_error(ArgumentError, "List ID is required")
    end

    it "raises error for nil entry_ids" do
      expect { bulk.remove_list_entries(list_id: "list_123", entry_ids: nil) }
        .to raise_error(ArgumentError, "IDs array is required for bulk operation")
    end
  end

  describe "batch merging" do
    it "correctly merges results from multiple batches" do
      records = Array.new(150) { |i| { name: "Company #{i}" } }

      batch1_response = {
        "success" => true,
        "records" => Array.new(100) { { "id" => "company_1" } },
        "errors" => [],
        "statistics" => { "created" => 100, "failed" => 0 }
      }

      batch2_response = {
        "success" => true,
        "records" => Array.new(50) { { "id" => "company_2" } },
        "errors" => [{ "error" => "Some error" }],
        "statistics" => { "created" => 49, "failed" => 1 }
      }

      expect(connection).to receive(:post).twice
        .and_return(batch1_response, batch2_response)

      result = bulk.create_records(object: "companies", records: records)

      expect(result["total_batches"]).to eq(2)
      expect(result["records"].size).to eq(150)
      expect(result["errors"].size).to eq(1)
      expect(result["statistics"]["created"]).to eq(149)
      expect(result["statistics"]["failed"]).to eq(1)
      expect(result["success"]).to be true
    end

    it "sets success to false if any batch fails" do
      records = Array.new(150) { |i| { name: "Company #{i}" } }

      batch1_response = {
        "success" => true,
        "records" => Array.new(100) { { "id" => "company_1" } },
        "statistics" => { "created" => 100 }
      }

      batch2_response = {
        "success" => false,
        "records" => [],
        "errors" => [{ "error" => "Batch failed" }],
        "statistics" => { "failed" => 50 }
      }

      expect(connection).to receive(:post).twice
        .and_return(batch1_response, batch2_response)

      result = bulk.create_records(object: "companies", records: records)

      expect(result["success"]).to be false
      expect(result["errors"].size).to eq(1)
    end
  end
end