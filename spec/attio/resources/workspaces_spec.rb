# frozen_string_literal: true

RSpec.describe Attio::Resources::Workspaces do
  let(:client) { instance_double(Attio::Client) }
  let(:workspaces) { described_class.new(client) }

  describe "#get" do
    let(:response) { { "data" => { "id" => "workspace123", "name" => "My Workspace" } } }

    before do
      allow(workspaces).to receive(:request).and_return(response)
    end

    it "makes a GET request to get workspace information" do
      expect(workspaces).to receive(:request).with(:get, "self")
      workspaces.get
    end

    it "returns the response" do
      expect(workspaces.get).to eq(response)
    end

    it "does not require any parameters" do
      expect { workspaces.get }.not_to raise_error
    end
  end

  describe "#members" do
    let(:params) { { limit: 10, offset: 0 } }
    let(:response) { { "data" => [{ "id" => "member123", "email" => "user@example.com" }] } }

    before do
      allow(workspaces).to receive(:request).and_return(response)
    end

    it "makes a GET request to list workspace members" do
      expect(workspaces).to receive(:request).with(:get, "workspace_members", params)
      workspaces.members(**params)
    end

    it "returns the response" do
      expect(workspaces.members).to eq(response)
    end

    it "accepts optional parameters" do
      expect(workspaces).to receive(:request).with(:get, "workspace_members", params)
      workspaces.members(**params)
    end

    it "works without parameters" do
      expect(workspaces).to receive(:request).with(:get, "workspace_members", {})
      workspaces.members
    end

    it "handles pagination parameters" do
      pagination_params = { limit: 50, offset: 100 }
      expect(workspaces).to receive(:request).with(:get, "workspace_members", pagination_params)
      workspaces.members(**pagination_params)
    end
  end
end
