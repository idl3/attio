# frozen_string_literal: true

RSpec.describe Attio::Resources::Users do
  let(:client) { instance_double(Attio::Client) }
  let(:users) { described_class.new(client) }

  describe "#list" do
    let(:params) { { limit: 10, offset: 0 } }
    let(:response) { { "data" => [{ "id" => "user123", "email" => "john@example.com", "name" => "John Doe" }] } }

    before do
      allow(users).to receive(:request).and_return(response)
    end

    it "makes a GET request to list users" do
      expect(users).to receive(:request).with(:get, "users", params)
      users.list(**params)
    end

    it "returns the response" do
      expect(users.list).to eq(response)
    end

    it "accepts optional parameters" do
      expect(users).to receive(:request).with(:get, "users", params)
      users.list(**params)
    end

    it "works without parameters" do
      expect(users).to receive(:request).with(:get, "users", {})
      users.list
    end

    it "handles pagination parameters" do
      pagination_params = { limit: 50, offset: 100 }
      expect(users).to receive(:request).with(:get, "users", pagination_params)
      users.list(**pagination_params)
    end

    it "handles filtering parameters" do
      filter_params = { filter: { email: "john@example.com" } }
      expect(users).to receive(:request).with(:get, "users", filter_params)
      users.list(**filter_params)
    end
  end

  describe "#get" do
    let(:id) { "user123" }
    let(:response) { { "data" => { "id" => id, "email" => "john@example.com", "name" => "John Doe" } } }

    before do
      allow(users).to receive(:request).and_return(response)
    end

    it "makes a GET request to get a user" do
      expect(users).to receive(:request).with(:get, "users/#{id}")
      users.get(id: id)
    end

    it "returns the response" do
      expect(users.get(id: id)).to eq(response)
    end

    it "validates id parameter" do
      expect { users.get(id: nil) }.to raise_error(ArgumentError, "User ID is required")
      expect { users.get(id: "") }.to raise_error(ArgumentError, "User ID is required")
      expect { users.get(id: "  ") }.to raise_error(ArgumentError, "User ID is required")
    end

    it "handles different user ID formats" do
      uuid_id = "550e8400-e29b-41d4-a716-446655440000"
      expect(users).to receive(:request).with(:get, "users/#{uuid_id}")
      users.get(id: uuid_id)
    end
  end
end
