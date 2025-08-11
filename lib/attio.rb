# frozen_string_literal: true

require "typhoeus"

require "attio/version"
require "attio/errors"
require "attio/http_client"
require "attio/client"

require "attio/resources/base"
require "attio/resources/records"
require "attio/resources/objects"
require "attio/resources/lists"
require "attio/resources/workspaces"
require "attio/resources/attributes"
require "attio/resources/users"
require "attio/resources/notes"
require "attio/resources/tasks"
require "attio/resources/comments"
require "attio/resources/threads"
require "attio/resources/workspace_members"
require "attio/resources/deals"
require "attio/resources/meta"
require "attio/resources/bulk"
require "attio/rate_limiter"

# The main Attio module provides access to the Attio API client.
#
# This is the primary entry point for interacting with the Attio API.
#
# @example Basic usage
#   client = Attio.client(api_key: 'your-api-key')
#
# @example Working with records
#   # List records for a specific object type
#   records = client.records.list(object: 'people', filters: { name: 'John' })
#
#   # Create a new record
#   new_record = client.records.create(
#     object: 'people',
#     data: { name: 'Jane Doe', email: 'jane@example.com' }
#   )
#
#   # Get a specific record
#   record = client.records.get(object: 'people', id: 'record-id')
#
#   # Update a record
#   updated = client.records.update(
#     object: 'people',
#     id: 'record-id',
#     data: { name: 'Jane Smith' }
#   )
#
#   # Delete a record
#   client.records.delete(object: 'people', id: 'record-id')
#
# @author Ernest Sim
# @since 1.0.0
module Attio
  # Creates a new Attio API client instance.
  #
  # @param api_key [String] Your Attio API key
  # @return [Client] A new client instance configured with the provided API key
  # @raise [ArgumentError] if api_key is nil or empty
  #
  # @example Create a client
  #   client = Attio.client(api_key: 'your-api-key-here')
  def self.client(api_key:)
    Client.new(api_key: api_key)
  end
end
