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

    describe "#notes" do
      it "returns a Notes resource" do
        expect(client.notes).to be_a(Attio::Resources::Notes)
      end

      it "memoizes the resource" do
        notes1 = client.notes
        notes2 = client.notes
        expect(notes1).to be(notes2)
      end
    end

    describe "#tasks" do
      it "returns a Tasks resource" do
        expect(client.tasks).to be_a(Attio::Resources::Tasks)
      end

      it "memoizes the resource" do
        tasks1 = client.tasks
        tasks2 = client.tasks
        expect(tasks1).to be(tasks2)
      end
    end

    describe "#comments" do
      it "returns a Comments resource" do
        expect(client.comments).to be_a(Attio::Resources::Comments)
      end

      it "memoizes the resource" do
        comments1 = client.comments
        comments2 = client.comments
        expect(comments1).to be(comments2)
      end
    end

    describe "#threads" do
      it "returns a Threads resource" do
        expect(client.threads).to be_a(Attio::Resources::Threads)
      end

      it "memoizes the resource" do
        threads1 = client.threads
        threads2 = client.threads
        expect(threads1).to be(threads2)
      end
    end

    describe "#workspace_members" do
      it "returns a WorkspaceMembers resource" do
        expect(client.workspace_members).to be_a(Attio::Resources::WorkspaceMembers)
      end

      it "memoizes the resource" do
        workspace_members1 = client.workspace_members
        workspace_members2 = client.workspace_members
        expect(workspace_members1).to be(workspace_members2)
      end
    end

    describe "#deals" do
      it "returns a Deals resource" do
        expect(client.deals).to be_a(Attio::Resources::Deals)
      end

      it "memoizes the resource" do
        deals1 = client.deals
        deals2 = client.deals
        expect(deals1).to be(deals2)
      end
    end

    describe "#meta" do
      it "returns a Meta resource" do
        expect(client.meta).to be_a(Attio::Resources::Meta)
      end

      it "memoizes the resource" do
        meta1 = client.meta
        meta2 = client.meta
        expect(meta1).to be(meta2)
      end
    end

    describe "#bulk" do
      it "returns a Bulk resource" do
        expect(client.bulk).to be_a(Attio::Resources::Bulk)
      end

      it "memoizes the resource" do
        bulk1 = client.bulk
        bulk2 = client.bulk
        expect(bulk1).to be(bulk2)
      end
    end
  end

  describe "#rate_limiter" do
    it "returns a default RateLimiter if not set" do
      expect(client.rate_limiter).to be_a(Attio::RateLimiter)
    end

    it "allows setting a custom rate limiter" do
      custom_limiter = Attio::RateLimiter.new(max_requests: 50)
      client.rate_limiter(custom_limiter)
      expect(client.rate_limiter).to be(custom_limiter)
    end

    it "memoizes the default rate limiter" do
      limiter1 = client.rate_limiter
      limiter2 = client.rate_limiter
      expect(limiter1).to be(limiter2)
    end
  end
end
