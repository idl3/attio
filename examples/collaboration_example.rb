#!/usr/bin/env ruby
# frozen_string_literal: true

require "attio"
require "time"

# Example: Collaboration Features (Comments, Threads, Tasks, Notes)
#
# This example demonstrates how to use Attio's collaboration features
# to manage team communication and tasks on customer records.

# Initialize the client
client = Attio.client(api_key: ENV.fetch("ATTIO_API_KEY"))

puts "Attio Collaboration Features Example"
puts "=" * 40

# 1. Create a company and contact for our example
puts "\n1. Creating sample company and contact..."
company = client.records.create(
  object: "companies",
  data: {
    name: "TechCorp Solutions",
    domain: "techcorp.example.com",
    industry: "Software Development",
  }
)
puts "   ✓ Created company: #{company.dig('data', 'values', 'name', 0, 'value')}"

contact = client.records.create(
  object: "people",
  data: {
    name: "Sarah Johnson",
    email: "sarah@techcorp.example.com",
    title: "VP of Engineering",
  }
)
puts "   ✓ Created contact: #{contact.dig('data', 'values', 'name', 0, 'value')}"

company_id = company.dig("data", "id", "record_id")
contact_id = contact.dig("data", "id", "record_id")

# 2. Create a thread for discussion
puts "\n2. Creating a discussion thread..."
thread = client.threads.create(
  parent_object: "companies",
  parent_record_id: company_id,
  title: "Q1 2025 Contract Renewal Discussion",
  description: "Thread to track all discussions related to the Q1 2025 contract renewal"
)
thread_id = thread.dig("data", "id", "thread_id")
puts "   ✓ Created thread: #{thread.dig('data', 'title')}"

# 3. Add comments to the thread
puts "\n3. Adding comments to the thread..."
client.comments.create(
  thread_id: thread_id,
  content: "Initial meeting scheduled for next Monday. Key topics:\n\n" \
           "- Review current usage metrics\n" \
           "- Discuss expansion opportunities\n" \
           "- Address any concerns"
)
puts "   ✓ Added initial comment"

comment2 = client.comments.create(
  thread_id: thread_id,
  content: "Sarah confirmed attendance. She mentioned interest in our new API features."
)
puts "   ✓ Added follow-up comment"

# 4. React to a comment
puts "\n4. Adding reactions to comments..."
client.comments.react(id: comment2.dig("data", "id", "comment_id"), emoji: "👍")
puts "   ✓ Added 👍 reaction"

# 5. Create tasks
puts "\n5. Creating tasks..."
task1 = client.tasks.create(
  parent_object: "companies",
  parent_record_id: company_id,
  title: "Prepare renewal proposal",
  due_date: (Date.today + 7).iso8601,
  description: "Create comprehensive renewal proposal including pricing and new features"
)
puts "   ✓ Created task: #{task1.dig('data', 'title')}"

task2 = client.tasks.create(
  parent_object: "people",
  parent_record_id: contact_id,
  title: "Schedule follow-up call",
  due_date: (Date.today + 14).iso8601
)
puts "   ✓ Created task: #{task2.dig('data', 'title')}"

# 6. Create meeting notes
puts "\n6. Creating meeting notes..."
client.notes.create(
  parent_object: "companies",
  parent_record_id: company_id,
  title: "Contract Renewal Meeting - #{Date.today}",
  content: <<~CONTENT
    ## Attendees
    - Sarah Johnson (TechCorp)
    - Our team: Sales, Customer Success

    ## Key Points Discussed
    1. Current contract value: $50,000/year
    2. Usage has grown 40% in last quarter
    3. Interest in API expansion package

    ## Action Items
    - [ ] Send updated pricing proposal by EOW
    - [ ] Schedule technical demo for API features
    - [ ] Review SLA requirements

    ## Next Steps
    Follow-up call scheduled for next week
  CONTENT
)
puts "   ✓ Created meeting notes"

# 7. List all collaboration items
puts "\n7. Listing collaboration items..."

# List threads
threads = client.threads.list(
  parent_object: "companies",
  parent_record_id: company_id
)
puts "   Threads on company: #{threads['data']&.length || 0}"

# List comments in thread
comments = client.comments.list(thread_id: thread_id)
puts "   Comments in thread: #{comments['data']&.length || 0}"

# List tasks
all_tasks = client.tasks.list
puts "   Total tasks: #{all_tasks['data']&.length || 0}"

# List notes
notes = client.notes.list(
  parent_object: "companies",
  parent_record_id: company_id
)
puts "   Notes on company: #{notes['data']&.length || 0}"

# 8. Update task status
puts "\n8. Updating task status..."
client.tasks.complete(
  id: task1.dig("data", "id", "task_id"),
  completed_at: Time.now.iso8601
)
puts "   ✓ Marked task as complete"

# 9. Close the thread
puts "\n9. Closing the discussion thread..."
client.threads.close(id: thread_id)
puts "   ✓ Thread closed"

puts "\n#{'=' * 40}"
puts "Example completed successfully!"
puts "\nThis example demonstrated:"
puts "  • Creating and managing discussion threads"
puts "  • Adding comments and reactions"
puts "  • Creating and completing tasks"
puts "  • Creating detailed meeting notes"
puts "  • Listing collaboration items"

# Clean up (optional - uncomment to delete created records)
# puts "\nCleaning up..."
# client.records.delete(object: "companies", id: company_id)
# client.records.delete(object: "people", id: contact_id)
# puts "   ✓ Cleanup complete"
