# Attio Ruby Client

[![Tests](https://github.com/idl3/attio/actions/workflows/tests.yml/badge.svg)](https://github.com/idl3/attio/actions/workflows/tests.yml)
[![Test Coverage](https://img.shields.io/badge/coverage-100%25-brightgreen.svg)](https://github.com/idl3/attio/tree/master/spec)
[![Documentation](https://img.shields.io/badge/docs-yard-blue.svg)](https://idl3.github.io/attio)
[![Gem Version](https://badge.fury.io/rb/attio.svg)](https://badge.fury.io/rb/attio)
[![RSpec](https://img.shields.io/badge/RSpec-147_tests-green.svg)](https://github.com/idl3/attio/tree/master/spec)

Ruby client for the [Attio CRM API](https://developers.attio.com/). This library provides easy access to the Attio API, allowing you to manage records, objects, lists, and more.

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

- ✅ Records (CRUD operations, querying)
- ✅ Objects (list, get schema)
- ✅ Lists (list, get entries)
- ✅ Workspaces (list, get current)
- ✅ Attributes (list, create, update)
- ✅ Users (list, get current user)

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

