# frozen_string_literal: true

RSpec.describe Attio::Resources::Meta do
  let(:connection) { instance_double(Attio::HttpClient) }
  let(:client) { instance_double(Attio::Client, connection: connection) }
  let(:meta) { described_class.new(client) }

  describe "#identify" do
    it "identifies the current API key" do
      expected_response = {
        "workspace" => {
          "id" => "workspace_123",
          "name" => "Acme Corp",
          "domain" => "acme"
        },
        "user" => {
          "id" => "user_456",
          "email" => "api@acme.com",
          "name" => "API User"
        },
        "permissions" => ["read", "write"]
      }

      expect(connection).to receive(:get)
        .with("meta/identify")
        .and_return(expected_response)

      result = meta.identify
      expect(result).to eq(expected_response)
    end
  end

  describe "#status" do
    it "gets API status information" do
      expected_response = {
        "status" => "operational",
        "version" => "v2",
        "environment" => "production",
        "timestamp" => "2024-01-15T10:00:00Z"
      }

      expect(connection).to receive(:get)
        .with("meta/status")
        .and_return(expected_response)

      result = meta.status
      expect(result).to eq(expected_response)
    end
  end

  describe "#rate_limits" do
    it "gets rate limit information" do
      expected_response = {
        "limit" => 1000,
        "remaining" => 950,
        "reset_at" => "2024-01-15T11:00:00Z",
        "window" => "1h"
      }

      expect(connection).to receive(:get)
        .with("meta/rate_limits")
        .and_return(expected_response)

      result = meta.rate_limits
      expect(result).to eq(expected_response)
    end
  end

  describe "#workspace_config" do
    it "gets workspace configuration" do
      expected_response = {
        "workspace_id" => "workspace_123",
        "settings" => {
          "timezone" => "America/New_York",
          "currency" => "USD",
          "date_format" => "MM/DD/YYYY"
        },
        "limits" => {
          "max_records" => 100_000,
          "max_users" => 50
        }
      }

      expect(connection).to receive(:get)
        .with("meta/workspace_config")
        .and_return(expected_response)

      result = meta.workspace_config
      expect(result).to eq(expected_response)
    end
  end

  describe "#validate_key" do
    it "validates the current API key" do
      expected_response = {
        "valid" => true,
        "permissions" => ["read", "write", "delete"],
        "workspace_id" => "workspace_123",
        "key_type" => "full_access"
      }

      expect(connection).to receive(:post)
        .with("meta/validate")
        .and_return(expected_response)

      result = meta.validate_key
      expect(result).to eq(expected_response)
    end
  end

  describe "#endpoints" do
    it "gets available API endpoints" do
      expected_response = {
        "endpoints" => [
          {
            "path" => "/v2/objects",
            "methods" => ["GET", "POST"],
            "description" => "Manage custom objects"
          },
          {
            "path" => "/v2/records",
            "methods" => ["GET", "POST", "PATCH", "DELETE"],
            "description" => "CRUD operations on records"
          }
        ],
        "total" => 25
      }

      expect(connection).to receive(:get)
        .with("meta/endpoints")
        .and_return(expected_response)

      result = meta.endpoints
      expect(result).to eq(expected_response)
    end
  end

  describe "#usage_stats" do
    it "gets workspace usage statistics" do
      expected_response = {
        "records" => {
          "total" => 15_234,
          "by_object" => {
            "companies" => 5_123,
            "people" => 10_111
          }
        },
        "api_calls" => {
          "today" => 523,
          "this_month" => 12_456,
          "limit" => 100_000
        },
        "storage" => {
          "used_mb" => 234,
          "limit_mb" => 10_240
        }
      }

      expect(connection).to receive(:get)
        .with("meta/usage")
        .and_return(expected_response)

      result = meta.usage_stats
      expect(result).to eq(expected_response)
    end
  end

  describe "#features" do
    it "gets enabled features and capabilities" do
      expected_response = {
        "features" => {
          "webhooks" => true,
          "bulk_operations" => true,
          "custom_objects" => true,
          "advanced_filtering" => true,
          "api_v2" => true
        },
        "limits" => {
          "max_webhook_endpoints" => 10,
          "max_bulk_operations" => 100,
          "max_custom_objects" => 50
        }
      }

      expect(connection).to receive(:get)
        .with("meta/features")
        .and_return(expected_response)

      result = meta.features
      expect(result).to eq(expected_response)
    end
  end
end