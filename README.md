# Attio Ruby Client

[![Tests](https://github.com/idl3/attio/actions/workflows/tests.yml/badge.svg)](https://github.com/idl3/attio/actions/workflows/tests.yml)
[![Test Coverage](https://img.shields.io/badge/coverage-100%25-brightgreen.svg)](https://github.com/idl3/attio/tree/master/spec)
[![Documentation](https://img.shields.io/badge/docs-yard-blue.svg)](https://idl3.github.io/attio)
[![Gem Version](https://badge.fury.io/rb/attio.svg)](https://badge.fury.io/rb/attio)
[![RSpec](https://img.shields.io/badge/RSpec-392_tests-green.svg)](https://github.com/idl3/attio/tree/master/spec)

Ruby client for the [Attio CRM API](https://developers.attio.com/). This library provides easy access to the Attio API, allowing you to manage records, objects, lists, and more.

## Requirements

- Ruby 3.0 or higher (tested with Ruby 3.0, 3.1, 3.2, 3.3, and 3.4)
- Bundler

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'attio'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install attio

## Quick Start

```ruby
require 'attio'

# Initialize the client with your API key
client = Attio.client(api_key: 'your-api-key-here')

# List people records
people = client.records.list(object: 'people', limit: 10)

# Create a new person
person = client.records.create(
  object: 'people',
  data: {
    name: 'Jane Doe',
    email: 'jane@example.com',
    phone: '+1-555-0123'
  }
)

# Get a specific person
person = client.records.get(object: 'people', id: person['id'])

# Update a person
updated_person = client.records.update(
  object: 'people',
  id: person['id'],
  data: { name: 'Jane Smith' }
)

# Delete a person
client.records.delete(object: 'people', id: person['id'])
```

## Usage

### Client Configuration

```ruby
# Basic client with default timeout (30 seconds)
client = Attio.client(api_key: 'your-api-key')

# Client with custom timeout
client = Attio::Client.new(api_key: 'your-api-key', timeout: 60)
```

### Working with Records

#### Listing Records

```ruby
# List all people
people = client.records.list(object: 'people')

# List with filters
filtered_people = client.records.list(
  object: 'people',
  filters: {
    name: { contains: 'John' },
    company: { target_object: 'companies', target_record_id: 'company-123' }
  },
  limit: 50
)

# List with sorting
sorted_people = client.records.list(
  object: 'people',
  sorts: [{ field: 'created_at', direction: 'desc' }],
  limit: 25
)
```

#### Creating Records

```ruby
# Create a person
person = client.records.create(
  object: 'people',
  data: {
    name: 'John Doe',
    email: 'john@example.com',
    phone: '+1-555-0123',
    company: {
      target_object: 'companies',
      target_record_id: 'company-123'
    }
  }
)

# Create a company
company = client.records.create(
  object: 'companies',
  data: {
    name: 'Acme Corp',
    domain: 'acme.com',
    industry: 'Technology'
  }
)
```

#### Updating Records

```ruby
# Update a person's email
client.records.update(
  object: 'people',
  id: 'person-123',
  data: { email: 'newemail@example.com' }
)

# Update multiple fields
client.records.update(
  object: 'people',
  id: 'person-123',
  data: {
    name: 'John Smith',
    phone: '+1-555-9999',
    notes: 'Updated contact information'
  }
)
```

### Working with Other Resources

#### Comments

```ruby
# List comments on a record
comments = client.comments.list(
  parent_object: 'people',
  parent_record_id: 'person-123'
)

# List comments in a thread
thread_comments = client.comments.list(thread_id: 'thread-456')

# Create a comment on a record
comment = client.comments.create(
  parent_object: 'people',
  parent_record_id: 'person-123',
  content: 'This is a comment with **markdown** support!'
)

# Create a comment in a thread
thread_comment = client.comments.create(
  thread_id: 'thread-456',
  content: 'Following up on this discussion'
)

# Update a comment
updated_comment = client.comments.update(
  id: 'comment-123',
  content: 'Updated comment content'
)

# React to a comment
client.comments.react(id: 'comment-123', emoji: '👍')

# Remove reaction
client.comments.unreact(id: 'comment-123', emoji: '👍')

# Delete a comment
client.comments.delete(id: 'comment-123')
```

#### Threads

```ruby
# List threads on a record
threads = client.threads.list(
  parent_object: 'companies',
  parent_record_id: 'company-123'
)

# Get a thread with comments
thread = client.threads.get(id: 'thread-123', include_comments: true)

# Create a thread
thread = client.threads.create(
  parent_object: 'companies',
  parent_record_id: 'company-123',
  title: 'Q4 Planning Discussion',
  description: 'Thread for Q4 planning discussions',
  participant_ids: ['user-1', 'user-2']
)

# Update thread title
client.threads.update(id: 'thread-123', title: 'Updated Q4 Planning')

# Manage participants
client.threads.add_participants(id: 'thread-123', user_ids: ['user-3', 'user-4'])
client.threads.remove_participants(id: 'thread-123', user_ids: ['user-2'])

# Close and reopen threads
client.threads.close(id: 'thread-123')
client.threads.reopen(id: 'thread-123')

# Delete a thread
client.threads.delete(id: 'thread-123')
```

#### Tasks

```ruby
# List all tasks
tasks = client.tasks.list

# List tasks with filters
my_tasks = client.tasks.list(
  assignee_id: 'user-123',
  status: 'pending'
)

# Get a specific task
task = client.tasks.get(id: 'task-123')

# Create a task
task = client.tasks.create(
  parent_object: 'people',
  parent_record_id: 'person-123',
  title: 'Follow up with customer',
  due_date: '2025-02-01',
  assignee_id: 'user-456'
)

# Update a task
client.tasks.update(
  id: 'task-123',
  title: 'Updated task title',
  status: 'in_progress'
)

# Complete a task
client.tasks.complete(id: 'task-123', completed_at: Time.now.iso8601)

# Reopen a task
client.tasks.reopen(id: 'task-123')

# Delete a task
client.tasks.delete(id: 'task-123')
```

#### Notes

```ruby
# List notes on a record
notes = client.notes.list(
  parent_object: 'companies',
  parent_record_id: 'company-123'
)

# Get a specific note
note = client.notes.get(id: 'note-123')

# Create a note
note = client.notes.create(
  parent_object: 'companies',
  parent_record_id: 'company-123',
  title: 'Meeting Notes - Q4 Planning',
  content: 'Discussed roadmap and resource allocation...',
  tags: ['important', 'quarterly-planning']
)

# Update a note
client.notes.update(
  id: 'note-123',
  title: 'Updated Meeting Notes',
  content: 'Added action items from discussion'
)

# Delete a note
client.notes.delete(id: 'note-123')
```

#### Objects

```ruby
# List all object types
objects = client.objects.list

# Get a specific object schema
people_object = client.objects.get(id: 'people')
```

#### Lists

```ruby
# List all lists
lists = client.lists.list

# Get entries from a specific list
entries = client.lists.entries(id: 'list-123')
```

#### Workspaces

```ruby
# List workspaces
workspaces = client.workspaces.list

# Get current workspace
workspace = client.workspaces.get
```

#### Attributes

```ruby
# List attributes for an object
attributes = client.attributes.list(object: 'people')

# Create a custom attribute
attribute = client.attributes.create(
  object: 'people',
  data: {
    title: 'Custom Field',
    api_slug: 'custom_field',
    type: 'text'
  }
)
```

#### Users

```ruby
# List workspace users
users = client.users.list

# Get current user
user = client.users.me
```

### Advanced Features

#### Workspace Members

```ruby
# List workspace members
members = client.workspace_members.list

# Invite a new member
invitation = client.workspace_members.invite(
  email: 'new.member@example.com',
  role: 'member'  # admin, member, or guest
)

# Update member permissions
client.workspace_members.update(
  member_id: 'user-123',
  data: { role: 'admin' }
)

# Remove a member
client.workspace_members.remove(member_id: 'user-123')
```

#### Deals

```ruby
# List all deals
deals = client.deals.list

# Create a new deal
deal = client.deals.create(
  data: {
    name: 'Enterprise Contract',
    value: 50000,
    stage_id: 'stage-negotiation',
    company_id: 'company-123'
  }
)

# Update deal stage
client.deals.update_stage(id: 'deal-123', stage_id: 'stage-won')

# Mark deal as won/lost
client.deals.mark_won(id: 'deal-123', won_date: Date.today)
client.deals.mark_lost(id: 'deal-123', lost_reason: 'Budget constraints')

# List deals by various criteria
pipeline_deals = client.deals.list_by_stage(stage_id: 'stage-proposal')
company_deals = client.deals.list_by_company(company_id: 'company-123')
my_deals = client.deals.list_by_owner(owner_id: 'user-456')
```

#### Bulk Operations

```ruby
# Bulk create records
results = client.bulk.create_records(
  object: 'people',
  records: [
    { name: 'John Doe', email: 'john@example.com' },
    { name: 'Jane Smith', email: 'jane@example.com' },
    # ... up to 100 records per batch
  ]
)

# Bulk update records
results = client.bulk.update_records(
  object: 'companies',
  updates: [
    { id: 'company-1', data: { status: 'active' } },
    { id: 'company-2', data: { status: 'inactive' } }
  ]
)

# Bulk upsert (create or update based on matching)
results = client.bulk.upsert_records(
  object: 'people',
  match_attribute: 'email',
  records: [
    { email: 'john@example.com', name: 'John Updated' },
    { email: 'new@example.com', name: 'New Person' }
  ]
)
```

#### Rate Limiting

```ruby
# Initialize client with custom rate limiter
limiter = Attio::RateLimiter.new(
  max_requests: 100,
  window_seconds: 60,
  max_retries: 3
)
client.rate_limiter = limiter

# Execute with rate limiting
limiter.execute { client.records.list(object: 'people') }

# Queue requests for later processing
limiter.queue_request(priority: 1) { important_operation }
limiter.queue_request(priority: 5) { less_important_operation }

# Process queued requests
results = limiter.process_queue(max_per_batch: 10)

# Check rate limit status
status = limiter.status
puts "Remaining: #{status[:remaining]}/#{status[:limit]}"
```

#### Meta API

```ruby
# Identify current workspace and user
info = client.meta.identify
puts "Workspace: #{info['workspace']['name']}"
puts "User: #{info['user']['email']}"

# Validate API key
validation = client.meta.validate_key
puts "Valid: #{validation['valid']}"
puts "Permissions: #{validation['permissions']}"

# Get usage statistics
usage = client.meta.usage_stats
puts "Records: #{usage['records']['total']}"
puts "API calls today: #{usage['api_calls']['today']}"
```

### Error Handling

The client will raise appropriate exceptions for different error conditions:

```ruby
begin
  client.records.get(object: 'people', id: 'invalid-id')
rescue Attio::NotFoundError => e
  puts "Record not found: #{e.message}"
rescue Attio::AuthenticationError => e
  puts "Authentication failed: #{e.message}"
rescue Attio::RateLimitError => e
  puts "Rate limit exceeded. Retry after: #{e.retry_after}"
rescue Attio::APIError => e
  puts "API error: #{e.message}"
end
```

## Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `api_key` | String | Required | Your Attio API key |
| `timeout` | Integer | 30 | Request timeout in seconds |

## API Coverage

This client supports all major Attio API endpoints:

### Core Resources
- ✅ **Records** - Full CRUD operations, querying with filters and sorting
- ✅ **Objects** - List, get schema information
- ✅ **Lists** - List, get entries, manage list entries
- ✅ **Attributes** - List, create, update custom attributes
- ✅ **Workspaces** - List, get current workspace
- ✅ **Users** - List, get current user

### Collaboration Features
- ✅ **Comments** - CRUD operations, emoji reactions on records and threads
- ✅ **Threads** - CRUD operations, participant management, status control
- ✅ **Tasks** - CRUD operations, assignment, completion tracking
- ✅ **Notes** - CRUD operations on records

### Sales & CRM
- ✅ **Deals** - Pipeline management, stage tracking, win/loss tracking
- ✅ **Workspace Members** - Member management, invitations, permissions

### Advanced Features
- ✅ **Bulk Operations** - Batch create/update/delete with automatic batching
- ✅ **Rate Limiting** - Intelligent retry with exponential backoff and request queuing
- ✅ **Meta API** - Identify workspace, validate API keys, get usage stats

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

### Running Tests

```bash
bundle exec rspec
```

### Generating Documentation

```bash
# Generate YARD documentation
bundle exec rake docs:generate

# Open documentation in browser
bundle exec rake docs:open

# Serve documentation locally
bundle exec rake docs:serve
```

### Code Coverage

```bash
bundle exec rake coverage:report
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/idl3/attio.

1. Fork the repository
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Make your changes and add tests
4. Ensure all tests pass (`bundle exec rspec`)
5. Commit your changes (`git commit -am 'Add some feature'`)
6. Push to the branch (`git push origin my-new-feature`)
7. Create a new Pull Request

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Support

- 📖 [API Documentation](https://developers.attio.com/)
- 🐛 [Issues](https://github.com/idl3/attio/issues)
- 💬 [Discussions](https://github.com/idl3/attio/discussions)

