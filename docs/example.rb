#!/usr/bin/env ruby

# Example usage of the Attio Ruby client
# 
# This file demonstrates common use cases and serves as
# additional documentation for YARD.

require_relative '../lib/attio'

# Initialize client with API key
# In production, use environment variables or secure config
client = Attio.client(api_key: ENV['ATTIO_API_KEY'] || 'your-api-key-here')

# Example 1: Working with People Records
puts "=== Working with People Records ==="

# List people with filters
people = client.records.list(
  object: 'people',
  filters: {
    name: { contains: 'John' }
  },
  limit: 10
)
puts "Found #{people['data'].length} people matching filter"

# Create a new person
new_person = client.records.create(
  object: 'people',
  data: {
    name: 'Jane Doe',
    email: 'jane.doe@example.com',
    phone: '+1-555-0123',
    notes: 'Created via Ruby client example'
  }
)
puts "Created person: #{new_person['data']['name']} (ID: #{new_person['data']['id']})"

# Get the person we just created
person = client.records.get(
  object: 'people',
  id: new_person['data']['id']
)
puts "Retrieved person: #{person['data']['name']}"

# Update the person
updated_person = client.records.update(
  object: 'people',
  id: person['data']['id'],
  data: {
    name: 'Jane Smith',
    notes: 'Updated name after marriage'
  }
)
puts "Updated person name to: #{updated_person['data']['name']}"

# Example 2: Working with Companies
puts "\n=== Working with Company Records ==="

# Create a company
company = client.records.create(
  object: 'companies',
  data: {
    name: 'Acme Corporation',
    domain: 'acme.com',
    industry: 'Technology'
  }
)
puts "Created company: #{company['data']['name']}"

# Link the person to the company
client.records.update(
  object: 'people',
  id: person['data']['id'],
  data: {
    company: {
      target_object: 'companies',
      target_record_id: company['data']['id']
    }
  }
)
puts "Linked #{person['data']['name']} to #{company['data']['name']}"

# Example 3: Working with Other Resources
puts "\n=== Working with Other Resources ==="

# List all object types
objects = client.objects.list
puts "Available object types: #{objects['data'].map { |obj| obj['api_slug'] }.join(', ')}"

# List workspaces
workspaces = client.workspaces.list
puts "Available workspaces: #{workspaces['data'].length}"

# Get current user
current_user = client.users.me
puts "Current user: #{current_user['data']['name']} (#{current_user['data']['email']})"

# Example 4: Error Handling
puts "\n=== Error Handling Example ==="

begin
  # Try to get a non-existent record
  client.records.get(object: 'people', id: 'non-existent-id')
rescue Attio::NotFoundError => e
  puts "Caught expected error: #{e.message}"
rescue Attio::APIError => e
  puts "API error: #{e.message}"
end

# Clean up - delete the records we created
puts "\n=== Cleanup ==="
client.records.delete(object: 'people', id: person['data']['id'])
puts "Deleted person record"

client.records.delete(object: 'companies', id: company['data']['id'])
puts "Deleted company record"

puts "\nExample completed successfully!"