# frozen_string_literal: true

module Attio
  module Resources
    # API resource for managing tasks in Attio
    #
    # Tasks help track action items and to-dos associated with records.
    #
    # @example Creating a task
    #   client.tasks.create(
    #     parent_object: "people",
    #     parent_record_id: "person_123",
    #     title: "Follow up on proposal",
    #     due_date: "2025-02-01",
    #     assignee_id: "user_456"
    #   )
    #
    # @example Listing tasks with filters
    #   client.tasks.list(
    #     status: "pending",
    #     assignee_id: "user_456"
    #   )
    class Tasks < Base
      # List tasks with optional filters
      #
      # @param params [Hash] Query parameters
      # @option params [String] :parent_object Filter by parent object type
      # @option params [String] :parent_record_id Filter by parent record
      # @option params [String] :status Filter by status (pending, completed)
      # @option params [String] :assignee_id Filter by assignee
      # @option params [Integer] :limit Number of tasks to return
      # @option params [String] :cursor Pagination cursor
      #
      # @return [Hash] API response containing tasks
      def list(**params)
        request(:get, "tasks", params)
      end

      # Get a specific task by ID
      #
      # @param id [String] The task ID
      #
      # @return [Hash] The task data
      # @raise [ArgumentError] if id is nil or empty
      def get(id:)
        validate_id!(id, "Task")
        request(:get, "tasks/#{id}")
      end

      # Create a new task
      #
      # @param parent_object [String] The parent object type
      # @param parent_record_id [String] The ID of the parent record
      # @param title [String] The task title
      # @param data [Hash] Additional task data
      # @option data [String] :description Task description
      # @option data [String] :due_date Due date (ISO 8601 format)
      # @option data [String] :assignee_id User ID to assign the task to
      # @option data [String] :status Task status (pending, completed)
      # @option data [Integer] :priority Task priority (1-5)
      #
      # @return [Hash] The created task
      # @raise [ArgumentError] if required parameters are missing
      def create(parent_object:, parent_record_id:, title:, **data)
        validate_parent!(parent_object, parent_record_id)
        validate_required_string!(title, "Task title")

        request(:post, "tasks", data.merge(
                                  parent_object: parent_object,
                                  parent_record_id: parent_record_id,
                                  title: title
                                ))
      end

      # Update an existing task
      #
      # @param id [String] The task ID
      # @param data [Hash] The fields to update
      # @option data [String] :title New title
      # @option data [String] :description New description
      # @option data [String] :due_date New due date
      # @option data [String] :assignee_id New assignee
      # @option data [String] :status New status
      # @option data [Integer] :priority New priority
      #
      # @return [Hash] The updated task
      # @raise [ArgumentError] if id is invalid
      def update(id:, **data)
        validate_id!(id, "Task")
        validate_data!(data, "Update")
        request(:patch, "tasks/#{id}", data)
      end

      # Mark a task as completed
      #
      # @param id [String] The task ID
      # @param completed_at [String] Optional completion timestamp (defaults to now)
      #
      # @return [Hash] The updated task
      # @raise [ArgumentError] if id is nil or empty
      def complete(id:, completed_at: nil)
        validate_id!(id, "Task")
        data = { status: "completed" }
        data[:completed_at] = completed_at if completed_at
        request(:patch, "tasks/#{id}", data)
      end

      # Reopen a completed task
      #
      # @param id [String] The task ID
      #
      # @return [Hash] The updated task
      # @raise [ArgumentError] if id is nil or empty
      def reopen(id:)
        validate_id!(id, "Task")
        request(:patch, "tasks/#{id}", { status: "pending", completed_at: nil })
      end

      # Delete a task
      #
      # @param id [String] The task ID to delete
      #
      # @return [Hash] Deletion confirmation
      # @raise [ArgumentError] if id is nil or empty
      def delete(id:)
        validate_id!(id, "Task")
        request(:delete, "tasks/#{id}")
      end
    end
  end
end
