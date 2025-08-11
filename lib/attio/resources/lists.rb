module Attio
  module Resources
    class Lists < Base
      def list(**params)
        request(:get, "lists", params)
      end

      def get(id:)
        validate_id!(id)
        request(:get, "lists/#{id}")
      end

      def entries(id:, **params)
        validate_id!(id)
        request(:get, "lists/#{id}/entries", params)
      end

      def create_entry(id:, data:)
        validate_id!(id)
        validate_data!(data)
        request(:post, "lists/#{id}/entries", data)
      end

      def get_entry(list_id:, entry_id:)
        validate_list_id!(list_id)
        validate_entry_id!(entry_id)
        request(:get, "lists/#{list_id}/entries/#{entry_id}")
      end

      def delete_entry(list_id:, entry_id:)
        validate_list_id!(list_id)
        validate_entry_id!(entry_id)
        request(:delete, "lists/#{list_id}/entries/#{entry_id}")
      end

      private

      def validate_id!(id)
        raise ArgumentError, "List ID is required" if id.nil? || id.to_s.strip.empty?
      end

      def validate_list_id!(list_id)
        raise ArgumentError, "List ID is required" if list_id.nil? || list_id.to_s.strip.empty?
      end

      def validate_entry_id!(entry_id)
        raise ArgumentError, "Entry ID is required" if entry_id.nil? || entry_id.to_s.strip.empty?
      end

      def validate_data!(data)
        raise ArgumentError, "Data is required" if data.nil?
        raise ArgumentError, "Data must be a hash" unless data.is_a?(Hash)
      end
    end
  end
end