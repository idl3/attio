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
      response = instance_double(Net::HTTPResponse)
      allow(response).to receive(:[]).with("retry-after").and_return("not-a-number")
      
      # Access private method through send
      retry_after = http_client.send(:extract_retry_after, response)
      expect(retry_after).to eq(60)
    end
  end

  describe "EnhancedClient background thread error" do
    it "triggers background stats thread error handling" do
      # Create mock instrumentation with logger
      instrumentation = instance_double(Attio::Observability::Manager)
      logger = instance_double(Logger)
      allow(instrumentation).to receive(:logger).and_return(logger)
      allow(logger).to receive(:fatal)
      allow(instrumentation).to receive(:record_gauge)
      
      client = Attio::EnhancedClient.new(
        api_key: "test-key",
        instrumentation: instrumentation
      )
      
      # Start the background thread if it exists
      if client.instance_variable_get(:@background_thread)
        # Mock the pool to raise an error on stats call
        pool = client.instance_variable_get(:@pool)
        allow(pool).to receive(:stats).and_raise(StandardError, "Test error")
        
        # Let the background thread run and handle the error
        sleep(0.05)
        
        # Check that the error was logged
        expect(logger).to have_received(:fatal).at_least(:once)
      end
      
      # Clean up
      client.close
    end
  end
end