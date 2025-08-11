#!/usr/bin/env ruby
# frozen_string_literal: true

require "attio"
require "time"

# Example: Complete CRM Workflow
#
# This example demonstrates a complete CRM workflow including:
# - Creating and managing companies and contacts
# - Working with lists and workspace management
# - Using collaboration features
# - Error handling

# Initialize the client
client = Attio.client(api_key: ENV.fetch("ATTIO_API_KEY"))

puts "Attio Complete CRM Workflow Example"
puts "=" * 40

# Error handling wrapper
def safe_execute(description)
  print "#{description}..."
  result = yield
  puts " ✓"
  result
rescue Attio::NotFoundError => e
  puts " ✗ Not found: #{e.message}"
  nil
rescue Attio::ValidationError => e
  puts " ✗ Validation error: #{e.message}"
  nil
rescue Attio::Error => e
  puts " ✗ Error: #{e.message}"
  nil
end

# 1. Get workspace information
puts "\n1. Workspace Information"
puts "-" * 20
workspace = safe_execute("Getting current workspace") do
  client.workspaces.get
end

if workspace
  puts "   Workspace: #{workspace.dig('data', 'name')}"
  puts "   ID: #{workspace.dig('data', 'id', 'workspace_id')}"
end

# 2. List available objects and attributes
puts "\n2. Schema Information"
puts "-" * 20
objects = safe_execute("Listing objects") do
  client.objects.list
end

if objects && objects["data"]
  puts "   Available objects:"
  objects["data"].each do |obj|
    puts "   - #{obj['api_slug']}: #{obj['name']}"
  end
end

# 3. Create a sales pipeline workflow
puts "\n3. Sales Pipeline Setup"
puts "-" * 20

# Create a company
company = safe_execute("Creating prospect company") do
  client.records.create(
    object: "companies",
    data: {
      name: "Innovation Labs Inc",
      domain: "innovationlabs.example.com",
      industry: "Technology",
      description: "Potential enterprise customer",
    }
  )
end
company_id = company&.dig("data", "id", "record_id")

# Create primary contact
contact = safe_execute("Creating primary contact") do
  client.records.create(
    object: "people",
    data: {
      name: "Michael Chen",
      email: "m.chen@innovationlabs.example.com",
      title: "CTO",
      phone: "+1-555-0123",
    }
  )
end
contact&.dig("data", "id", "record_id")

# Create additional contacts
if company_id
  safe_execute("Creating additional contact") do
    client.records.create(
      object: "people",
      data: {
        name: "Lisa Park",
        email: "l.park@innovationlabs.example.com",
        title: "VP of Product",
      }
    )
  end
end

# 4. Create and manage lists
puts "\n4. List Management"
puts "-" * 20

lists = safe_execute("Getting available lists") do
  client.lists.list
end

if lists && lists["data"] && !lists["data"].empty?
  list_id = lists["data"].first["id"]["list_id"]

  # Add company to a list
  if company_id
    safe_execute("Adding company to list") do
      client.lists.create_entry(
        id: list_id,
        data: {
          record_id: company_id,
          notes: "High priority prospect",
        }
      )
    end
  end

  # Get list entries
  entries = safe_execute("Getting list entries") do
    client.lists.entries(id: list_id, limit: 5)
  end

  puts "   List has #{entries.dig('data')&.length || 0} entries" if entries
end

# 5. Collaboration workflow
puts "\n5. Collaboration Workflow"
puts "-" * 20

if company_id
  # Create a discussion thread
  thread = safe_execute("Creating sales discussion thread") do
    client.threads.create(
      parent_object: "companies",
      parent_record_id: company_id,
      title: "Sales Opportunity - Innovation Labs",
      description: "Track all sales activities and discussions"
    )
  end
  thread_id = thread&.dig("data", "id", "thread_id")

  # Add initial comment
  if thread_id
    safe_execute("Adding sales strategy comment") do
      client.comments.create(
        thread_id: thread_id,
        content: <<~CONTENT
          ## Opportunity Overview
          - **Company**: Innovation Labs Inc
          - **Potential Value**: $100K ARR
          - **Timeline**: Q1 2025

          ## Next Steps
          1. Schedule discovery call
          2. Prepare custom demo
          3. Send pricing proposal
        CONTENT
      )
    end
  end

  # Create tasks
  safe_execute("Creating discovery call task") do
    client.tasks.create(
      parent_object: "companies",
      parent_record_id: company_id,
      title: "Schedule discovery call with Michael Chen",
      due_date: (Date.today + 3).iso8601,
      description: "Initial discovery call to understand their requirements"
    )
  end

  safe_execute("Creating demo prep task") do
    client.tasks.create(
      parent_object: "companies",
      parent_record_id: company_id,
      title: "Prepare customized product demo",
      due_date: (Date.today + 7).iso8601
    )
  end

  # Create meeting notes
  safe_execute("Creating initial contact notes") do
    client.notes.create(
      parent_object: "companies",
      parent_record_id: company_id,
      title: "Initial Contact - #{Date.today}",
      content: <<~CONTENT
        ## Contact Method
        Inbound inquiry via website

        ## Requirements
        - Looking for enterprise CRM solution
        - Team size: 200+ employees
        - Current solution: Spreadsheets

        ## Pain Points
        - No centralized customer data
        - Manual reporting processes
        - Limited collaboration features

        ## Budget
        Approved budget: $100-150K annually

        ## Decision Timeline
        Looking to implement in Q1 2025
      CONTENT
    )
  end
end

# 6. Query and reporting
puts "\n6. Queries and Reporting"
puts "-" * 20

# Get all high-priority tasks
tasks = safe_execute("Getting pending tasks") do
  client.tasks.list(status: "pending", limit: 5)
end

if tasks
  puts "   Pending tasks: #{tasks.dig('data')&.length || 0}"
  tasks["data"]&.each do |task|
    puts "   - #{task.dig('title')}"
  end
end

# Query recent companies
recent_companies = safe_execute("Finding recent companies") do
  client.records.list(
    object: "companies",
    sorts: [{ field: "created_at", direction: "desc" }],
    limit: 5
  )
end

puts "   Recent companies: #{recent_companies.dig('data')&.length || 0}" if recent_companies

# 7. User management
puts "\n7. User Information"
puts "-" * 20

# Get current user
me = safe_execute("Getting current user") do
  client.users.me
end

if me
  puts "   Current user: #{me.dig('data', 'name')}"
  puts "   Email: #{me.dig('data', 'email')}"
end

# List all users
users = safe_execute("Listing workspace users") do
  client.users.list
end

puts "   Total users: #{users.dig('data')&.length || 0}" if users

# 8. Advanced features
puts "\n8. Advanced Features"
puts "-" * 20

# Get custom attributes
if company_id
  attributes = safe_execute("Getting company attributes") do
    client.attributes.list(object: "companies")
  end

  puts "   Company attributes: #{attributes.dig('data')&.length || 0}" if attributes
end

# Demonstrate pagination
puts "   Demonstrating pagination..."
all_records = []
cursor = nil
pages = 0

loop do
  params = { object: "companies", limit: 2 }
  params[:cursor] = cursor if cursor

  page = safe_execute("   Fetching page #{pages + 1}") do
    client.records.list(**params)
  end

  break unless page && page["data"]

  all_records.concat(page["data"])
  pages += 1

  cursor = page.dig("pagination", "next_cursor")
  break unless cursor && pages < 3 # Limit to 3 pages for demo
end

puts "   Fetched #{all_records.length} records across #{pages} pages"

# 9. Summary
puts "\n9. Workflow Summary"
puts "-" * 20
puts "   ✓ Workspace configured"
puts "   ✓ Company and contacts created"
puts "   ✓ Lists managed"
puts "   ✓ Collaboration tools utilized"
puts "   ✓ Tasks and notes created"
puts "   ✓ Queries executed"
puts "   ✓ User information retrieved"

puts "\n" + ("=" * 40)
puts "Complete workflow example finished!"
puts "\nThis example demonstrated:"
puts "  • Complete CRM setup"
puts "  • Record creation and management"
puts "  • List operations"
puts "  • Collaboration features"
puts "  • Task management"
puts "  • Querying and reporting"
puts "  • User management"
puts "  • Error handling"
puts "  • Pagination"

# Optional cleanup
# if company_id
#   safe_execute("Cleaning up company") do
#     client.records.delete(object: "companies", id: company_id)
#   end
# end
# if contact_id
#   safe_execute("Cleaning up contact") do
#     client.records.delete(object: "people", id: contact_id)
#   end
# end
