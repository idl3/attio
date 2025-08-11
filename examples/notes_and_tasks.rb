#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "attio"
require "date"

# Example demonstrating Notes and Tasks functionality
#
# This example shows how to:
# - Create and manage notes on records
# - Create and manage tasks
# - Work with task assignments and due dates
# - Track task completion

client = Attio.client(api_key: ENV.fetch("ATTIO_API_KEY"))

puts "📓 Attio Notes and Tasks Example"
puts "=" * 50

begin
  # First, find or create a person to work with
  puts "\n👤 Setting up test person..."
  test_person = client.records.create(
    object: "people",
    data: {
      name: "Jane Smith",
      email: "jane.smith@example.com",
      title: "Product Manager",
    }
  )
  person_id = test_person["data"]["id"]
  puts "  Created test person: Jane Smith (#{person_id})"

  # Working with Notes
  puts "\n📝 Creating Notes:"

  # Create a meeting note
  meeting_note = client.notes.create(
    parent_object: "people",
    parent_record_id: person_id,
    title: "Initial Meeting - Product Requirements",
    content: <<~MARKDOWN
      ## Meeting Summary
      **Date:** #{Date.today}
      **Attendees:** Jane Smith, Development Team

      ### Discussion Points:
      1. **Q1 Product Roadmap**
         - Feature A: User authentication improvements
         - Feature B: New dashboard design
         - Feature C: API v2 development

      2. **Timeline**
         - Sprint 1: Jan 15-29
         - Sprint 2: Jan 30-Feb 12
         - Release: Feb 15

      3. **Action Items**
         - [ ] Create detailed specs for Feature A
         - [ ] Schedule design review for Feature B
         - [ ] Allocate resources for API development

      ### Next Steps:
      Follow-up meeting scheduled for next week.
    MARKDOWN
  )
  puts "  ✅ Created meeting note: #{meeting_note['data']['title']}"

  # Create a follow-up note
  followup_note = client.notes.create(
    parent_object: "people",
    parent_record_id: person_id,
    title: "Follow-up: Action Items",
    content: "Confirmed timeline and resource allocation. Jane will provide detailed specs by EOW."
  )
  puts "  ✅ Created follow-up note"

  # List all notes for the person
  notes = client.notes.list(
    parent_object: "people",
    parent_record_id: person_id
  )
  puts "\n  📋 Notes for Jane Smith:"
  notes["data"].each do |note|
    puts "    - #{note['title']} (created: #{note['created_at']})"
  end

  # Working with Tasks
  puts "\n✅ Creating Tasks:"

  # Create tasks based on action items
  task1 = client.tasks.create(
    parent_object: "people",
    parent_record_id: person_id,
    title: "Create detailed specs for Feature A",
    description: "Write comprehensive specifications for the user authentication improvements",
    due_date: (Date.today + 7).iso8601,
    priority: 1,
    status: "pending"
  )
  puts "  ✅ Created task: #{task1['data']['title']}"

  task2 = client.tasks.create(
    parent_object: "people",
    parent_record_id: person_id,
    title: "Schedule design review for Feature B",
    description: "Coordinate with design team and schedule review meeting",
    due_date: (Date.today + 3).iso8601,
    priority: 2,
    status: "pending"
  )
  puts "  ✅ Created task: #{task2['data']['title']}"

  task3 = client.tasks.create(
    parent_object: "people",
    parent_record_id: person_id,
    title: "Allocate resources for API development",
    description: "Determine team members and timeline for API v2",
    due_date: (Date.today + 10).iso8601,
    priority: 3,
    status: "pending"
  )
  puts "  ✅ Created task: #{task3['data']['title']}"

  # List pending tasks
  puts "\n  📋 Pending Tasks:"
  pending_tasks = client.tasks.list(
    status: "pending",
    parent_object: "people",
    parent_record_id: person_id
  )
  pending_tasks["data"].each do |task|
    puts "    - #{task['title']} (due: #{task['due_date']})"
  end

  # Complete a task
  puts "\n  ✅ Completing task..."
  completed_task = client.tasks.complete(
    id: task2["data"]["id"],
    completed_at: DateTime.now.iso8601
  )
  puts "    Task completed: #{completed_task['data']['title']}"

  # Update a task
  puts "\n  📝 Updating task..."
  updated_task = client.tasks.update(
    id: task1["data"]["id"],
    description: "Updated: Include security requirements in the specifications",
    priority: 1
  )
  puts "    Task updated: #{updated_task['data']['title']}"

  # Get task details
  puts "\n  🔍 Task Details:"
  task_detail = client.tasks.get(id: task1["data"]["id"])
  puts "    Title: #{task_detail['data']['title']}"
  puts "    Description: #{task_detail['data']['description']}"
  puts "    Due Date: #{task_detail['data']['due_date']}"
  puts "    Status: #{task_detail['data']['status']}"

  # Update a note
  puts "\n  📝 Updating note..."
  client.notes.update(
    id: followup_note["data"]["id"],
    content: "Updated: Specs delivered. Design review scheduled for Friday."
  )
  puts "    Note updated successfully"

  # Cleanup
  puts "\n🧹 Cleaning up..."

  # Delete tasks
  [task1, task2, task3].each do |task|
    client.tasks.delete(id: task["data"]["id"])
  end
  puts "  ✅ Deleted tasks"

  # Delete notes
  [meeting_note, followup_note].each do |note|
    client.notes.delete(id: note["data"]["id"])
  end
  puts "  ✅ Deleted notes"

  # Delete test person
  client.records.delete(object: "people", id: person_id)
  puts "  ✅ Deleted test person"
rescue Attio::Error => e
  puts "❌ Error: #{e.message}"
  # Cleanup on error
  if defined?(person_id)
    begin
      client.records.delete(object: "people", id: person_id)
    rescue StandardError
      nil
    end
  end
end

puts "\n✨ Example completed!"
