# frozen_string_literal: true

RSpec.describe Attio::Client do
  let(:api_key) { "test_api_key" }
  let(:client) { described_class.new(api_key: api_key) }

  describe "#initialize" do
    it "requires an API key" do
      expect { described_class.new(api_key: nil) }.to raise_error(ArgumentError, "API key is required")
      expect { described_class.new(api_key: "") }.to raise_error(ArgumentError, "API key is required")
    end

    it "sets the API key" do
      expect(client.api_key).to eq(api_key)
    end

    it "uses the default timeout" do
      expect(client.timeout).to eq(Attio::Client::DEFAULT_TIMEOUT)
    end

    it "accepts a custom timeout" do
      custom_timeout = 60
      client = described_class.new(api_key: api_key, timeout: custom_timeout)
      expect(client.timeout).to eq(custom_timeout)
    end
  end

  describe "#connection" do
    it "creates an HttpClient instance" do
      expect(client.connection).to be_a(Attio::HttpClient)
    end

    it "sets the base URL" do
      expect(client.connection.base_url).to eq(Attio::Client::API_BASE_URL)
    end

    it "sets the authorization header" do
      expect(client.connection.headers["Authorization"]).to eq("Bearer #{api_key}")
    end

    it "sets the accept header" do
      expect(client.connection.headers["Accept"]).to eq("application/json")
    end

    it "sets the content-type header" do
      expect(client.connection.headers["Content-Type"]).to eq("application/json")
    end

    it "sets the user agent header" do
      expect(client.connection.headers["User-Agent"]).to eq("Attio Ruby Client/#{Attio::VERSION}")
    end

    it "memoizes the connection" do
      connection1 = client.connection
      connection2 = client.connection
      expect(connection1).to be(connection2)
    end
  end

  describe "resource accessors" do
    describe "#records" do
      it "returns a Records resource" do
        expect(client.records).to be_a(Attio::Resources::Records)
      end

      it "memoizes the resource" do
        records1 = client.records
        records2 = client.records
        expect(records1).to be(records2)
      end

      it "passes the client to the resource" do
        expect(client.records.client).to be(client)
      end
    end

    describe "#objects" do
      it "returns an Objects resource" do
        expect(client.objects).to be_a(Attio::Resources::Objects)
      end

      it "memoizes the resource" do
        objects1 = client.objects
        objects2 = client.objects
        expect(objects1).to be(objects2)
      end
    end

    describe "#lists" do
      it "returns a Lists resource" do
        expect(client.lists).to be_a(Attio::Resources::Lists)
      end

      it "memoizes the resource" do
        lists1 = client.lists
        lists2 = client.lists
        expect(lists1).to be(lists2)
      end
    end

    describe "#workspaces" do
      it "returns a Workspaces resource" do
        expect(client.workspaces).to be_a(Attio::Resources::Workspaces)
      end

      it "memoizes the resource" do
        workspaces1 = client.workspaces
        workspaces2 = client.workspaces
        expect(workspaces1).to be(workspaces2)
      end
    end

    describe "#attributes" do
      it "returns an Attributes resource" do
        expect(client.attributes).to be_a(Attio::Resources::Attributes)
      end

      it "memoizes the resource" do
        attributes1 = client.attributes
        attributes2 = client.attributes
        expect(attributes1).to be(attributes2)
      end
    end

    describe "#users" do
      it "returns a Users resource" do
        expect(client.users).to be_a(Attio::Resources::Users)
      end

      it "memoizes the resource" do
        users1 = client.users
        users2 = client.users
        expect(users1).to be(users2)
      end
    end
  end
end
