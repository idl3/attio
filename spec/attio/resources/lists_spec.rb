# frozen_string_literal: true

RSpec.describe Attio::Resources::Lists do
  let(:client) { instance_double(Attio::Client) }
  let(:lists) { described_class.new(client) }

  describe "#list" do
    let(:params) { { limit: 10, offset: 0 } }
    let(:response) { { "data" => [{ "id" => "list123", "name" => "VIP Customers" }] } }

    before do
      allow(lists).to receive(:request).and_return(response)
    end

    it "makes a GET request to list lists" do
      expect(lists).to receive(:request).with(:get, "lists", params)
      lists.list(**params)
    end

    it "returns the response" do
      expect(lists.list).to eq(response)
    end

    it "accepts optional parameters" do
      expect(lists).to receive(:request).with(:get, "lists", params)
      lists.list(**params)
    end

    it "works without parameters" do
      expect(lists).to receive(:request).with(:get, "lists", {})
      lists.list
    end
  end

  describe "#get" do
    let(:id) { "list123" }
    let(:response) { { "data" => { "id" => id, "name" => "VIP Customers" } } }

    before do
      allow(lists).to receive(:request).and_return(response)
    end

    it "makes a GET request to get a list" do
      expect(lists).to receive(:request).with(:get, "lists/#{id}")
      lists.get(id: id)
    end

    it "returns the response" do
      expect(lists.get(id: id)).to eq(response)
    end

    it "validates id parameter" do
      expect { lists.get(id: nil) }.to raise_error(ArgumentError, "List ID is required")
      expect { lists.get(id: "") }.to raise_error(ArgumentError, "List ID is required")
      expect { lists.get(id: "  ") }.to raise_error(ArgumentError, "List ID is required")
    end
  end

  describe "#entries" do
    let(:id) { "list123" }
    let(:params) { { limit: 20, offset: 0 } }
    let(:response) { { "data" => [{ "id" => "entry123" }] } }

    before do
      allow(lists).to receive(:request).and_return(response)
    end

    it "makes a GET request to list entries" do
      expect(lists).to receive(:request).with(:get, "lists/#{id}/entries", params)
      lists.entries(id: id, **params)
    end

    it "returns the response" do
      expect(lists.entries(id: id)).to eq(response)
    end

    it "validates id parameter" do
      expect { lists.entries(id: nil) }.to raise_error(ArgumentError, "List ID is required")
      expect { lists.entries(id: "") }.to raise_error(ArgumentError, "List ID is required")
      expect { lists.entries(id: "  ") }.to raise_error(ArgumentError, "List ID is required")
    end

    it "accepts optional parameters" do
      expect(lists).to receive(:request).with(:get, "lists/#{id}/entries", params)
      lists.entries(id: id, **params)
    end

    it "works without additional parameters" do
      expect(lists).to receive(:request).with(:get, "lists/#{id}/entries", {})
      lists.entries(id: id)
    end
  end

  describe "#create_entry" do
    let(:id) { "list123" }
    let(:data) { { record_id: "rec123", notes: "Important customer" } }
    let(:response) { { "data" => { "id" => "entry123" } } }

    before do
      allow(lists).to receive(:request).and_return(response)
    end

    it "makes a POST request to create an entry" do
      expect(lists).to receive(:request).with(:post, "lists/#{id}/entries", data)
      lists.create_entry(id: id, data: data)
    end

    it "returns the response" do
      expect(lists.create_entry(id: id, data: data)).to eq(response)
    end

    it "validates id parameter" do
      expect { lists.create_entry(id: nil, data: data) }.to raise_error(ArgumentError, "List ID is required")
      expect { lists.create_entry(id: "", data: data) }.to raise_error(ArgumentError, "List ID is required")
      expect { lists.create_entry(id: "  ", data: data) }.to raise_error(ArgumentError, "List ID is required")
    end

    it "validates data parameter" do
      expect { lists.create_entry(id: id, data: nil) }.to raise_error(ArgumentError, "Data is required")
      expect { lists.create_entry(id: id, data: "not a hash") }.to raise_error(ArgumentError, "Data must be a hash")
      expect { lists.create_entry(id: id, data: []) }.to raise_error(ArgumentError, "Data must be a hash")
    end
  end

  describe "#get_entry" do
    let(:list_id) { "list123" }
    let(:entry_id) { "entry123" }
    let(:response) { { "data" => { "id" => entry_id, "record_id" => "rec123" } } }

    before do
      allow(lists).to receive(:request).and_return(response)
    end

    it "makes a GET request to get an entry" do
      expect(lists).to receive(:request).with(:get, "lists/#{list_id}/entries/#{entry_id}")
      lists.get_entry(list_id: list_id, entry_id: entry_id)
    end

    it "returns the response" do
      expect(lists.get_entry(list_id: list_id, entry_id: entry_id)).to eq(response)
    end

    it "validates list_id parameter" do
      expect { lists.get_entry(list_id: nil, entry_id: entry_id) }.to raise_error(ArgumentError, "List ID is required")
      expect { lists.get_entry(list_id: "", entry_id: entry_id) }.to raise_error(ArgumentError, "List ID is required")
      expect { lists.get_entry(list_id: "  ", entry_id: entry_id) }.to raise_error(ArgumentError, "List ID is required")
    end

    it "validates entry_id parameter" do
      expect { lists.get_entry(list_id: list_id, entry_id: nil) }.to raise_error(ArgumentError, "Entry ID is required")
      expect { lists.get_entry(list_id: list_id, entry_id: "") }.to raise_error(ArgumentError, "Entry ID is required")
      expect { lists.get_entry(list_id: list_id, entry_id: "  ") }.to raise_error(ArgumentError, "Entry ID is required")
    end
  end

  describe "#delete_entry" do
    let(:list_id) { "list123" }
    let(:entry_id) { "entry123" }
    let(:response) { { "success" => true } }

    before do
      allow(lists).to receive(:request).and_return(response)
    end

    it "makes a DELETE request to delete an entry" do
      expect(lists).to receive(:request).with(:delete, "lists/#{list_id}/entries/#{entry_id}")
      lists.delete_entry(list_id: list_id, entry_id: entry_id)
    end

    it "returns the response" do
      expect(lists.delete_entry(list_id: list_id, entry_id: entry_id)).to eq(response)
    end

    it "validates list_id parameter" do
      expect do
        lists.delete_entry(list_id: nil, entry_id: entry_id)
      end.to raise_error(ArgumentError, "List ID is required")
      expect do
        lists.delete_entry(list_id: "", entry_id: entry_id)
      end.to raise_error(ArgumentError, "List ID is required")
      expect do
        lists.delete_entry(list_id: "  ", entry_id: entry_id)
      end.to raise_error(ArgumentError, "List ID is required")
    end

    it "validates entry_id parameter" do
      expect do
        lists.delete_entry(list_id: list_id, entry_id: nil)
      end.to raise_error(ArgumentError, "Entry ID is required")
      expect do
        lists.delete_entry(list_id: list_id, entry_id: "")
      end.to raise_error(ArgumentError, "Entry ID is required")
      expect do
        lists.delete_entry(list_id: list_id, entry_id: "  ")
      end.to raise_error(ArgumentError, "Entry ID is required")
    end
  end

  describe "#create" do
    let(:data) { { name: "VIP Customers", parent_object: "people", is_public: true } }
    let(:response) { { "data" => { "id" => "list123", "name" => "VIP Customers" } } }

    before do
      allow(lists).to receive(:request).and_return(response)
    end

    it "makes a POST request to create a list" do
      expect(lists).to receive(:request).with(:post, "lists", { data: data })
      lists.create(data: data)
    end

    it "returns the response" do
      expect(lists.create(data: data)).to eq(response)
    end

    it "validates data parameter" do
      expect { lists.create(data: nil) }.to raise_error(ArgumentError, "Data is required")
      expect { lists.create(data: "not a hash") }.to raise_error(ArgumentError, "Data must be a hash")
      expect { lists.create(data: []) }.to raise_error(ArgumentError, "Data must be a hash")
    end

    it "accepts minimal data" do
      minimal_data = { name: "Simple List" }
      expect(lists).to receive(:request).with(:post, "lists", { data: minimal_data })
      lists.create(data: minimal_data)
    end

    it "accepts complex data with all options" do
      complex_data = {
        name: "Premium Customers",
        parent_object: "companies",
        is_public: false,
        description: "High-value customer accounts"
      }
      expect(lists).to receive(:request).with(:post, "lists", { data: complex_data })
      lists.create(data: complex_data)
    end
  end

  describe "#update" do
    let(:id_or_slug) { "list123" }
    let(:data) { { name: "Updated List Name", is_public: false } }
    let(:response) { { "data" => { "id" => id_or_slug, "name" => "Updated List Name" } } }

    before do
      allow(lists).to receive(:request).and_return(response)
    end

    it "makes a PATCH request to update a list" do
      expect(lists).to receive(:request).with(:patch, "lists/#{id_or_slug}", { data: data })
      lists.update(id_or_slug: id_or_slug, data: data)
    end

    it "returns the response" do
      expect(lists.update(id_or_slug: id_or_slug, data: data)).to eq(response)
    end

    it "validates id_or_slug parameter" do
      expect { lists.update(id_or_slug: nil, data: data) }.to raise_error(ArgumentError, "List ID is required")
      expect { lists.update(id_or_slug: "", data: data) }.to raise_error(ArgumentError, "List ID is required")
      expect { lists.update(id_or_slug: "  ", data: data) }.to raise_error(ArgumentError, "List ID is required")
    end

    it "validates data parameter" do
      expect { lists.update(id_or_slug: id_or_slug, data: nil) }.to raise_error(ArgumentError, "Data is required")
      expect { lists.update(id_or_slug: id_or_slug, data: "not a hash") }.to raise_error(ArgumentError, "Data must be a hash")
      expect { lists.update(id_or_slug: id_or_slug, data: []) }.to raise_error(ArgumentError, "Data must be a hash")
    end

    it "works with list slug instead of ID" do
      slug = "vip-customers"
      expect(lists).to receive(:request).with(:patch, "lists/#{slug}", { data: data })
      lists.update(id_or_slug: slug, data: data)
    end

    it "accepts partial data updates" do
      partial_data = { description: "New description only" }
      expect(lists).to receive(:request).with(:patch, "lists/#{id_or_slug}", { data: partial_data })
      lists.update(id_or_slug: id_or_slug, data: partial_data)
    end
  end

  describe "#query_entries" do
    let(:id_or_slug) { "list123" }
    let(:response) { { "data" => [{ "id" => "entry123", "record_id" => "rec456" }] } }

    before do
      allow(lists).to receive(:request).and_return(response)
    end

    it "makes a POST request to query list entries" do
      expect(lists).to receive(:request).with(:post, "lists/#{id_or_slug}/entries/query", {})
      lists.query_entries(id_or_slug: id_or_slug)
    end

    it "returns the response" do
      expect(lists.query_entries(id_or_slug: id_or_slug)).to eq(response)
    end

    it "validates id_or_slug parameter" do
      expect { lists.query_entries(id_or_slug: nil) }.to raise_error(ArgumentError, "List ID is required")
      expect { lists.query_entries(id_or_slug: "") }.to raise_error(ArgumentError, "List ID is required")
      expect { lists.query_entries(id_or_slug: "  ") }.to raise_error(ArgumentError, "List ID is required")
    end

    it "accepts filter parameter as hash" do
      filter = { created_at: { gte: "2023-01-01" } }
      expect(lists).to receive(:request).with(:post, "lists/#{id_or_slug}/entries/query", { filter: filter.to_json })
      lists.query_entries(id_or_slug: id_or_slug, filter: filter)
    end

    it "accepts filter parameter as string" do
      filter_string = "{\"created_at\": {\"gte\": \"2023-01-01\"}}"
      expect(lists).to receive(:request).with(:post, "lists/#{id_or_slug}/entries/query", { filter: filter_string })
      lists.query_entries(id_or_slug: id_or_slug, filter: filter_string)
    end

    it "accepts sort parameter" do
      sort = { created_at: "desc" }
      expect(lists).to receive(:request).with(:post, "lists/#{id_or_slug}/entries/query", { sort: sort })
      lists.query_entries(id_or_slug: id_or_slug, sort: sort)
    end

    it "accepts limit parameter" do
      limit = 50
      expect(lists).to receive(:request).with(:post, "lists/#{id_or_slug}/entries/query", { limit: limit })
      lists.query_entries(id_or_slug: id_or_slug, limit: limit)
    end

    it "accepts offset parameter" do
      offset = 100
      expect(lists).to receive(:request).with(:post, "lists/#{id_or_slug}/entries/query", { offset: offset })
      lists.query_entries(id_or_slug: id_or_slug, offset: offset)
    end

    it "accepts all parameters together" do
      filter = { status: "active" }
      sort = { created_at: "desc" }
      limit = 25
      offset = 50
      
      expected_params = {
        filter: filter.to_json,
        sort: sort,
        limit: limit,
        offset: offset
      }
      
      expect(lists).to receive(:request).with(:post, "lists/#{id_or_slug}/entries/query", expected_params)
      lists.query_entries(id_or_slug: id_or_slug, filter: filter, sort: sort, limit: limit, offset: offset)
    end

    it "works with list slug instead of ID" do
      slug = "vip-customers"
      expect(lists).to receive(:request).with(:post, "lists/#{slug}/entries/query", {})
      lists.query_entries(id_or_slug: slug)
    end

    it "ignores nil parameters" do
      expect(lists).to receive(:request).with(:post, "lists/#{id_or_slug}/entries/query", { limit: 10 })
      lists.query_entries(id_or_slug: id_or_slug, filter: nil, sort: nil, limit: 10, offset: nil)
    end
  end

  describe "#assert_entry" do
    let(:id_or_slug) { "list123" }
    let(:matching_attribute) { "record_id" }
    let(:data) { { record_id: "rec123", values: { priority: "high" }, notes: "VIP customer" } }
    let(:response) { { "data" => { "id" => "entry123", "record_id" => "rec123" } } }

    before do
      allow(lists).to receive(:request).and_return(response)
    end

    it "makes a PUT request to assert an entry" do
      expected_body = { data: data, matching_attribute: matching_attribute }
      expect(lists).to receive(:request).with(:put, "lists/#{id_or_slug}/entries", expected_body)
      lists.assert_entry(id_or_slug: id_or_slug, matching_attribute: matching_attribute, data: data)
    end

    it "returns the response" do
      expect(lists.assert_entry(id_or_slug: id_or_slug, matching_attribute: matching_attribute, data: data)).to eq(response)
    end

    it "validates id_or_slug parameter" do
      expect { lists.assert_entry(id_or_slug: nil, matching_attribute: matching_attribute, data: data) }.to raise_error(ArgumentError, "List ID is required")
      expect { lists.assert_entry(id_or_slug: "", matching_attribute: matching_attribute, data: data) }.to raise_error(ArgumentError, "List ID is required")
      expect { lists.assert_entry(id_or_slug: "  ", matching_attribute: matching_attribute, data: data) }.to raise_error(ArgumentError, "List ID is required")
    end

    it "validates matching_attribute parameter" do
      expect { lists.assert_entry(id_or_slug: id_or_slug, matching_attribute: nil, data: data) }.to raise_error(ArgumentError, "Matching attribute is required")
      expect { lists.assert_entry(id_or_slug: id_or_slug, matching_attribute: "", data: data) }.to raise_error(ArgumentError, "Matching attribute is required")
      expect { lists.assert_entry(id_or_slug: id_or_slug, matching_attribute: "  ", data: data) }.to raise_error(ArgumentError, "Matching attribute is required")
    end

    it "validates data parameter" do
      expect { lists.assert_entry(id_or_slug: id_or_slug, matching_attribute: matching_attribute, data: nil) }.to raise_error(ArgumentError, "Data is required")
      expect { lists.assert_entry(id_or_slug: id_or_slug, matching_attribute: matching_attribute, data: "not a hash") }.to raise_error(ArgumentError, "Data must be a hash")
      expect { lists.assert_entry(id_or_slug: id_or_slug, matching_attribute: matching_attribute, data: []) }.to raise_error(ArgumentError, "Data must be a hash")
    end

    it "works with list slug instead of ID" do
      slug = "vip-customers"
      expected_body = { data: data, matching_attribute: matching_attribute }
      expect(lists).to receive(:request).with(:put, "lists/#{slug}/entries", expected_body)
      lists.assert_entry(id_or_slug: slug, matching_attribute: matching_attribute, data: data)
    end

    it "accepts minimal data" do
      minimal_data = { record_id: "rec123" }
      expected_body = { data: minimal_data, matching_attribute: matching_attribute }
      expect(lists).to receive(:request).with(:put, "lists/#{id_or_slug}/entries", expected_body)
      lists.assert_entry(id_or_slug: id_or_slug, matching_attribute: matching_attribute, data: minimal_data)
    end

    it "accepts complex data with all fields" do
      complex_data = {
        record_id: "rec123",
        values: { priority: "high", category: "premium", last_contacted: "2024-01-15" },
        notes: "VIP customer with special requirements"
      }
      expected_body = { data: complex_data, matching_attribute: matching_attribute }
      expect(lists).to receive(:request).with(:put, "lists/#{id_or_slug}/entries", expected_body)
      lists.assert_entry(id_or_slug: id_or_slug, matching_attribute: matching_attribute, data: complex_data)
    end

    it "works with custom matching attributes" do
      custom_matching_attribute = "email"
      custom_data = { email: "john@example.com", values: { status: "qualified" } }
      expected_body = { data: custom_data, matching_attribute: custom_matching_attribute }
      expect(lists).to receive(:request).with(:put, "lists/#{id_or_slug}/entries", expected_body)
      lists.assert_entry(id_or_slug: id_or_slug, matching_attribute: custom_matching_attribute, data: custom_data)
    end

    it "handles empty data hash" do
      empty_data = {}
      expected_body = { data: empty_data, matching_attribute: matching_attribute }
      expect(lists).to receive(:request).with(:put, "lists/#{id_or_slug}/entries", expected_body)
      lists.assert_entry(id_or_slug: id_or_slug, matching_attribute: matching_attribute, data: empty_data)
    end
  end

  describe "#update_entry" do
    let(:id_or_slug) { "list123" }
    let(:entry_id) { "entry456" }
    let(:data) { { values: { priority: "medium" }, notes: "Updated customer info" } }
    let(:response) { { "data" => { "id" => entry_id, "record_id" => "rec123" } } }

    before do
      allow(lists).to receive(:request).and_return(response)
    end

    it "makes a PATCH request to update an entry" do
      expected_body = { data: data }
      expect(lists).to receive(:request).with(:patch, "lists/#{id_or_slug}/entries/#{entry_id}", expected_body)
      lists.update_entry(id_or_slug: id_or_slug, entry_id: entry_id, data: data)
    end

    it "returns the response" do
      expect(lists.update_entry(id_or_slug: id_or_slug, entry_id: entry_id, data: data)).to eq(response)
    end

    it "validates id_or_slug parameter" do
      expect { lists.update_entry(id_or_slug: nil, entry_id: entry_id, data: data) }.to raise_error(ArgumentError, "List ID is required")
      expect { lists.update_entry(id_or_slug: "", entry_id: entry_id, data: data) }.to raise_error(ArgumentError, "List ID is required")
      expect { lists.update_entry(id_or_slug: "  ", entry_id: entry_id, data: data) }.to raise_error(ArgumentError, "List ID is required")
    end

    it "validates entry_id parameter" do
      expect { lists.update_entry(id_or_slug: id_or_slug, entry_id: nil, data: data) }.to raise_error(ArgumentError, "Entry ID is required")
      expect { lists.update_entry(id_or_slug: id_or_slug, entry_id: "", data: data) }.to raise_error(ArgumentError, "Entry ID is required")
      expect { lists.update_entry(id_or_slug: id_or_slug, entry_id: "  ", data: data) }.to raise_error(ArgumentError, "Entry ID is required")
    end

    it "validates data parameter" do
      expect { lists.update_entry(id_or_slug: id_or_slug, entry_id: entry_id, data: nil) }.to raise_error(ArgumentError, "Data is required")
      expect { lists.update_entry(id_or_slug: id_or_slug, entry_id: entry_id, data: "not a hash") }.to raise_error(ArgumentError, "Data must be a hash")
      expect { lists.update_entry(id_or_slug: id_or_slug, entry_id: entry_id, data: []) }.to raise_error(ArgumentError, "Data must be a hash")
    end

    it "works with list slug instead of ID" do
      slug = "vip-customers"
      expected_body = { data: data }
      expect(lists).to receive(:request).with(:patch, "lists/#{slug}/entries/#{entry_id}", expected_body)
      lists.update_entry(id_or_slug: slug, entry_id: entry_id, data: data)
    end

    it "accepts minimal data updates" do
      minimal_data = { notes: "Quick update" }
      expected_body = { data: minimal_data }
      expect(lists).to receive(:request).with(:patch, "lists/#{id_or_slug}/entries/#{entry_id}", expected_body)
      lists.update_entry(id_or_slug: id_or_slug, entry_id: entry_id, data: minimal_data)
    end

    it "accepts values-only updates" do
      values_data = { values: { priority: "low", status: "inactive" } }
      expected_body = { data: values_data }
      expect(lists).to receive(:request).with(:patch, "lists/#{id_or_slug}/entries/#{entry_id}", expected_body)
      lists.update_entry(id_or_slug: id_or_slug, entry_id: entry_id, data: values_data)
    end

    it "accepts complex data updates" do
      complex_data = {
        values: {
          priority: "high",
          category: "enterprise",
          last_contacted: "2024-01-15",
          deal_size: 100000
        },
        notes: "Promoted to enterprise tier with significant deal potential"
      }
      expected_body = { data: complex_data }
      expect(lists).to receive(:request).with(:patch, "lists/#{id_or_slug}/entries/#{entry_id}", expected_body)
      lists.update_entry(id_or_slug: id_or_slug, entry_id: entry_id, data: complex_data)
    end

    it "handles empty data hash" do
      empty_data = {}
      expected_body = { data: empty_data }
      expect(lists).to receive(:request).with(:patch, "lists/#{id_or_slug}/entries/#{entry_id}", expected_body)
      lists.update_entry(id_or_slug: id_or_slug, entry_id: entry_id, data: empty_data)
    end
  end
end
