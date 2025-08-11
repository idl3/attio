# frozen_string_literal: true

module Attio
  module Resources
    # Bulk operations for efficient batch processing
    #
    # @example Bulk create records
    #   client.bulk.create_records(
    #     object: "companies",
    #     records: [
    #       { name: "Acme Corp", domain: "acme.com" },
    #       { name: "Tech Co", domain: "techco.com" }
    #     ]
    #   )
    #
    # @example Bulk update records
    #   client.bulk.update_records(
    #     object: "people",
    #     updates: [
    #       { id: "person_123", data: { title: "CEO" } },
    #       { id: "person_456", data: { title: "CTO" } }
    #     ]
    #   )
    class Bulk < Base
      # Maximum number of records per bulk operation
      MAX_BATCH_SIZE = 100

      # Bulk create multiple records
      #
      # @param object [String] The object type (companies, people, etc.)
      # @param records [Array<Hash>] Array of record data to create
      # @param options [Hash] Additional options
      # @option options [Boolean] :partial_success Allow partial success (default: false)
      # @option options [Boolean] :return_records Return created records (default: true)
      # @return [Hash] Results including created records and any errors
      def create_records(object:, records:, options: {})
        validate_required_string!(object, "Object type")
        validate_bulk_records!(records, "create")

        batches = records.each_slice(MAX_BATCH_SIZE).to_a
        results = []

        batches.each_with_index do |batch, index|
          body = {
            records: batch.map { |record| { data: record } },
            partial_success: options.fetch(:partial_success, false),
            return_records: options.fetch(:return_records, true),
          }

          result = request(:post, "objects/#{object}/records/bulk", body)
          results << result.merge("batch" => index + 1)
        end

        merge_batch_results(results)
      end

      # Bulk update multiple records
      #
      # @param object [String] The object type
      # @param updates [Array<Hash>] Array of updates with :id and :data keys
      # @param options [Hash] Additional options
      # @option options [Boolean] :partial_success Allow partial success (default: false)
      # @option options [Boolean] :return_records Return updated records (default: true)
      # @return [Hash] Results including updated records and any errors
      def update_records(object:, updates:, options: {})
        validate_required_string!(object, "Object type")
        validate_bulk_updates!(updates)

        batches = updates.each_slice(MAX_BATCH_SIZE).to_a
        results = []

        batches.each_with_index do |batch, index|
          body = {
            updates: batch,
            partial_success: options.fetch(:partial_success, false),
            return_records: options.fetch(:return_records, true),
          }

          result = request(:patch, "objects/#{object}/records/bulk", body)
          results << result.merge("batch" => index + 1)
        end

        merge_batch_results(results)
      end

      # Bulk delete multiple records
      #
      # @param object [String] The object type
      # @param ids [Array<String>] Array of record IDs to delete
      # @param options [Hash] Additional options
      # @option options [Boolean] :partial_success Allow partial success (default: false)
      # @return [Hash] Results including deletion confirmations and any errors
      def delete_records(object:, ids:, options: {})
        validate_required_string!(object, "Object type")
        validate_bulk_ids!(ids)

        batches = ids.each_slice(MAX_BATCH_SIZE).to_a
        results = []

        batches.each_with_index do |batch, index|
          body = {
            ids: batch,
            partial_success: options.fetch(:partial_success, false),
          }

          result = request(:delete, "objects/#{object}/records/bulk", body)
          results << result.merge("batch" => index + 1)
        end

        merge_batch_results(results)
      end

      # Bulk upsert records (create or update based on matching criteria)
      #
      # @param object [String] The object type
      # @param records [Array<Hash>] Records to upsert
      # @param match_attribute [String] Attribute to match on (e.g., "email", "domain")
      # @param options [Hash] Additional options
      # @return [Hash] Results including created/updated records
      def upsert_records(object:, records:, match_attribute:, options: {})
        validate_required_string!(object, "Object type")
        validate_required_string!(match_attribute, "Match attribute")
        validate_bulk_records!(records, "upsert")

        batches = records.each_slice(MAX_BATCH_SIZE).to_a
        results = []

        batches.each_with_index do |batch, index|
          body = {
            records: batch.map { |record| { data: record } },
            match_attribute: match_attribute,
            partial_success: options.fetch(:partial_success, false),
            return_records: options.fetch(:return_records, true),
          }

          result = request(:put, "objects/#{object}/records/bulk", body)
          results << result.merge("batch" => index + 1)
        end

        merge_batch_results(results)
      end

      # Bulk add entries to a list
      #
      # @param list_id [String] The list ID
      # @param entries [Array<Hash>] Array of entries to add
      # @param options [Hash] Additional options
      # @return [Hash] Results including added entries
      def add_list_entries(list_id:, entries:, options: {})
        validate_id!(list_id, "List")
        validate_bulk_records!(entries, "add to list")

        batches = entries.each_slice(MAX_BATCH_SIZE).to_a
        results = []

        batches.each_with_index do |batch, index|
          body = {
            entries: batch,
            partial_success: options.fetch(:partial_success, false),
          }

          result = request(:post, "lists/#{list_id}/entries/bulk", body)
          results << result.merge("batch" => index + 1)
        end

        merge_batch_results(results)
      end

      # Bulk remove entries from a list
      #
      # @param list_id [String] The list ID
      # @param entry_ids [Array<String>] Array of entry IDs to remove
      # @param options [Hash] Additional options
      # @return [Hash] Results including removal confirmations
      def remove_list_entries(list_id:, entry_ids:, options: {})
        validate_id!(list_id, "List")
        validate_bulk_ids!(entry_ids)

        batches = entry_ids.each_slice(MAX_BATCH_SIZE).to_a
        results = []

        batches.each_with_index do |batch, index|
          body = {
            entry_ids: batch,
            partial_success: options.fetch(:partial_success, false),
          }

          result = request(:delete, "lists/#{list_id}/entries/bulk", body)
          results << result.merge("batch" => index + 1)
        end

        merge_batch_results(results)
      end

      private def validate_bulk_records!(records, operation)
        raise ArgumentError, "Records array is required for bulk #{operation}" if records.nil?
        raise ArgumentError, "Records must be an array for bulk #{operation}" unless records.is_a?(Array)
        raise ArgumentError, "Records array cannot be empty for bulk #{operation}" if records.empty?
        raise ArgumentError, "Too many records (max #{MAX_BATCH_SIZE * 10})" if records.size > MAX_BATCH_SIZE * 10

        records.each_with_index do |record, index|
          raise ArgumentError, "Record at index #{index} must be a hash" unless record.is_a?(Hash)
        end
      end

      private def validate_bulk_updates!(updates)
        raise ArgumentError, "Updates array is required for bulk update" if updates.nil?
        raise ArgumentError, "Updates must be an array for bulk update" unless updates.is_a?(Array)
        raise ArgumentError, "Updates array cannot be empty for bulk update" if updates.empty?
        raise ArgumentError, "Too many updates (max #{MAX_BATCH_SIZE * 10})" if updates.size > MAX_BATCH_SIZE * 10

        updates.each_with_index do |update, index|
          raise ArgumentError, "Update at index #{index} must be a hash" unless update.is_a?(Hash)

          raise ArgumentError, "Update at index #{index} must have an :id" unless update[:id]

          raise ArgumentError, "Update at index #{index} must have :data" unless update[:data]
        end
      end

      private def validate_bulk_ids!(ids)
        raise ArgumentError, "IDs array is required for bulk operation" if ids.nil?
        raise ArgumentError, "IDs must be an array for bulk operation" unless ids.is_a?(Array)
        raise ArgumentError, "IDs array cannot be empty for bulk operation" if ids.empty?
        raise ArgumentError, "Too many IDs (max #{MAX_BATCH_SIZE * 10})" if ids.size > MAX_BATCH_SIZE * 10

        ids.each_with_index do |id, index|
          raise ArgumentError, "ID at index #{index} cannot be nil or empty" if id.nil? || id.to_s.strip.empty?
        end
      end

      private def merge_batch_results(results)
        merged = {
          "success" => true,
          "total_batches" => results.size,
          "records" => [],
          "errors" => [],
          "statistics" => {
            "created" => 0,
            "updated" => 0,
            "deleted" => 0,
            "failed" => 0,
          },
        }

        results.each do |result|
          merged["records"].concat(result["records"] || [])
          merged["errors"].concat(result["errors"] || [])

          if result["statistics"]
            merged["statistics"]["created"] += result["statistics"]["created"] || 0
            merged["statistics"]["updated"] += result["statistics"]["updated"] || 0
            merged["statistics"]["deleted"] += result["statistics"]["deleted"] || 0
            merged["statistics"]["failed"] += result["statistics"]["failed"] || 0
          end

          merged["success"] &&= result["success"] != false
        end

        merged
      end
    end
  end
end
