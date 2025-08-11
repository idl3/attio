# frozen_string_literal: true

require "spec_helper"

RSpec.describe Attio::Resources::Comments do
  let(:client) { instance_double(Attio::Client) }
  let(:connection) { instance_double(Attio::HttpClient) }
  let(:comments) { described_class.new(client) }

  before do
    allow(client).to receive(:connection).and_return(connection)
  end

  describe "#list" do
    context "with parent parameters" do
      it "makes a GET request to list comments" do
        expect(connection).to receive(:get).with(
          "comments",
          { parent_object: "people", parent_record_id: "person_123" }
        ).and_return({ "data" => [] })

        comments.list(parent_object: "people", parent_record_id: "person_123")
      end

      it "includes additional parameters" do
        expect(connection).to receive(:get).with(
          "comments",
          {
            parent_object: "people",
            parent_record_id: "person_123",
            limit: 10,
            cursor: "next_page"
          }
        ).and_return({ "data" => [] })

        comments.list(
          parent_object: "people",
          parent_record_id: "person_123",
          limit: 10,
          cursor: "next_page"
        )
      end
    end

    context "with thread_id" do
      it "makes a GET request with thread_id" do
        expect(connection).to receive(:get).with(
          "comments",
          { thread_id: "thread_456" }
        ).and_return({ "data" => [] })

        comments.list(thread_id: "thread_456")
      end
    end

    context "with invalid parameters" do
      it "raises error when neither parent nor thread provided" do
        expect do
          comments.list
        end.to raise_error(ArgumentError, "Must provide either parent_object/parent_record_id or thread_id")
      end
    end

    it "returns the response" do
      allow(connection).to receive(:get).and_return({ "data" => [] })
      response = comments.list(thread_id: "thread_123")
      expect(response).to eq({ "data" => [] })
    end
  end

  describe "#get" do
    it "makes a GET request to get a comment" do
      expect(connection).to receive(:get).with("comments/comment_123").and_return({})
      comments.get(id: "comment_123")
    end

    it "validates id parameter" do
      expect { comments.get(id: nil) }.to raise_error(ArgumentError, "Comment ID is required")
      expect { comments.get(id: "") }.to raise_error(ArgumentError, "Comment ID is required")
    end

    it "returns the response" do
      allow(connection).to receive(:get).and_return({ "data" => { "id" => "comment_123" } })
      response = comments.get(id: "comment_123")
      expect(response).to eq({ "data" => { "id" => "comment_123" } })
    end
  end

  describe "#create" do
    context "with parent parameters" do
      it "makes a POST request to create a comment" do
        expect(connection).to receive(:post).with(
          "comments",
          {
            content: "Test comment",
            parent_object: "people",
            parent_record_id: "person_123"
          }
        ).and_return({})

        comments.create(
          content: "Test comment",
          parent_object: "people",
          parent_record_id: "person_123"
        )
      end

      it "includes additional data" do
        expect(connection).to receive(:post).with(
          "comments",
          {
            content: "Test comment",
            parent_object: "people",
            parent_record_id: "person_123",
            internal: true
          }
        ).and_return({})

        comments.create(
          content: "Test comment",
          parent_object: "people",
          parent_record_id: "person_123",
          internal: true
        )
      end
    end

    context "with thread_id" do
      it "makes a POST request with thread_id" do
        expect(connection).to receive(:post).with(
          "comments",
          {
            content: "Thread comment",
            thread_id: "thread_456"
          }
        ).and_return({})

        comments.create(
          content: "Thread comment",
          thread_id: "thread_456"
        )
      end
    end

    context "with invalid parameters" do
      it "validates content" do
        expect do
          comments.create(content: nil, thread_id: "thread_123")
        end.to raise_error(ArgumentError, "Comment content is required")

        expect do
          comments.create(content: "", thread_id: "thread_123")
        end.to raise_error(ArgumentError, "Comment content is required")
      end

      it "raises error when neither parent nor thread provided" do
        expect do
          comments.create(content: "Test")
        end.to raise_error(ArgumentError, "Must provide either parent_object/parent_record_id or thread_id")
      end

      it "raises error when both parent and thread provided" do
        expect do
          comments.create(
            content: "Test",
            parent_object: "people",
            parent_record_id: "person_123",
            thread_id: "thread_456"
          )
        end.to raise_error(ArgumentError, "Cannot provide both parent and thread parameters")
      end
    end
  end

  describe "#update" do
    it "makes a PATCH request to update a comment" do
      expect(connection).to receive(:patch).with(
        "comments/comment_123",
        { content: "Updated comment" }
      ).and_return({})

      comments.update(id: "comment_123", content: "Updated comment")
    end

    it "validates id parameter" do
      expect do
        comments.update(id: nil, content: "Test")
      end.to raise_error(ArgumentError, "Comment ID is required")
    end

    it "validates content parameter" do
      expect do
        comments.update(id: "comment_123", content: nil)
      end.to raise_error(ArgumentError, "Comment content is required")

      expect do
        comments.update(id: "comment_123", content: "")
      end.to raise_error(ArgumentError, "Comment content is required")
    end

    it "returns the response" do
      allow(connection).to receive(:patch).and_return({ "data" => { "id" => "comment_123" } })
      response = comments.update(id: "comment_123", content: "Updated")
      expect(response).to eq({ "data" => { "id" => "comment_123" } })
    end
  end

  describe "#delete" do
    it "makes a DELETE request to delete a comment" do
      expect(connection).to receive(:delete).with("comments/comment_123").and_return({})
      comments.delete(id: "comment_123")
    end

    it "validates id parameter" do
      expect { comments.delete(id: nil) }.to raise_error(ArgumentError, "Comment ID is required")
      expect { comments.delete(id: "") }.to raise_error(ArgumentError, "Comment ID is required")
    end

    it "returns the response" do
      allow(connection).to receive(:delete).and_return({ "success" => true })
      response = comments.delete(id: "comment_123")
      expect(response).to eq({ "success" => true })
    end
  end

  describe "#react" do
    it "makes a POST request to add a reaction" do
      expect(connection).to receive(:post).with(
        "comments/comment_123/reactions",
        { emoji: "👍" }
      ).and_return({})

      comments.react(id: "comment_123", emoji: "👍")
    end

    it "validates id parameter" do
      expect do
        comments.react(id: nil, emoji: "👍")
      end.to raise_error(ArgumentError, "Comment ID is required")
    end

    it "validates emoji parameter" do
      expect do
        comments.react(id: "comment_123", emoji: nil)
      end.to raise_error(ArgumentError, "Emoji is required")

      expect do
        comments.react(id: "comment_123", emoji: "")
      end.to raise_error(ArgumentError, "Emoji is required")
    end

    it "returns the response" do
      allow(connection).to receive(:post).and_return({ "data" => { "reactions" => ["👍"] } })
      response = comments.react(id: "comment_123", emoji: "👍")
      expect(response).to eq({ "data" => { "reactions" => ["👍"] } })
    end
  end

  describe "#unreact" do
    it "makes a DELETE request to remove a reaction" do
      expect(connection).to receive(:delete).with("comments/comment_123/reactions/%F0%9F%91%8D").and_return({})
      comments.unreact(id: "comment_123", emoji: "👍")
    end

    it "validates id parameter" do
      expect do
        comments.unreact(id: nil, emoji: "👍")
      end.to raise_error(ArgumentError, "Comment ID is required")
    end

    it "validates emoji parameter" do
      expect do
        comments.unreact(id: "comment_123", emoji: nil)
      end.to raise_error(ArgumentError, "Emoji is required")

      expect do
        comments.unreact(id: "comment_123", emoji: "")
      end.to raise_error(ArgumentError, "Emoji is required")
    end

    it "returns the response" do
      allow(connection).to receive(:delete).and_return({ "data" => { "reactions" => [] } })
      response = comments.unreact(id: "comment_123", emoji: "👍")
      expect(response).to eq({ "data" => { "reactions" => [] } })
    end
  end
end