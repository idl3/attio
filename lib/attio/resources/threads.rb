# frozen_string_literal: true

module Attio
  module Resources
    # API resource for managing threads in Attio
    #
    # Threads represent conversations or discussion topics related to records.
    #
    # @example Listing threads for a record
    #   client.threads.list(
    #     parent_object: "companies",
    #     parent_record_id: "company_123"
    #   )
    #
    # @example Getting a specific thread
    #   client.threads.get(id: "thread_456")
    class Threads < Base
      # List threads for a parent record
      #
      # @param parent_object [String] The parent object type
      # @param parent_record_id [String] The parent record ID
      # @param params [Hash] Additional query parameters
      # @option params [Integer] :limit Number of threads to return
      # @option params [String] :cursor Pagination cursor
      # @option params [String] :status Filter by status (open, closed)
      #
      # @return [Hash] API response containing threads
      # @raise [ArgumentError] if parent_object or parent_record_id is missing
      def list(parent_object:, parent_record_id:, **params)
        validate_parent!(parent_object, parent_record_id)
        request(:get, "threads", params.merge(
                                   parent_object: parent_object,
                                   parent_record_id: parent_record_id
                                 ))
      end

      # Get a specific thread by ID
      #
      # @param id [String] The thread ID
      # @param include_comments [Boolean] Whether to include comments in the response
      #
      # @return [Hash] The thread data
      # @raise [ArgumentError] if id is nil or empty
      def get(id:, include_comments: false)
        validate_id!(id, "Thread")
        params = include_comments ? { include: "comments" } : {}
        request(:get, "threads/#{id}", params)
      end

      # Create a new thread
      #
      # @param parent_object [String] The parent object type
      # @param parent_record_id [String] The parent record ID
      # @param title [String] The thread title
      # @param data [Hash] Additional thread data
      # @option data [String] :description Thread description
      # @option data [String] :status Thread status (open, closed)
      # @option data [Array<String>] :participant_ids User IDs of participants
      #
      # @return [Hash] The created thread
      # @raise [ArgumentError] if required parameters are missing
      def create(parent_object:, parent_record_id:, title:, **data)
        validate_parent!(parent_object, parent_record_id)
        validate_required_string!(title, "Thread title")

        request(:post, "threads", data.merge(
                                    parent_object: parent_object,
                                    parent_record_id: parent_record_id,
                                    title: title
                                  ))
      end

      # Update an existing thread
      #
      # @param id [String] The thread ID
      # @param data [Hash] The fields to update
      # @option data [String] :title New title
      # @option data [String] :description New description
      # @option data [String] :status New status (open, closed)
      #
      # @return [Hash] The updated thread
      # @raise [ArgumentError] if id is invalid
      def update(id:, **data)
        validate_id!(id, "Thread")
        validate_data!(data, "Update")
        request(:patch, "threads/#{id}", data)
      end

      # Close a thread
      #
      # @param id [String] The thread ID
      #
      # @return [Hash] The updated thread
      # @raise [ArgumentError] if id is nil or empty
      def close(id:)
        validate_id!(id, "Thread")
        request(:patch, "threads/#{id}", { status: "closed" })
      end

      # Reopen a closed thread
      #
      # @param id [String] The thread ID
      #
      # @return [Hash] The updated thread
      # @raise [ArgumentError] if id is nil or empty
      def reopen(id:)
        validate_id!(id, "Thread")
        request(:patch, "threads/#{id}", { status: "open" })
      end

      # Delete a thread
      #
      # @param id [String] The thread ID to delete
      #
      # @return [Hash] Deletion confirmation
      # @raise [ArgumentError] if id is nil or empty
      def delete(id:)
        validate_id!(id, "Thread")
        request(:delete, "threads/#{id}")
      end

      # Add participants to a thread
      #
      # @param id [String] The thread ID
      # @param user_ids [Array<String>] User IDs to add as participants
      #
      # @return [Hash] The updated thread
      # @raise [ArgumentError] if id or user_ids is invalid
      def add_participants(id:, user_ids:)
        validate_id!(id, "Thread")
        validate_user_ids!(user_ids)
        request(:post, "threads/#{id}/participants", { user_ids: user_ids })
      end

      # Remove participants from a thread
      #
      # @param id [String] The thread ID
      # @param user_ids [Array<String>] User IDs to remove
      #
      # @return [Hash] The updated thread
      # @raise [ArgumentError] if id or user_ids is invalid
      def remove_participants(id:, user_ids:)
        validate_id!(id, "Thread")
        validate_user_ids!(user_ids)
        request(:delete, "threads/#{id}/participants", { user_ids: user_ids })
      end

      private def validate_user_ids!(user_ids)
        raise ArgumentError, "User IDs are required" if user_ids.nil? || user_ids.empty?
        raise ArgumentError, "User IDs must be an array" unless user_ids.is_a?(Array)
      end
    end
  end
end
