# frozen_string_literal: true

RSpec.describe Attio::Resources::Tasks do
  let(:client) { instance_double(Attio::Client) }
  let(:tasks) { described_class.new(client) }

  describe "#list" do
    let(:params) { { status: "pending", assignee_id: "user_456", limit: 10 } }
    let(:response) { { "data" => [{ "id" => "task_123", "title" => "Follow up" }] } }

    before do
      allow(tasks).to receive(:request).and_return(response)
    end

    it "makes a GET request to list tasks" do
      expect(tasks).to receive(:request).with(:get, "tasks", params)
      tasks.list(**params)
    end

    it "returns the response" do
      expect(tasks.list(**params)).to eq(response)
    end

    it "works without parameters" do
      expect(tasks).to receive(:request).with(:get, "tasks", {})
      tasks.list
    end
  end

  describe "#get" do
    let(:id) { "task_123" }
    let(:response) { { "data" => { "id" => id, "title" => "Follow up" } } }

    before do
      allow(tasks).to receive(:request).and_return(response)
    end

    it "makes a GET request to get a task" do
      expect(tasks).to receive(:request).with(:get, "tasks/#{id}")
      tasks.get(id: id)
    end

    it "returns the response" do
      expect(tasks.get(id: id)).to eq(response)
    end

    it "validates id parameter" do
      expect { tasks.get(id: nil) }.to raise_error(ArgumentError, "Task ID is required")
      expect { tasks.get(id: "") }.to raise_error(ArgumentError, "Task ID is required")
    end
  end

  describe "#create" do
    let(:parent_object) { "people" }
    let(:parent_record_id) { "person_123" }
    let(:title) { "Follow up on proposal" }
    let(:additional_data) { { due_date: "2025-02-01", assignee_id: "user_456" } }
    let(:response) { { "data" => { "id" => "task_123" } } }

    before do
      allow(tasks).to receive(:request).and_return(response)
    end

    it "makes a POST request to create a task" do
      expect(tasks).to receive(:request).with(
        :post,
        "tasks",
        hash_including(
          parent_object: parent_object,
          parent_record_id: parent_record_id,
          title: title
        )
      )
      tasks.create(
        parent_object: parent_object,
        parent_record_id: parent_record_id,
        title: title
      )
    end

    it "includes additional data" do
      expect(tasks).to receive(:request).with(
        :post,
        "tasks",
        hash_including(additional_data)
      )
      tasks.create(
        parent_object: parent_object,
        parent_record_id: parent_record_id,
        title: title,
        **additional_data
      )
    end

    it "validates parent_object" do
      expect do
        tasks.create(parent_object: nil, parent_record_id: parent_record_id, title: title)
      end.to raise_error(ArgumentError, "Parent object is required")
    end

    it "validates parent_record_id" do
      expect do
        tasks.create(parent_object: parent_object, parent_record_id: nil, title: title)
      end.to raise_error(ArgumentError, "Parent record ID is required")
    end

    it "validates title" do
      expect do
        tasks.create(parent_object: parent_object, parent_record_id: parent_record_id, title: nil)
      end.to raise_error(ArgumentError, "Task title is required")
    end
  end

  describe "#update" do
    let(:id) { "task_123" }
    let(:update_data) { { title: "Updated task", status: "completed" } }
    let(:response) { { "data" => { "id" => id } } }

    before do
      allow(tasks).to receive(:request).and_return(response)
    end

    it "makes a PATCH request to update a task" do
      expect(tasks).to receive(:request).with(:patch, "tasks/#{id}", update_data)
      tasks.update(id: id, **update_data)
    end

    it "returns the response" do
      expect(tasks.update(id: id, **update_data)).to eq(response)
    end

    it "validates id parameter" do
      expect { tasks.update(id: nil, **update_data) }.to raise_error(ArgumentError, "Task ID is required")
    end

    it "validates update data is not empty" do
      expect { tasks.update(id: id) }.to raise_error(ArgumentError, "Update data is required")
    end
  end

  describe "#complete" do
    let(:id) { "task_123" }
    let(:response) { { "data" => { "id" => id, "status" => "completed" } } }

    before do
      allow(tasks).to receive(:request).and_return(response)
    end

    it "makes a PATCH request to complete a task" do
      expect(tasks).to receive(:request).with(:patch, "tasks/#{id}", { status: "completed" })
      tasks.complete(id: id)
    end

    it "includes completed_at if provided" do
      completed_at = "2025-01-15T10:00:00Z"
      expect(tasks).to receive(:request).with(
        :patch,
        "tasks/#{id}",
        { status: "completed", completed_at: completed_at }
      )
      tasks.complete(id: id, completed_at: completed_at)
    end

    it "validates id parameter" do
      expect { tasks.complete(id: nil) }.to raise_error(ArgumentError, "Task ID is required")
    end
  end

  describe "#reopen" do
    let(:id) { "task_123" }
    let(:response) { { "data" => { "id" => id, "status" => "pending" } } }

    before do
      allow(tasks).to receive(:request).and_return(response)
    end

    it "makes a PATCH request to reopen a task" do
      expect(tasks).to receive(:request).with(
        :patch,
        "tasks/#{id}",
        { status: "pending", completed_at: nil }
      )
      tasks.reopen(id: id)
    end

    it "validates id parameter" do
      expect { tasks.reopen(id: nil) }.to raise_error(ArgumentError, "Task ID is required")
    end
  end

  describe "#delete" do
    let(:id) { "task_123" }
    let(:response) { { "success" => true } }

    before do
      allow(tasks).to receive(:request).and_return(response)
    end

    it "makes a DELETE request to delete a task" do
      expect(tasks).to receive(:request).with(:delete, "tasks/#{id}")
      tasks.delete(id: id)
    end

    it "returns the response" do
      expect(tasks.delete(id: id)).to eq(response)
    end

    it "validates id parameter" do
      expect { tasks.delete(id: nil) }.to raise_error(ArgumentError, "Task ID is required")
    end
  end
end