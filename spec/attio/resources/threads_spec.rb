# frozen_string_literal: true

require "spec_helper"

RSpec.describe Attio::Resources::Threads do
  let(:client) { instance_double(Attio::Client) }
  let(:connection) { instance_double(Attio::HttpClient) }
  let(:threads) { described_class.new(client) }

  before do
    allow(client).to receive(:connection).and_return(connection)
  end

  describe "#list" do
    it "makes a GET request to list threads" do
      expect(connection).to receive(:get).with(
        "threads",
        {
          parent_object: "companies",
          parent_record_id: "company_123"
        }
      ).and_return({ "data" => [] })

      threads.list(parent_object: "companies", parent_record_id: "company_123")
    end

    it "includes additional parameters" do
      expect(connection).to receive(:get).with(
        "threads",
        {
          parent_object: "companies",
          parent_record_id: "company_123",
          limit: 10,
          cursor: "next_page",
          status: "open"
        }
      ).and_return({ "data" => [] })

      threads.list(
        parent_object: "companies",
        parent_record_id: "company_123",
        limit: 10,
        cursor: "next_page",
        status: "open"
      )
    end

    it "validates parent_object" do
      expect do
        threads.list(parent_object: nil, parent_record_id: "record_123")
      end.to raise_error(ArgumentError, "Parent object is required")

      expect do
        threads.list(parent_object: "", parent_record_id: "record_123")
      end.to raise_error(ArgumentError, "Parent object is required")
    end

    it "validates parent_record_id" do
      expect do
        threads.list(parent_object: "companies", parent_record_id: nil)
      end.to raise_error(ArgumentError, "Parent record ID is required")

      expect do
        threads.list(parent_object: "companies", parent_record_id: "")
      end.to raise_error(ArgumentError, "Parent record ID is required")
    end

    it "returns the response" do
      allow(connection).to receive(:get).and_return({ "data" => [] })
      response = threads.list(parent_object: "companies", parent_record_id: "company_123")
      expect(response).to eq({ "data" => [] })
    end
  end

  describe "#get" do
    it "makes a GET request to get a thread" do
      expect(connection).to receive(:get).with("threads/thread_123").and_return({})
      threads.get(id: "thread_123")
    end

    it "includes comments when requested" do
      expect(connection).to receive(:get).with(
        "threads/thread_123",
        { include: "comments" }
      ).and_return({})

      threads.get(id: "thread_123", include_comments: true)
    end

    it "validates id parameter" do
      expect { threads.get(id: nil) }.to raise_error(ArgumentError, "Thread ID is required")
      expect { threads.get(id: "") }.to raise_error(ArgumentError, "Thread ID is required")
    end

    it "returns the response" do
      allow(connection).to receive(:get).and_return({ "data" => { "id" => "thread_123" } })
      response = threads.get(id: "thread_123")
      expect(response).to eq({ "data" => { "id" => "thread_123" } })
    end
  end

  describe "#create" do
    it "makes a POST request to create a thread" do
      expect(connection).to receive(:post).with(
        "threads",
        {
          parent_object: "companies",
          parent_record_id: "company_123",
          title: "Discussion Thread"
        }
      ).and_return({})

      threads.create(
        parent_object: "companies",
        parent_record_id: "company_123",
        title: "Discussion Thread"
      )
    end

    it "includes additional data" do
      expect(connection).to receive(:post).with(
        "threads",
        {
          parent_object: "companies",
          parent_record_id: "company_123",
          title: "Discussion Thread",
          description: "Thread description",
          status: "open",
          participant_ids: ["user_1", "user_2"]
        }
      ).and_return({})

      threads.create(
        parent_object: "companies",
        parent_record_id: "company_123",
        title: "Discussion Thread",
        description: "Thread description",
        status: "open",
        participant_ids: ["user_1", "user_2"]
      )
    end

    it "validates parent_object" do
      expect do
        threads.create(parent_object: nil, parent_record_id: "record_123", title: "Title")
      end.to raise_error(ArgumentError, "Parent object is required")
    end

    it "validates parent_record_id" do
      expect do
        threads.create(parent_object: "companies", parent_record_id: nil, title: "Title")
      end.to raise_error(ArgumentError, "Parent record ID is required")
    end

    it "validates title" do
      expect do
        threads.create(parent_object: "companies", parent_record_id: "company_123", title: nil)
      end.to raise_error(ArgumentError, "Thread title is required")

      expect do
        threads.create(parent_object: "companies", parent_record_id: "company_123", title: "")
      end.to raise_error(ArgumentError, "Thread title is required")
    end
  end

  describe "#update" do
    it "makes a PATCH request to update a thread" do
      expect(connection).to receive(:patch).with(
        "threads/thread_123",
        { title: "Updated Title" }
      ).and_return({})

      threads.update(id: "thread_123", title: "Updated Title")
    end

    it "validates id parameter" do
      expect do
        threads.update(id: nil, title: "Title")
      end.to raise_error(ArgumentError, "Thread ID is required")
    end

    it "validates update data is not empty" do
      expect do
        threads.update(id: "thread_123")
      end.to raise_error(ArgumentError, "Update data is required")
    end

    it "returns the response" do
      allow(connection).to receive(:patch).and_return({ "data" => { "id" => "thread_123" } })
      response = threads.update(id: "thread_123", title: "Updated")
      expect(response).to eq({ "data" => { "id" => "thread_123" } })
    end
  end

  describe "#close" do
    it "makes a PATCH request to close a thread" do
      expect(connection).to receive(:patch).with(
        "threads/thread_123",
        { status: "closed" }
      ).and_return({})

      threads.close(id: "thread_123")
    end

    it "validates id parameter" do
      expect do
        threads.close(id: nil)
      end.to raise_error(ArgumentError, "Thread ID is required")
    end

    it "returns the response" do
      allow(connection).to receive(:patch).and_return({ "data" => { "status" => "closed" } })
      response = threads.close(id: "thread_123")
      expect(response).to eq({ "data" => { "status" => "closed" } })
    end
  end

  describe "#reopen" do
    it "makes a PATCH request to reopen a thread" do
      expect(connection).to receive(:patch).with(
        "threads/thread_123",
        { status: "open" }
      ).and_return({})

      threads.reopen(id: "thread_123")
    end

    it "validates id parameter" do
      expect do
        threads.reopen(id: nil)
      end.to raise_error(ArgumentError, "Thread ID is required")
    end

    it "returns the response" do
      allow(connection).to receive(:patch).and_return({ "data" => { "status" => "open" } })
      response = threads.reopen(id: "thread_123")
      expect(response).to eq({ "data" => { "status" => "open" } })
    end
  end

  describe "#delete" do
    it "makes a DELETE request to delete a thread" do
      expect(connection).to receive(:delete).with("threads/thread_123").and_return({})
      threads.delete(id: "thread_123")
    end

    it "validates id parameter" do
      expect { threads.delete(id: nil) }.to raise_error(ArgumentError, "Thread ID is required")
      expect { threads.delete(id: "") }.to raise_error(ArgumentError, "Thread ID is required")
    end

    it "returns the response" do
      allow(connection).to receive(:delete).and_return({ "success" => true })
      response = threads.delete(id: "thread_123")
      expect(response).to eq({ "success" => true })
    end
  end

  describe "#add_participants" do
    it "makes a POST request to add participants" do
      expect(connection).to receive(:post).with(
        "threads/thread_123/participants",
        { user_ids: ["user_1", "user_2"] }
      ).and_return({})

      threads.add_participants(id: "thread_123", user_ids: ["user_1", "user_2"])
    end

    it "validates id parameter" do
      expect do
        threads.add_participants(id: nil, user_ids: ["user_1"])
      end.to raise_error(ArgumentError, "Thread ID is required")
    end

    it "validates user_ids parameter" do
      expect do
        threads.add_participants(id: "thread_123", user_ids: nil)
      end.to raise_error(ArgumentError, "User IDs are required")

      expect do
        threads.add_participants(id: "thread_123", user_ids: [])
      end.to raise_error(ArgumentError, "User IDs are required")

      expect do
        threads.add_participants(id: "thread_123", user_ids: "user_1")
      end.to raise_error(ArgumentError, "User IDs must be an array")
    end

    it "returns the response" do
      allow(connection).to receive(:post).and_return({ "data" => { "participants" => ["user_1", "user_2"] } })
      response = threads.add_participants(id: "thread_123", user_ids: ["user_1", "user_2"])
      expect(response).to eq({ "data" => { "participants" => ["user_1", "user_2"] } })
    end
  end

  describe "#remove_participants" do
    it "makes a DELETE request to remove participants" do
      expect(connection).to receive(:delete).with(
        "threads/thread_123/participants",
        { user_ids: ["user_1"] }
      ).and_return({})

      threads.remove_participants(id: "thread_123", user_ids: ["user_1"])
    end

    it "validates id parameter" do
      expect do
        threads.remove_participants(id: nil, user_ids: ["user_1"])
      end.to raise_error(ArgumentError, "Thread ID is required")
    end

    it "validates user_ids parameter" do
      expect do
        threads.remove_participants(id: "thread_123", user_ids: nil)
      end.to raise_error(ArgumentError, "User IDs are required")

      expect do
        threads.remove_participants(id: "thread_123", user_ids: [])
      end.to raise_error(ArgumentError, "User IDs are required")

      expect do
        threads.remove_participants(id: "thread_123", user_ids: "user_1")
      end.to raise_error(ArgumentError, "User IDs must be an array")
    end

    it "returns the response" do
      allow(connection).to receive(:delete).and_return({ "data" => { "participants" => [] } })
      response = threads.remove_participants(id: "thread_123", user_ids: ["user_1"])
      expect(response).to eq({ "data" => { "participants" => [] } })
    end
  end
end