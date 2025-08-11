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
      expect { lists.delete_entry(list_id: nil, entry_id: entry_id) }.to raise_error(ArgumentError, "List ID is required")
      expect { lists.delete_entry(list_id: "", entry_id: entry_id) }.to raise_error(ArgumentError, "List ID is required")
      expect { lists.delete_entry(list_id: "  ", entry_id: entry_id) }.to raise_error(ArgumentError, "List ID is required")
    end

    it "validates entry_id parameter" do
      expect { lists.delete_entry(list_id: list_id, entry_id: nil) }.to raise_error(ArgumentError, "Entry ID is required")
      expect { lists.delete_entry(list_id: list_id, entry_id: "") }.to raise_error(ArgumentError, "Entry ID is required")
      expect { lists.delete_entry(list_id: list_id, entry_id: "  ") }.to raise_error(ArgumentError, "Entry ID is required")
    end
  end
end