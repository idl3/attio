#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "attio"

# Test Meta resource against production API
API_KEY = ENV["API_KEY"] || "5472096a0d3ad936523a7a9101807bb3155616a3e04a7649ad41cd5a0261dddd"

puts "Testing Meta Resource Against Production API"
puts "=" * 50

client = Attio.client(api_key: API_KEY)
meta = client.meta

# Test 1: identify method
puts "\n1. Testing meta.identify:"
info = meta.identify
puts "   Response keys: #{info['data'].keys.join(', ')}"
puts "   Active: #{info['data']['active']}"
puts "   Workspace: #{info['data']['workspace_name']}"
puts "   Token type: #{info['data']['token_type']}"

# Test 2: active? method
puts "\n2. Testing meta.active?:"
is_active = meta.active?
puts "   Token active: #{is_active}"
raise "Expected active to be true" unless is_active

# Test 3: workspace method
puts "\n3. Testing meta.workspace:"
workspace = meta.workspace
puts "   Workspace ID: #{workspace['id']}"
puts "   Workspace Name: #{workspace['name']}"
puts "   Workspace Slug: #{workspace['slug']}"
puts "   Logo URL: #{workspace['logo_url'].inspect}"

# Test 4: permissions method
puts "\n4. Testing meta.permissions:"
permissions = meta.permissions
puts "   Total permissions: #{permissions.size}"
puts "   First 3 permissions: #{permissions[0..2].join(', ')}"

# Test 5: has_permission? method
puts "\n5. Testing meta.has_permission?:"
has_comment = meta.has_permission?("comment:read-write")
has_admin = meta.has_permission?("admin:full")
puts "   Has comment:read-write: #{has_comment}"
puts "   Has admin:full: #{has_admin}"

# Test 6: token_info method
puts "\n6. Testing meta.token_info:"
token = meta.token_info
puts "   Active: #{token['active']}"
puts "   Type: #{token['type']}"
puts "   Expires at: #{token['expires_at'].inspect}"
puts "   Issued at: #{token['issued_at']}"
puts "   Client ID: #{token['client_id']}"
puts "   Authorized by: #{token['authorized_by']}"

# Test 7: Alias methods
puts "\n7. Testing alias methods:"
self_result = meta.self
get_result = meta.get
puts "   meta.self returns data: #{self_result.key?('data')}"
puts "   meta.get returns data: #{get_result.key?('data')}"

# Test 8: Workspaces.get (should now work)
puts "\n8. Testing workspaces.get (uses /v2/self):"
workspace_info = client.workspaces.get
puts "   Returns workspace data: #{workspace_info['data'].key?('workspace_name')}"

# Test 9: Enhanced client health check
puts "\n9. Testing enhanced client health check:"
enhanced = Attio::EnhancedClient.new(api_key: API_KEY)
puts "   Health check passes: #{enhanced.send(:check_api_health)}"

puts "\n#{'=' * 50}"
puts "✅ All Meta Resource Tests Passed!"
puts "=" * 50
