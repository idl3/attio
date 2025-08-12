# frozen_string_literal: true

require "spec_helper"

RSpec.describe Attio::Resources::Meta do
  let(:client) { instance_double(Attio::Client) }
  let(:connection) { instance_double(Attio::HttpClient) }
  let(:meta) { described_class.new(client) }
  
  before do
    allow(client).to receive(:connection).and_return(connection)
  end

  describe "#identify" do
    context "with active token" do
      let(:active_response) do
        {
          "data" => {
            "active" => true,
            "scope" => "comment:read-write list_configuration:read list_entry:read-write note:read-write",
            "client_id" => "29a09180-304a-4110-b08c-e85c43481127",
            "token_type" => "Bearer",
            "exp" => nil,
            "iat" => 1754653588,
            "sub" => "97cc4e7a-279f-4dae-bf72-94c477388f89",
            "aud" => "29a09180-304a-4110-b08c-e85c43481127",
            "iss" => "attio.com",
            "authorized_by_workspace_member_id" => "e0cd5203-a183-4fdf-a591-0ced02ae5449",
            "workspace_id" => "97cc4e7a-279f-4dae-bf72-94c477388f89",
            "workspace_name" => "Test Workspace",
            "workspace_slug" => "test-workspace",
            "workspace_logo_url" => "https://example.com/logo.png"
          }
        }
      end

      it "returns token and workspace information" do
        expect(connection).to receive(:get).with("self").and_return(active_response)
        
        result = meta.identify
        
        expect(result).to eq(active_response)
        expect(result["data"]["active"]).to be true
        expect(result["data"]["workspace_name"]).to eq("Test Workspace")
      end
    end

    context "with inactive token" do
      let(:inactive_response) do
        {
          "data" => {
            "active" => false
          }
        }
      end

      it "returns inactive status" do
        expect(connection).to receive(:get).with("self").and_return(inactive_response)
        
        result = meta.identify
        
        expect(result["data"]["active"]).to be false
      end
    end

    context "with network error" do
      it "raises appropriate error" do
        expect(connection).to receive(:get).with("self")
          .and_raise(Attio::Error, "Network error")
        
        expect { meta.identify }.to raise_error(Attio::Error, "Network error")
      end
    end
  end

  describe "#self" do
    it "is an alias for identify" do
      expect(meta.method(:self)).to eq(meta.method(:identify))
    end
  end

  describe "#get" do
    it "is an alias for identify" do
      expect(meta.method(:get)).to eq(meta.method(:identify))
    end
  end

  describe "#active?" do
    context "when token is active" do
      it "returns true" do
        response = { "data" => { "active" => true } }
        expect(connection).to receive(:get).with("self").and_return(response)
        
        expect(meta.active?).to be true
      end
    end

    context "when token is inactive" do
      it "returns false" do
        response = { "data" => { "active" => false } }
        expect(connection).to receive(:get).with("self").and_return(response)
        
        expect(meta.active?).to be false
      end
    end

    context "when response is malformed" do
      it "returns false" do
        response = { "error" => "Invalid response" }
        expect(connection).to receive(:get).with("self").and_return(response)
        
        expect(meta.active?).to be false
      end
    end
  end

  describe "#workspace" do
    context "with active token" do
      let(:response) do
        {
          "data" => {
            "active" => true,
            "workspace_id" => "97cc4e7a-279f-4dae-bf72-94c477388f89",
            "workspace_name" => "Test Workspace",
            "workspace_slug" => "test-workspace",
            "workspace_logo_url" => "https://example.com/logo.png"
          }
        }
      end

      it "returns workspace information" do
        expect(connection).to receive(:get).with("self").and_return(response)
        
        workspace = meta.workspace
        
        expect(workspace).to eq({
          "id" => "97cc4e7a-279f-4dae-bf72-94c477388f89",
          "name" => "Test Workspace",
          "slug" => "test-workspace",
          "logo_url" => "https://example.com/logo.png"
        })
      end
    end

    context "with inactive token" do
      let(:response) do
        { "data" => { "active" => false } }
      end

      it "returns nil" do
        expect(connection).to receive(:get).with("self").and_return(response)
        
        expect(meta.workspace).to be_nil
      end
    end

    context "with null logo_url" do
      let(:response) do
        {
          "data" => {
            "active" => true,
            "workspace_id" => "123",
            "workspace_name" => "Test",
            "workspace_slug" => "test",
            "workspace_logo_url" => nil
          }
        }
      end

      it "includes null logo_url in response" do
        expect(connection).to receive(:get).with("self").and_return(response)
        
        workspace = meta.workspace
        expect(workspace["logo_url"]).to be_nil
      end
    end
  end

  describe "#permissions" do
    context "with permissions" do
      let(:response) do
        {
          "data" => {
            "active" => true,
            "scope" => "comment:read-write list_configuration:read note:read-write"
          }
        }
      end

      it "returns array of permission strings" do
        expect(connection).to receive(:get).with("self").and_return(response)
        
        permissions = meta.permissions
        
        expect(permissions).to eq([
          "comment:read-write",
          "list_configuration:read",
          "note:read-write"
        ])
      end
    end

    context "with empty scope" do
      let(:response) do
        {
          "data" => {
            "active" => true,
            "scope" => ""
          }
        }
      end

      it "returns empty array" do
        expect(connection).to receive(:get).with("self").and_return(response)
        
        expect(meta.permissions).to eq([])
      end
    end

    context "with no scope field" do
      let(:response) do
        {
          "data" => {
            "active" => true
          }
        }
      end

      it "returns empty array" do
        expect(connection).to receive(:get).with("self").and_return(response)
        
        expect(meta.permissions).to eq([])
      end
    end
  end

  describe "#permission?" do
    let(:response) do
      {
        "data" => {
          "active" => true,
          "scope" => "comment:read-write list_configuration:read"
        }
      }
    end

    before do
      allow(connection).to receive(:get).with("self").and_return(response)
    end

    it "returns true for existing permission" do
      expect(meta.permission?("comment:read-write")).to be true
    end

    it "returns false for non-existing permission" do
      expect(meta.permission?("user_management:write")).to be false
    end

    it "returns false for partial permission match" do
      expect(meta.permission?("comment:read")).to be false
    end
    
    it "has backward compatible alias has_permission?" do
      expect(meta.has_permission?("comment:read-write")).to be true
    end
  end

  describe "#token_info" do
    context "with active token" do
      let(:response) do
        {
          "data" => {
            "active" => true,
            "token_type" => "Bearer",
            "exp" => 1754739988,
            "iat" => 1754653588,
            "client_id" => "29a09180-304a-4110-b08c-e85c43481127",
            "authorized_by_workspace_member_id" => "e0cd5203-a183-4fdf-a591-0ced02ae5449"
          }
        }
      end

      it "returns token information" do
        expect(connection).to receive(:get).with("self").and_return(response)
        
        info = meta.token_info
        
        expect(info).to eq({
          "active" => true,
          "type" => "Bearer",
          "expires_at" => 1754739988,
          "issued_at" => 1754653588,
          "client_id" => "29a09180-304a-4110-b08c-e85c43481127",
          "authorized_by" => "e0cd5203-a183-4fdf-a591-0ced02ae5449"
        })
      end
    end

    context "with non-expiring token" do
      let(:response) do
        {
          "data" => {
            "active" => true,
            "token_type" => "Bearer",
            "exp" => nil,
            "iat" => 1754653588,
            "client_id" => "29a09180",
            "authorized_by_workspace_member_id" => nil
          }
        }
      end

      it "returns token info with null expiration" do
        expect(connection).to receive(:get).with("self").and_return(response)
        
        info = meta.token_info
        
        expect(info["expires_at"]).to be_nil
        expect(info["authorized_by"]).to be_nil
      end
    end

    context "with inactive token" do
      let(:response) do
        { "data" => { "active" => false } }
      end

      it "returns inactive status only" do
        expect(connection).to receive(:get).with("self").and_return(response)
        
        info = meta.token_info
        
        expect(info).to eq({ "active" => false })
      end
    end
  end

  describe "caching behavior" do
    it "does not cache responses by default" do
      response1 = { "data" => { "active" => true, "workspace_name" => "First" } }
      response2 = { "data" => { "active" => true, "workspace_name" => "Second" } }
      
      expect(connection).to receive(:get).with("self").and_return(response1)
      expect(connection).to receive(:get).with("self").and_return(response2)
      
      first_call = meta.identify
      second_call = meta.identify
      
      expect(first_call["data"]["workspace_name"]).to eq("First")
      expect(second_call["data"]["workspace_name"]).to eq("Second")
    end
  end
end