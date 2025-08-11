# frozen_string_literal: true

module Attio
  module Resources
    # API resource for managing comments in Attio
    #
    # Comments can be added to records and threads for collaboration.
    #
    # @example Creating a comment on a record
    #   client.comments.create(
    #     parent_object: "people",
    #     parent_record_id: "person_123",
    #     content: "Just had a great call with this lead!"
    #   )
    #
    # @example Creating a comment in a thread
    #   client.comments.create(
    #     thread_id: "thread_456",
    #     content: "Following up on our discussion..."
    #   )
    class Comments < Base
      # List comments for a parent record or thread
      #
      # @param params [Hash] Query parameters
      # @option params [String] :parent_object Parent object type
      # @option params [String] :parent_record_id Parent record ID
      # @option params [String] :thread_id Thread ID
      # @option params [Integer] :limit Number of comments to return
      # @option params [String] :cursor Pagination cursor
      #
      # @return [Hash] API response containing comments
      def list(**params)
        validate_list_params!(params)
        request(:get, "comments", params)
      end

      # Get a specific comment by ID
      #
      # @param id [String] The comment ID
      #
      # @return [Hash] The comment data
      # @raise [ArgumentError] if id is nil or empty
      def get(id:)
        validate_id!(id, "Comment")
        request(:get, "comments/#{id}")
      end

      # Create a new comment
      #
      # @param content [String] The comment content (supports markdown)
      # @param parent_object [String] Parent object type (required if no thread_id)
      # @param parent_record_id [String] Parent record ID (required if no thread_id)
      # @param thread_id [String] Thread ID (required if no parent_object/parent_record_id)
      # @param data [Hash] Additional comment data
      #
      # @return [Hash] The created comment
      # @raise [ArgumentError] if required parameters are missing
      def create(content:, parent_object: nil, parent_record_id: nil, thread_id: nil, **data)
        validate_required_string!(content, "Comment content")
        validate_create_params!(parent_object, parent_record_id, thread_id)

        params = data.merge(content: content)

        if thread_id
          params[:thread_id] = thread_id
        else
          params[:parent_object] = parent_object
          params[:parent_record_id] = parent_record_id
        end

        request(:post, "comments", params)
      end

      # Update an existing comment
      #
      # @param id [String] The comment ID
      # @param content [String] The new content
      #
      # @return [Hash] The updated comment
      # @raise [ArgumentError] if id or content is invalid
      def update(id:, content:)
        validate_id!(id, "Comment")
        validate_required_string!(content, "Comment content")
        request(:patch, "comments/#{id}", { content: content })
      end

      # Delete a comment
      #
      # @param id [String] The comment ID to delete
      #
      # @return [Hash] Deletion confirmation
      # @raise [ArgumentError] if id is nil or empty
      def delete(id:)
        validate_id!(id, "Comment")
        request(:delete, "comments/#{id}")
      end

      # React to a comment with an emoji
      #
      # @param id [String] The comment ID
      # @param emoji [String] The emoji reaction (e.g., "👍", "❤️")
      #
      # @return [Hash] The updated comment with reaction
      # @raise [ArgumentError] if id or emoji is invalid
      def react(id:, emoji:)
        validate_id!(id, "Comment")
        validate_required_string!(emoji, "Emoji")
        request(:post, "comments/#{id}/reactions", { emoji: emoji })
      end

      # Remove a reaction from a comment
      #
      # @param id [String] The comment ID
      # @param emoji [String] The emoji reaction to remove
      #
      # @return [Hash] The updated comment
      # @raise [ArgumentError] if id or emoji is invalid
      def unreact(id:, emoji:)
        validate_id!(id, "Comment")
        validate_required_string!(emoji, "Emoji")
        request(:delete, "comments/#{id}/reactions/#{CGI.escape(emoji)}")
      end

      private def validate_list_params!(params)
        has_parent = params[:parent_object] && params[:parent_record_id]
        has_thread = params[:thread_id]

        return if has_parent || has_thread

        raise ArgumentError, "Must provide either parent_object/parent_record_id or thread_id"
      end

      private def validate_create_params!(parent_object, parent_record_id, thread_id)
        has_parent = parent_object && parent_record_id
        has_thread = thread_id

        unless has_parent || has_thread
          raise ArgumentError, "Must provide either parent_object/parent_record_id or thread_id"
        end

        return unless has_parent && has_thread

        raise ArgumentError, "Cannot provide both parent and thread parameters"
      end
    end
  end
end
