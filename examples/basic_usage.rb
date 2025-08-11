#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "attio"

# Basic usage example for the Attio Ruby gem
#
# This example demonstrates:
# - Client initialization
# - Working with records (people, companies)
# - Creating relationships between records
# - Error handling

# Initialize the client with your API key
# You can get your API key from: https://app.attio.com/settings/api-keys
client = Attio.client(api_key: ENV.fetch("ATTIO_API_KEY"))

puts "🚀 Attio Ruby Client - Basic Usage Example"
puts "=" * 50

begin
  # List all available objects in your workspace
  puts "\n📋 Available Objects:"
  objects = client.objects.list
  objects["data"].each do |object|
    puts "  - #{object['name']} (#{object['id']})"
  end

  # Working with People records
  puts "\n👥 Working with People:"

  # List existing people (first 5)
  people = client.records.list(object: "people", limit: 5)
  puts "  Found #{people['data'].length} people records"

  # Create a new person
  new_person = client.records.create(
    object: "people",
    data: {
      name: "John Doe",
      email: "john.doe@example.com",
      phone: "+1-555-0123",
      title: "Software Engineer",
    }
  )
  puts "  ✅ Created person: #{new_person['data']['name']} (ID: #{new_person['data']['id']})"

  # Update the person
  updated_person = client.records.update(
    object: "people",
    id: new_person["data"]["id"],
    data: { title: "Senior Software Engineer" }
  )
  puts "  ✅ Updated title to: #{updated_person['data']['title']}"

  # Working with Companies
  puts "\n🏢 Working with Companies:"

  # Create a company
  new_company = client.records.create(
    object: "companies",
    data: {
      name: "Acme Corp",
      domain: "acme.com",
      employee_count: 100,
      description: "Leading provider of innovative solutions",
    }
  )
  puts "  ✅ Created company: #{new_company['data']['name']}"

  # Link person to company (create relationship)
  # Note: This requires the person and company to have a relationship field configured
  puts "\n🔗 Creating Relationships:"
  # This would typically be done through a reference field
  # The exact implementation depends on your Attio workspace configuration

  # Working with Lists
  puts "\n📝 Working with Lists:"
  lists = client.lists.list(limit: 5)
  if lists["data"].any?
    first_list = lists["data"].first
    puts "  Found list: #{first_list['name']}"

    # Get entries in the list
    entries = client.lists.entries(id: first_list["id"], limit: 5)
    puts "  List has #{entries['data'].length} entries"
  else
    puts "  No lists found in workspace"
  end

  # Cleanup - Delete the test records
  puts "\n🧹 Cleaning up test data:"
  client.records.delete(object: "people", id: new_person["data"]["id"])
  puts "  ✅ Deleted test person record"

  client.records.delete(object: "companies", id: new_company["data"]["id"])
  puts "  ✅ Deleted test company record"
rescue Attio::AuthenticationError => e
  puts "❌ Authentication failed: #{e.message}"
  puts "   Please check your API key"
rescue Attio::NotFoundError => e
  puts "❌ Resource not found: #{e.message}"
rescue Attio::ValidationError => e
  puts "❌ Validation error: #{e.message}"
rescue Attio::Error => e
  puts "❌ API error: #{e.message}"
end

puts "\n✨ Example completed!"
