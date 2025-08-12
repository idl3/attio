# frozen_string_literal: true

module Attio
  module Resources
    # API resource for managing Attio objects
    #
    # Objects define the schema and structure for different types of
    # records in your Attio workspace (e.g., people, companies).
    #
    # @example Listing all objects
    #   client.objects.list
    #
    # @example Creating a custom object
    #   client.objects.create(
    #     api_slug: "projects",
    #     singular_noun: "Project",
    #     plural_noun: "Projects"
    #   )
    #
    # @example Updating a custom object
    #   client.objects.update(
    #     id_or_slug: "projects",
    #     plural_noun: "Active Projects"
    #   )
    class Objects < Base
      # List all objects in the workspace
      #
      # @param params [Hash] Optional query parameters
      # @return [Hash] List of objects
      def list(**params)
        request(:get, "objects", params)
      end

      # Get a single object by ID or slug
      #
      # @param id_or_slug [String] The object ID or slug
      # @return [Hash] The object details
      def get(id_or_slug:)
        validate_id_or_slug!(id_or_slug)
        request(:get, "objects/#{id_or_slug}")
      end

      # Create a new custom object
      #
      # @param api_slug [String] Unique slug for the object (snake_case)
      # @param singular_noun [String] Singular name of the object
      # @param plural_noun [String] Plural name of the object
      # @return [Hash] The created object with ID and timestamps
      # @raise [ArgumentError] if required parameters are missing
      # @example
      #   object = client.objects.create(
      #     api_slug: "projects",
      #     singular_noun: "Project",
      #     plural_noun: "Projects"
      #   )
      def create(api_slug:, singular_noun:, plural_noun:)
        validate_required_string!(api_slug, "API slug")
        validate_required_string!(singular_noun, "Singular noun")
        validate_required_string!(plural_noun, "Plural noun")

        data = {
          api_slug: api_slug,
          singular_noun: singular_noun,
          plural_noun: plural_noun,
        }

        request(:post, "objects", { data: data })
      end

      # Update an existing custom object
      #
      # @param id_or_slug [String] The object ID or slug to update
      # @param api_slug [String, nil] New API slug (optional)
      # @param singular_noun [String, nil] New singular noun (optional)
      # @param plural_noun [String, nil] New plural noun (optional)
      # @return [Hash] The updated object
      # @raise [ArgumentError] if no update fields are provided
      # @example Update just the plural noun
      #   client.objects.update(
      #     id_or_slug: "projects",
      #     plural_noun: "Active Projects"
      #   )
      # @example Update multiple fields
      #   client.objects.update(
      #     id_or_slug: "old_slug",
      #     api_slug: "new_slug",
      #     singular_noun: "New Name",
      #     plural_noun: "New Names"
      #   )
      def update(id_or_slug:, api_slug: nil, singular_noun: nil, plural_noun: nil)
        validate_id_or_slug!(id_or_slug)

        data = {}
        data[:api_slug] = api_slug if api_slug
        data[:singular_noun] = singular_noun if singular_noun
        data[:plural_noun] = plural_noun if plural_noun

        raise ArgumentError, "At least one field to update is required" if data.empty?

        request(:patch, "objects/#{id_or_slug}", { data: data })
      end

      # Delete a custom object
      #
      # NOTE: The Attio API v2.0.0 does not currently support deleting custom objects.
      # To delete a custom object, please visit your Attio settings at:
      # Settings > Data Model > Objects
      #
      # @param id_or_slug [String] The object ID or slug to delete
      # @raise [NotImplementedError] Always raised as the API doesn't support this operation
      # @example
      #   client.objects.delete(id_or_slug: "projects")
      #   # => NotImplementedError: The Attio API does not currently support deleting custom objects.
      #   #    Please delete objects through the Attio UI at: Settings > Data Model > Objects
      def delete(id_or_slug:)
        validate_id_or_slug!(id_or_slug)
        raise NotImplementedError,
              "The Attio API does not currently support deleting custom objects. " \
              "Please delete objects through the Attio UI at: Settings > Data Model > Objects"
      end

      # Alias for delete method for consistency with other resources
      # NOTE: See delete method for API limitations
      alias destroy delete

      private def validate_id_or_slug!(id_or_slug)
        raise ArgumentError, "Object ID or slug is required" if id_or_slug.nil? || id_or_slug.to_s.strip.empty?
      end
    end
  end
end
