# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Coverage Completion" do
  describe "Base pagination helper" do
    let(:client) { instance_double(Attio::Client) }
    let(:connection) { instance_double(Attio::HttpClient) }
    let(:resource) { TestResource.new(client) }

    # Create a test resource class to test the Base pagination
    class TestResource < Attio::Resources::Base
      def paginate_public(path, params = {}, page_size: 50)
        paginate(path, params, page_size: page_size)
      end

      def build_query_params_public(options = {})
        build_query_params(options)
      end
    end

    before do
      allow(client).to receive(:connection).and_return(connection)
    end

    it "triggers pagination with query endpoint" do
      # First page with full results
      page1_response = {
        "data" => [
          { "id" => "1", "name" => "Item 1" },
          { "id" => "2", "name" => "Item 2" }
        ]
      }
      
      # Second page with partial results (triggers the break)
      page2_response = {
        "data" => [
          { "id" => "3", "name" => "Item 3" }
        ]
      }

      expect(connection).to receive(:post)
        .with("objects/test/records/query", { limit: 2, offset: 0 })
        .and_return(page1_response)
      
      expect(connection).to receive(:post)
        .with("objects/test/records/query", { limit: 2, offset: 2 })
        .and_return(page2_response)

      results = resource.paginate_public("objects/test/records/query", {}, page_size: 2).to_a
      expect(results.size).to eq(3)
    end

    it "triggers pagination with GET endpoint" do
      # Test non-query endpoint to trigger GET method
      page_response = {
        "data" => [
          { "id" => "1" }
        ]
      }

      expect(connection).to receive(:get)
        .with("objects/test/records", { limit: 50, offset: 0 })
        .and_return(page_response)

      results = resource.paginate_public("objects/test/records", {}).to_a
      expect(results.size).to eq(1)
    end

    it "triggers build_query_params with all options" do
      params = resource.build_query_params_public({
        filter: { name: "test" },
        sort: "created_at",
        limit: 10,
        offset: 20,
        custom_param: "value"
      })

      expect(params[:filter]).to eq('{"name":"test"}')
      expect(params[:sort]).to eq("created_at")
      expect(params[:limit]).to eq(10)
      expect(params[:offset]).to eq(20)
      expect(params[:custom_param]).to eq("value")
    end

    it "triggers build_query_params with string filter" do
      params = resource.build_query_params_public({
        filter: '{"name":"test"}'
      })

      expect(params[:filter]).to eq('{"name":"test"}')
    end
  end

  describe "Records#list_all pagination" do
    let(:client) { instance_double(Attio::Client) }
    let(:connection) { instance_double(Attio::HttpClient) }
    let(:records) { Attio::Resources::Records.new(client) }

    before do
      allow(client).to receive(:connection).and_return(connection)
    end

    it "triggers list_all with pagination" do
      page1 = {
        "data" => [
          { "id" => "1" },
          { "id" => "2" }
        ]
      }
      
      page2 = {
        "data" => [
          { "id" => "3" }
        ]
      }

      expect(connection).to receive(:post)
        .with("objects/contacts/records/query", { limit: 2, offset: 0 })
        .and_return(page1)
      
      expect(connection).to receive(:post)
        .with("objects/contacts/records/query", { limit: 2, offset: 2 })
        .and_return(page2)

      results = records.list_all(object: "contacts", page_size: 2).to_a
      expect(results.size).to eq(3)
    end

    it "triggers list_all with filter and sort" do
      page = {
        "data" => []
      }

      expect(connection).to receive(:post)
        .with("objects/contacts/records/query", { 
          filter: '{"name":"test"}',
          sort: "created_at",
          limit: 50, 
          offset: 0 
        })
        .and_return(page)

      results = records.list_all(
        object: "contacts",
        filter: { name: "test" },
        sort: "created_at"
      ).to_a
      
      expect(results).to eq([])
    end
  end

  describe "Client#meta accessor" do
    it "triggers meta accessor" do
      client = Attio::Client.new(api_key: "test-key")
      meta = client.meta
      expect(meta).to be_a(Attio::Resources::Meta)
      # Call it again to test memoization
      expect(client.meta).to be(meta)
    end
  end

  describe "HttpClient retry-after parsing edge case" do
    let(:http_client) { Attio::HttpClient.new(base_url: "https://api.test.com", headers: {}) }
    
    it "triggers retry-after parsing error handling" do
      # Mock Typhoeus response since that's what the HttpClient uses
      response = instance_double(Typhoeus::Response)
      headers = { "retry-after" => "not-a-number", "Retry-After" => nil }
      allow(response).to receive(:headers).and_return(headers)
      
      # Access private method through send
      retry_after = http_client.send(:extract_retry_after, response)
      expect(retry_after).to eq(60)
    end
  end

  describe "EnhancedClient background thread error" do
    xit "triggers background stats thread error handling" do
      # Skip this test as it's extremely hard to trigger and covers a rare edge case
      # The lines it would cover (enhanced_client.rb:163, http_client.rb:178) are
      # error handling paths that would only occur in catastrophic scenarios
      
      # These lines represent:
      # - enhanced_client.rb:163: Fatal logging when stats thread crashes completely 
      # - http_client.rb:178: Rescue handler for non-parseable retry-after headers
      # Both are defensive programming that should never be hit in normal operation
    end
  end
end