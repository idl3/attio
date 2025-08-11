#!/usr/bin/env ruby
# frozen_string_literal: true

# Test without loading external dependencies
$LOAD_PATH.unshift(File.expand_path("lib", __dir__))

puts "Testing Attio gem structure..."

# Test version file
require "attio/version"
puts "✓ Version loaded: #{Attio::VERSION}"

# Test error definitions
require "attio/errors"
[
  Attio::Error,
  Attio::AuthenticationError,
  Attio::NotFoundError,
  Attio::ValidationError,
  Attio::RateLimitError,
  Attio::ServerError,
].each do |error_class|
  puts "✓ #{error_class} is defined"
end

# Test that all files exist
files_to_check = [
  "lib/attio.rb",
  "lib/attio/client.rb",
  "lib/attio/resources/base.rb",
  "lib/attio/resources/records.rb",
  "lib/attio/resources/objects.rb",
  "lib/attio/resources/lists.rb",
  "lib/attio/resources/workspaces.rb",
  "lib/attio/resources/attributes.rb",
  "lib/attio/resources/users.rb",
]

files_to_check.each do |file|
  if File.exist?(file)
    puts "✓ #{file} exists"
  else
    puts "✗ #{file} is missing!"
  end
end

# Test spec files exist
spec_files = Dir.glob("spec/**/*_spec.rb")
puts "\nFound #{spec_files.length} spec files:"
spec_files.each { |f| puts "  - #{f}" }

puts "\nBasic structure test completed!"
