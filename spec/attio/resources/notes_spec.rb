# frozen_string_literal: true

RSpec.describe Attio::Resources::Notes do
  let(:client) { instance_double(Attio::Client) }
  let(:notes) { described_class.new(client) }

  describe "#list" do
    let(:parent_object) { "people" }
    let(:parent_record_id) { "person_123" }
    let(:params) { { limit: 10, cursor: "next_page" } }
    let(:response) { { "data" => [{ "id" => "note_123", "title" => "Meeting notes" }] } }

    before do
      allow(notes).to receive(:request).and_return(response)
    end

    it "makes a GET request to list notes" do
      expect(notes).to receive(:request).with(
        :get,
        "notes",
        hash_including(parent_object: parent_object, parent_record_id: parent_record_id)
      )
      notes.list(parent_object: parent_object, parent_record_id: parent_record_id)
    end

    it "returns the response" do
      result = notes.list(parent_object: parent_object, parent_record_id: parent_record_id)
      expect(result).to eq(response)
    end

    it "includes additional parameters" do
      expect(notes).to receive(:request).with(
        :get,
        "notes",
        hash_including(params.merge(parent_object: parent_object, parent_record_id: parent_record_id))
      )
      notes.list(parent_object: parent_object, parent_record_id: parent_record_id, **params)
    end

    it "validates parent_object" do
      expect do
        notes.list(parent_object: nil, parent_record_id: parent_record_id)
      end.to raise_error(ArgumentError, "Parent object is required")
    end

    it "validates parent_record_id" do
      expect do
        notes.list(parent_object: parent_object, parent_record_id: nil)
      end.to raise_error(ArgumentError, "Parent record ID is required")
    end
  end

  describe "#get" do
    let(:id) { "note_123" }
    let(:response) { { "data" => { "id" => id, "title" => "Meeting notes" } } }

    before do
      allow(notes).to receive(:request).and_return(response)
    end

    it "makes a GET request to get a note" do
      expect(notes).to receive(:request).with(:get, "notes/#{id}")
      notes.get(id: id)
    end

    it "returns the response" do
      expect(notes.get(id: id)).to eq(response)
    end

    it "validates id parameter" do
      expect { notes.get(id: nil) }.to raise_error(ArgumentError, "Note ID is required")
      expect { notes.get(id: "") }.to raise_error(ArgumentError, "Note ID is required")
    end
  end

  describe "#create" do
    let(:parent_object) { "people" }
    let(:parent_record_id) { "person_123" }
    let(:title) { "Meeting Notes" }
    let(:content) { "Discussed Q4 goals and roadmap" }
    let(:additional_data) { { tags: ["important"] } }
    let(:response) { { "data" => { "id" => "note_123" } } }

    before do
      allow(notes).to receive(:request).and_return(response)
    end

    it "makes a POST request to create a note" do
      expect(notes).to receive(:request).with(
        :post,
        "notes",
        hash_including(
          parent_object: parent_object,
          parent_record_id: parent_record_id,
          title: title,
          content: content
        )
      )
      notes.create(
        parent_object: parent_object,
        parent_record_id: parent_record_id,
        title: title,
        content: content
      )
    end

    it "includes additional data" do
      expect(notes).to receive(:request).with(
        :post,
        "notes",
        hash_including(additional_data)
      )
      notes.create(
        parent_object: parent_object,
        parent_record_id: parent_record_id,
        title: title,
        content: content,
        **additional_data
      )
    end

    it "validates parent_object" do
      expect do
        notes.create(parent_object: nil, parent_record_id: parent_record_id, title: title, content: content)
      end.to raise_error(ArgumentError, "Parent object is required")
    end

    it "validates parent_record_id" do
      expect do
        notes.create(parent_object: parent_object, parent_record_id: nil, title: title, content: content)
      end.to raise_error(ArgumentError, "Parent record ID is required")
    end

    it "validates title" do
      expect do
        notes.create(parent_object: parent_object, parent_record_id: parent_record_id, title: nil, content: content)
      end.to raise_error(ArgumentError, "Note title is required")
    end

    it "validates content" do
      expect do
        notes.create(parent_object: parent_object, parent_record_id: parent_record_id, title: title, content: nil)
      end.to raise_error(ArgumentError, "Note content is required")
    end
  end

  describe "#update" do
    let(:id) { "note_123" }
    let(:update_data) { { title: "Updated Title", content: "Updated content" } }
    let(:response) { { "data" => { "id" => id } } }

    before do
      allow(notes).to receive(:request).and_return(response)
    end

    it "makes a PATCH request to update a note" do
      expect(notes).to receive(:request).with(:patch, "notes/#{id}", update_data)
      notes.update(id: id, **update_data)
    end

    it "returns the response" do
      expect(notes.update(id: id, **update_data)).to eq(response)
    end

    it "validates id parameter" do
      expect { notes.update(id: nil, **update_data) }.to raise_error(ArgumentError, "Note ID is required")
    end

    it "validates update data is not empty" do
      expect { notes.update(id: id) }.to raise_error(ArgumentError, "Update data is required")
    end

    it "validates update data contains title or content" do
      expect { notes.update(id: id, foo: "bar") }.to raise_error(ArgumentError, "Must provide title or content to update")
    end
  end

  describe "#delete" do
    let(:id) { "note_123" }
    let(:response) { { "success" => true } }

    before do
      allow(notes).to receive(:request).and_return(response)
    end

    it "makes a DELETE request to delete a note" do
      expect(notes).to receive(:request).with(:delete, "notes/#{id}")
      notes.delete(id: id)
    end

    it "returns the response" do
      expect(notes.delete(id: id)).to eq(response)
    end

    it "validates id parameter" do
      expect { notes.delete(id: nil) }.to raise_error(ArgumentError, "Note ID is required")
      expect { notes.delete(id: "") }.to raise_error(ArgumentError, "Note ID is required")
    end
  end
end