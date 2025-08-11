#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/attio"

# Test the gem with Typhoeus
puts "=== Testing Attio Ruby Gem with Typhoeus ==="
puts "Version: #{Attio::VERSION}"

# Initialize client
API_KEY = "5472096a0d3ad936523a7a9101807bb3155616a3e04a7649ad41cd5a0261dddd"
client = Attio.client(api_key: API_KEY)
puts "✓ Client initialized"

# Test listing people
puts "\nListing people..."
begin
  result = client.records.list(object: "people", sorts: [], limit: 5)
  records = result["data"]
  puts "✓ Found #{records.length} records"

  records.each do |record|
    name = begin
      record["values"]["name"][0]["full_name"]
    rescue StandardError
      "Unknown"
    end
    email = begin
      record["values"]["email_addresses"][0]["email_address"]
    rescue StandardError
      "No email"
    end
    puts "  - #{name} (#{email})"
  end
rescue StandardError => e
  puts "✗ Failed to list records: #{e.message}"
  puts e.backtrace
end

puts "\n✨ Test complete!"
