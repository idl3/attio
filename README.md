# Attio Ruby Client

[![Development Status](https://img.shields.io/badge/status-beta-yellow.svg)](https://github.com/idl3/attio)
[![Tests](https://github.com/idl3/attio/actions/workflows/tests.yml/badge.svg)](https://github.com/idl3/attio/actions/workflows/tests.yml)
[![Test Coverage](https://img.shields.io/badge/coverage-99.86%25-brightgreen.svg)](https://github.com/idl3/attio/tree/master/spec)
[![Documentation](https://img.shields.io/badge/docs-yard-blue.svg)](https://idl3.github.io/attio)
[![Gem Version](https://badge.fury.io/rb/attio.svg)](https://badge.fury.io/rb/attio)
[![RSpec](https://img.shields.io/badge/RSpec-768_tests-green.svg)](https://github.com/idl3/attio/tree/master/spec)

Ruby client for the [Attio CRM API](https://developers.attio.com/). This library provides easy access to the Attio API, allowing you to manage records, objects, lists, and more.

## ⚠️ Development Status Warning

**This gem is in active development and is NOT recommended for production use until version 1.0.0 is released.**

- **Current Version**: 0.5.0 (Beta)
- **Stability**: API may change between minor versions
- **Production Ready**: Expected at v1.0.0
- **Use at Your Own Risk**: While we have comprehensive tests, this gem is still evolving

If you choose to use this gem before v1.0.0:
- Pin to a specific version in your Gemfile
- Review the CHANGELOG carefully before upgrading
- Test thoroughly in your staging environment
- Be prepared for potential breaking changes

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

# List with filtering and sorting
filtered_people = client.records.list(
  object: 'people',
  filter: {
    name: { $contains: 'John' }
  },
  sort: 'created_at.desc',
  limit: 50,
  offset: 0
)

# List all records with automatic pagination
client.records.list_all(object: 'people', page_size: 50).each do |person|
  puts person['name']
end
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

#### Objects (including Custom Objects)

```ruby
# List all object types
objects = client.objects.list

# Get a specific object schema
people_object = client.objects.get(id_or_slug: 'people')

# Create a custom object
custom_object = client.objects.create(
  api_slug: 'projects',
  singular_noun: 'Project',
  plural_noun: 'Projects'
)

# Update a custom object
client.objects.update(
  id_or_slug: 'projects',
  plural_noun: 'Active Projects'
)

# Update multiple fields
client.objects.update(
  id_or_slug: 'projects',
  api_slug: 'active_projects',
  singular_noun: 'Active Project',
  plural_noun: 'Active Projects'
)

# NOTE: The Attio API v2.0.0 does not currently support deleting custom objects
# Calling delete/destroy will raise NotImplementedError with instructions
# To delete objects, use: Settings > Data Model > Objects in the Attio UI
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

# Get a specific user by ID
user = client.users.get(id: 'user-123')
```

#### Meta (Token & Workspace Info)

```ruby
# Get current token and workspace information
meta = client.meta.identify
# => { "data" => { "active" => true, "workspace_name" => "My Workspace", ... } }

# Check if token is active
if client.meta.active?
  puts "Token is valid and active"
end

# Get workspace details
workspace = client.meta.workspace
# => { "id" => "...", "name" => "My Workspace", "slug" => "my-workspace" }

# Check permissions
if client.meta.permission?("record_permission:read-write")
  puts "Can read and write records"
end

# Get all permissions
permissions = client.meta.permissions
# => ["comment:read-write", "list_configuration:read", ...]
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

## Enterprise Features

The gem includes advanced enterprise features for production use:

### Enhanced Client

The `EnhancedClient` provides production-ready features including connection pooling, circuit breaker, observability, and webhook support:

```ruby
# Create an enhanced client with all features
client = Attio.enhanced_client(
  api_key: ENV['ATTIO_API_KEY'],
  connection_pool: {
    size: 10,      # Pool size
    timeout: 5     # Checkout timeout
  },
  circuit_breaker: {
    threshold: 5,   # Failures before opening
    timeout: 30,    # Recovery timeout in seconds
    half_open_requests: 2
  },
  instrumentation: {
    logger: Rails.logger,
    metrics: :datadog,  # or :statsd, :prometheus, :opentelemetry
    traces: :datadog    # or :opentelemetry
  },
  webhook_secret: ENV['ATTIO_WEBHOOK_SECRET']
)

# Use it like a regular client
records = client.records.list(object: 'people')

# Execute with circuit breaker protection
client.execute(endpoint: 'api/records') do
  client.records.create(object: 'people', data: { name: 'John' })
end

# Check health of all components
health = client.health_check
# => { api: true, pool: true, circuit_breaker: :healthy, rate_limiter: true }

# Verify API connectivity and token validity
if client.meta.active?
  puts "API connection healthy, token valid"
end

# Get statistics
stats = client.stats
# => { pool: { size: 10, available: 7 }, circuit_breaker: { state: :closed, requests: 100 } }
```

### Connection Pooling

Efficient connection management with thread-safe pooling:

```ruby
pool = Attio::ConnectionPool.new(size: 5, timeout: 2) do
  Attio::HttpClient.new(
    base_url: 'https://api.attio.com/v2',
    headers: { 'Authorization' => "Bearer #{api_key}" }
  )
end

# Use connections from the pool
pool.with do |connection|
  connection.get('records')
end

# Check pool status
stats = pool.stats
# => { size: 5, available: 3, allocated: 2 }

# Graceful shutdown
pool.shutdown
```

### Circuit Breaker

Fault tolerance with circuit breaker pattern:

```ruby
breaker = Attio::CircuitBreaker.new(
  threshold: 5,        # Open after 5 failures
  timeout: 30,         # Reset after 30 seconds
  half_open_requests: 2
)

# Execute with protection
result = breaker.execute do
  risky_api_call
end

# Monitor state changes
breaker.on_state_change = ->(old_state, new_state) {
  puts "Circuit breaker: #{old_state} -> #{new_state}"
}

# Check current state
breaker.state  # => :closed, :open, or :half_open
breaker.stats  # => { requests: 100, failures: 2, success_rate: 0.98 }
```

### Observability

Comprehensive monitoring with multiple backend support:

```ruby
# Initialize with your preferred backend
instrumentation = Attio::Observability::Instrumentation.new(
  logger: Logger.new(STDOUT),
  metrics_backend: :datadog,  # :statsd, :prometheus, :memory
  trace_backend: :opentelemetry  # :datadog, :memory
)

# Record API calls
instrumentation.record_api_call(
  method: :post,
  path: '/records',
  duration: 0.125,
  status: 200
)

# Record rate limits
instrumentation.record_rate_limit(
  remaining: 450,
  limit: 500,
  reset_at: Time.now + 3600
)

# Record circuit breaker state changes
instrumentation.record_circuit_breaker(
  endpoint: 'api/records',
  old_state: :closed,
  new_state: :open
)

# Track pool statistics
instrumentation.record_pool_stats(
  size: 10,
  available: 7,
  allocated: 3
)
```

### Webhook Processing

Secure webhook handling with signature verification:

```ruby
# Initialize webhook handler
webhooks = Attio::Webhooks.new(secret: ENV['ATTIO_WEBHOOK_SECRET'])

# Register event handlers
webhooks.on('record.created') do |event|
  puts "New record: #{event.data['id']}"
end

webhooks.on_any do |event|
  puts "Event: #{event.type}"
end

# Process incoming webhook
begin
  event = webhooks.process(
    request.body.read,
    request.headers
  )
  render json: { status: 'ok' }
rescue Attio::Webhooks::InvalidSignatureError => e
  render json: { error: 'Invalid signature' }, status: 401
end

# Development webhook server
server = Attio::WebhookServer.new(port: 3001, secret: 'test_secret')
server.webhooks.on('record.created') do |event|
  puts "Received: #{event.inspect}"
end
server.start  # Starts WEBrick server for testing
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
- ✅ **Objects** - List, get, create and update custom objects
- ✅ **Lists** - List, get entries, manage list entries
- ✅ **Attributes** - List, create, update custom attributes
- ✅ **Workspaces** - List, get current workspace
- ✅ **Users** - List, get specific user
- ✅ **Meta** - Get token info, workspace details, and permissions (/v2/self endpoint)

### Collaboration Features
- ✅ **Comments** - CRUD operations, emoji reactions on records and threads
- ✅ **Threads** - CRUD operations, participant management, status control
- ✅ **Tasks** - CRUD operations, assignment, completion tracking
- ✅ **Notes** - CRUD operations on records

### Sales & CRM
- ✅ **Deals** - Pipeline management, stage tracking, win/loss tracking
- ✅ **Workspace Members** - Member management, invitations, permissions

### Advanced Features
- ✅ **Bulk Operations** - Batch create/update/delete with automatic batching (1000 items max)
- ✅ **Rate Limiting** - Intelligent retry with exponential backoff and request queuing

### Enterprise Features
- ✅ **Enhanced Client** - Production-ready client with pooling, circuit breaker, and observability
- ✅ **Connection Pooling** - Thread-safe connection management with configurable pool size
- ✅ **Circuit Breaker** - Fault tolerance with automatic recovery and state monitoring
- ✅ **Observability** - Metrics and tracing with StatsD, Datadog, Prometheus, OpenTelemetry support
- ✅ **Webhook Processing** - Secure webhook handling with HMAC signature verification
- ✅ **Middleware** - Request/response instrumentation for monitoring

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

The gem maintains 100% test coverage across all features:

```bash
# Run tests with coverage report
bundle exec rspec

# View detailed coverage report
open coverage/index.html
```

Current stats:
- **Test Coverage**: 99.86% (1474/1476 lines)
- **Test Count**: 768 tests
- **RuboCop**: 0 violations in production code


## Pending API Functionalities

The following Attio API endpoints are not yet implemented in this gem. Contributions are welcome!

### 🟢 Recently Implemented (v0.5.0)

The following critical endpoints were implemented in v0.5.0:

#### Records API ✅
- **Assert Record** (`PUT /v2/objects/{object}/records`) - Implemented via `client.records.assert`
- **Update with PUT** (`PUT /v2/objects/{object}/records/{record_id}`) - Implemented via `client.records.update_with_put`

#### Lists API ✅
- **Create List** (`POST /v2/lists`) - Implemented via `client.lists.create`
- **Update List** (`PATCH /v2/lists/{list}`) - Implemented via `client.lists.update`
- **Query Entries** (`POST /v2/lists/{list}/entries/query`) - Implemented via `client.lists.query_entries`
- **Assert Entry** (`PUT /v2/lists/{list}/entries`) - Implemented via `client.lists.assert_entry`
- **Update Entry** (`PATCH /v2/lists/{list}/entries/{entry}`) - Implemented via `client.lists.update_entry`

#### Attributes API ✅
- **Update Attribute** (`PATCH /v2/objects/{object}/attributes/{attribute}`) - Implemented via `client.attributes.update`
- **Select Options Management:**
  - List Options - Implemented via `client.attributes.list_options`
  - Create Option - Implemented via `client.attributes.create_option`
  - Update Option - Implemented via `client.attributes.update_option`
- **Status Management:**
  - List Statuses - Implemented via `client.attributes.list_statuses`
  - Create Status - Implemented via `client.attributes.create_status`
  - Update Status - Implemented via `client.attributes.update_status`

### 🔴 Still Missing Endpoints

#### Webhook Management API (Entire Resource Missing)
- **List Webhooks** (`GET /v2/webhooks`)
- **Create Webhook** (`POST /v2/webhooks`)
- **Get Webhook** (`GET /v2/webhooks/{webhook_id}`)
- **Update Webhook** (`PATCH /v2/webhooks/{webhook_id}`)
- **Delete Webhook** (`DELETE /v2/webhooks/{webhook_id}`)

### 🟡 Advanced Features Not Implemented

#### Values API (Entire Resource Missing)
- Historic value tracking
- Value validation endpoints
- Format conversion utilities
- Computed values

#### Import/Export API
- Bulk data import endpoints
- Export jobs management
- Import mapping configuration

#### Analytics & Reporting
- Aggregation queries
- Report generation
- Dashboard metrics
- Activity analytics

#### Advanced Search
- Cross-object search
- Full-text search capabilities
- Saved search management

### 🟢 API Limitations (Not Supported by Attio)

These operations are not available via the API and must be done through the Attio UI:
- **Delete Custom Objects** - Must use Settings > Data Model > Objects
- **Delete Attributes** - Not supported via API
- **Webhook Configuration** (in some cases) - UI configuration required

### Implementation Status by Category

| Category | Coverage | Status |
|----------|----------|--------|
| **Records** | 100% | ✅ Complete with assert/PUT operations |
| **Objects** | 100% | ✅ Complete (API limitations noted) |
| **Lists** | 100% | ✅ Complete with all CRUD and query operations |
| **Attributes** | 100% | ✅ Complete with update and options/status management |
| **Comments** | 100%+ | ✅ Over-implemented vs. documented API |
| **Threads** | 100%+ | ✅ Over-implemented vs. documented API |
| **Tasks** | 100% | ✅ Complete |
| **Notes** | 100%+ | ✅ Over-implemented vs. documented API |
| **Webhooks** | 50% | ⚠️ Event handling only, missing management API |
| **Users** | 100% | ✅ Complete |
| **Workspace Members** | 100% | ✅ Complete |
| **Meta/Self** | 100% | ✅ Complete |
| **Deals** | 100% | ✅ Complete |
| **Bulk Operations** | 100% | ✅ Complete with batching |
| **Values** | 0% | ❌ Not implemented |
| **Analytics** | 0% | ❌ Not implemented |
| **Import/Export** | 0% | ❌ Not implemented |

### Notes for Contributors

1. **Authentication**: Some endpoints require specific scopes (e.g., `object_configuration:read-write`)
2. **Rate Limiting**: The gem includes rate limiting support for all new endpoints
3. **Testing**: Please add comprehensive tests for any new endpoints
4. **Documentation**: Update both inline YARD docs and README examples

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

