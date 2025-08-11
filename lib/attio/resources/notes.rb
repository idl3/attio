# frozen_string_literal: true

module Attio
  module Resources
    # API resource for managing notes in Attio
    #
    # Notes can be attached to records to track important information,
    # meeting notes, or any other textual data.
    #
    # @example Creating a note on a person
    #   client.notes.create(
    #     parent_object: "people",
    #     parent_record_id: "person_123",
    #     title: "Meeting Notes",
    #     content: "Discussed Q4 goals..."
    #   )
    #
    # @example Listing notes for a record
    #   client.notes.list(
    #     parent_object: "companies",
    #     parent_record_id: "company_456"
    #   )
    class Notes < Base
      # List notes for a specific parent record
      #
      # @param parent_object [String] The parent object type (e.g., "people", "companies")
      # @param parent_record_id [String] The ID of the parent record
      # @param params [Hash] Additional query parameters
      # @option params [Integer] :limit Number of notes to return
      # @option params [String] :cursor Pagination cursor
      #
      # @return [Hash] API response containing notes
      # @raise [ArgumentError] if parent_object or parent_record_id is nil
      def list(parent_object:, parent_record_id:, **params)
        validate_parent!(parent_object, parent_record_id)
        request(:get, "notes", params.merge(
                                 parent_object: parent_object,
                                 parent_record_id: parent_record_id
                               ))
      end

      # Get a specific note by ID
      #
      # @param id [String] The note ID
      #
      # @return [Hash] The note data
      # @raise [ArgumentError] if id is nil or empty
      def get(id:)
        validate_id!(id, "Note")
        request(:get, "notes/#{id}")
      end

      # Create a new note
      #
      # @param parent_object [String] The parent object type
      # @param parent_record_id [String] The ID of the parent record
      # @param title [String] The note title
      # @param content [String] The note content (supports markdown)
      # @param data [Hash] Additional note data
      #
      # @return [Hash] The created note
      # @raise [ArgumentError] if required parameters are missing
      def create(parent_object:, parent_record_id:, title:, content:, **data)
        validate_parent!(parent_object, parent_record_id)
        validate_required_string!(title, "Note title")
        validate_required_string!(content, "Note content")

        request(:post, "notes", data.merge(
                                  parent_object: parent_object,
                                  parent_record_id: parent_record_id,
                                  title: title,
                                  content: content
                                ))
      end

      # Update an existing note
      #
      # @param id [String] The note ID
      # @param data [Hash] The fields to update
      # @option data [String] :title New title
      # @option data [String] :content New content
      #
      # @return [Hash] The updated note
      # @raise [ArgumentError] if id or data is invalid
      def update(id:, **data)
        validate_id!(id, "Note")
        validate_note_update_data!(data)
        request(:patch, "notes/#{id}", data)
      end

      # Delete a note
      #
      # @param id [String] The note ID to delete
      #
      # @return [Hash] Deletion confirmation
      # @raise [ArgumentError] if id is nil or empty
      def delete(id:)
        validate_id!(id, "Note")
        request(:delete, "notes/#{id}")
      end

      private def validate_note_update_data!(data)
        raise ArgumentError, "Update data is required" if data.empty?
        return if data.key?(:title) || data.key?(:content)

        raise ArgumentError, "Must provide title or content to update"
      end
    end
  end
end
