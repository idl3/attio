#!/usr/bin/env ruby

# Add lib to load path
$LOAD_PATH.unshift(File.expand_path('../lib', __FILE__))

# Load the gem
require 'attio'

# Basic smoke test
begin
  puts "Testing Attio gem..."
  puts "Version: #{Attio::VERSION}"
  
  # Test client initialization
  begin
    Attio::Client.new(api_key: nil)
    puts "ERROR: Should have raised error for nil API key"
  rescue ArgumentError => e
    puts "✓ Client validation works: #{e.message}"
  end
  
  # Test client creation
  client = Attio::Client.new(api_key: "test_key")
  puts "✓ Client created successfully"
  
  # Test resource access
  puts "✓ Records resource available: #{client.records.class}"
  puts "✓ Objects resource available: #{client.objects.class}"
  puts "✓ Lists resource available: #{client.lists.class}"
  puts "✓ Workspaces resource available: #{client.workspaces.class}"
  puts "✓ Attributes resource available: #{client.attributes.class}"
  puts "✓ Users resource available: #{client.users.class}"
  
  # Test error classes
  [
    Attio::Error,
    Attio::AuthenticationError,
    Attio::NotFoundError,
    Attio::ValidationError,
    Attio::RateLimitError,
    Attio::ServerError
  ].each do |error_class|
    puts "✓ #{error_class} is defined"
  end
  
  puts "\nAll basic tests passed!"
  
rescue StandardError => e
  puts "ERROR: #{e.message}"
  puts e.backtrace
  exit 1
end