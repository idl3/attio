# Claude Development Guidelines for Attio Ruby Gem

This document contains important guidelines for Claude (or any AI assistant) when working on the Attio Ruby gem. Following these guidelines ensures high-quality, consistent, and production-ready code.

## Pre-Release Checklist

**IMPORTANT**: Before creating any release tag or pushing to master, ALWAYS complete this checklist:

### 1. Code Quality
- [ ] Run RuboCop and fix all violations: `bundle exec rubocop -A`
- [ ] Ensure no RuboCop offenses remain
- [ ] Run all tests: `bundle exec rspec`
- [ ] Verify 100% test coverage: Check SimpleCov output
- [ ] Update version in `lib/attio/version.rb`
- [ ] Update CHANGELOG.md with release date

### 2. Testing Commands
```bash
# Run all tests
bundle exec rspec

# Run tests with coverage report
COVERAGE=true bundle exec rspec

# Run specific test file
bundle exec rspec spec/attio/resources/comments_spec.rb

# Run RuboCop
bundle exec rubocop

# Auto-fix RuboCop violations
bundle exec rubocop -A

# Check for outdated gems
bundle outdated
```

### 3. Documentation
- [ ] Update README.md with new features
- [ ] Add/update YARD documentation for new methods
- [ ] Create example files for new features
- [ ] Update API coverage section in README
- [ ] Ensure all public methods have proper documentation

### 4. Git Commit Standards

#### Commit Message Format
```
<type>: <subject>

<body>

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

#### Commit Types
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only changes
- `style`: Code style changes (formatting, missing semi-colons, etc)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks
- `ci`: CI/CD changes

#### Examples
```bash
git commit -m "feat: Add Comments resource with emoji reactions

- Implement full CRUD operations for comments
- Add support for emoji reactions with proper URL encoding
- Include comprehensive test coverage

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

## Development Guidelines

### 1. Test-Driven Development (TDD)
- Write tests FIRST before implementing features
- Ensure semantic correctness in all tests
- Use `instance_double` for type safety in RSpec
- Mock external API calls appropriately
- Achieve and maintain 100% test coverage

### 2. Code Organization
```
lib/attio/
├── resources/
│   ├── base.rb          # Base class with common functionality
│   ├── comments.rb      # Resource-specific implementation
│   └── ...
├── client.rb            # Main client class
├── http_client.rb       # HTTP handling
├── errors.rb           # Error classes
└── version.rb          # Version constant

spec/attio/
├── resources/          # Resource-specific tests
├── client_spec.rb      # Client tests
└── http_client_spec.rb # HTTP client tests
```

### 3. Resource Implementation Pattern

When implementing a new resource:

```ruby
# lib/attio/resources/new_resource.rb
module Attio
  module Resources
    class NewResource < Base
      def list(params = {})
        # Implementation
      end

      def get(id:)
        validate_id!(id, "NewResource")
        # Implementation
      end

      def create(data:)
        validate_required_hash!(data, "Data")
        # Implementation
      end

      def update(id:, data:)
        validate_id!(id, "NewResource")
        validate_required_hash!(data, "Data")
        # Implementation
      end

      def delete(id:)
        validate_id!(id, "NewResource")
        # Implementation
      end
    end
  end
end
```

### 4. Testing Pattern

```ruby
# spec/attio/resources/new_resource_spec.rb
RSpec.describe Attio::Resources::NewResource do
  let(:connection) { instance_double(Attio::HttpClient) }
  let(:resource) { described_class.new(connection) }

  describe "#list" do
    it "lists all resources" do
      expect(connection).to receive(:get)
        .with("new_resources", {})
        .and_return({ "data" => [] })
      
      result = resource.list
      expect(result).to eq({ "data" => [] })
    end
  end

  # Test all methods with edge cases
end
```

### 5. Error Handling
- Always validate required parameters
- Use specific error classes (ValidationError, NotFoundError, etc.)
- Provide clear, actionable error messages
- Include parameter names in error messages

### 6. API Design Principles
- Use keyword arguments for clarity
- Support optional parameters with defaults
- Return full API response (don't extract data)
- Maintain consistency across all resources

## Common Pitfalls to Avoid

### 1. Test Mocks
```ruby
# WRONG - Using keyword arguments in mock
expect(connection).to receive(:get).with("comments", thread_id: "123")

# CORRECT - Using hash as second argument
expect(connection).to receive(:get).with("comments", { thread_id: "123" })
```

### 2. URL Encoding
```ruby
# WRONG - Direct string interpolation
"comments/#{id}/reactions/#{emoji}"

# CORRECT - Proper encoding for special characters
"comments/#{id}/reactions/#{CGI.escape(emoji)}"
```

### 3. Validation
```ruby
# WRONG - No validation
def get(id:)
  request(:get, "resources/#{id}")
end

# CORRECT - Validate required parameters
def get(id:)
  validate_id!(id, "Resource")
  request(:get, "resources/#{id}")
end
```

## Release Process

### 1. Pre-Release
```bash
# 1. Ensure all tests pass
bundle exec rspec

# 2. Check RuboCop
bundle exec rubocop

# 3. Update version
# Edit lib/attio/version.rb

# 4. Update CHANGELOG
# Add release section with date

# 5. Commit changes
git add -A
git commit -m "chore: Prepare release v0.2.0"
```

### 2. Create Release
```bash
# 1. Push to master
git push origin master

# 2. Create and push tag
git tag -a v0.2.0 -m "Release v0.2.0"
git push origin v0.2.0
```

### 3. Post-Release
The CI/CD pipeline will automatically:
- Run tests across Ruby 3.0-3.4
- Build the gem
- Publish to RubyGems (requires RUBYGEMS_AUTH_TOKEN secret)
- Create GitHub release

## RuboCop Configuration

Key rules enforced:
- Line length: 120 characters
- Method length: 20 lines
- Class length: 250 lines
- Cyclomatic complexity: 10
- ABC metric: 17
- Use `dig` for nested hash access (except single argument)
- Prefer string interpolation over concatenation
- Use single quotes unless interpolation needed

## Environment Setup

### Ruby Version
- Minimum: Ruby 3.0
- Recommended: Ruby 3.4
- CI tests on: 3.0, 3.1, 3.2, 3.3, 3.4

### Bundler Version
- Use bundler 2.4.22 for compatibility
- Set in CI: `gem install bundler -v 2.4.22`

### Development Dependencies
```ruby
# Gemfile
group :development, :test do
  gem "rspec", "~> 3.13"
  gem "rubocop", "~> 1.50"
  gem "rubocop-rspec", "~> 2.22"
  gem "simplecov", "~> 0.22"
  gem "webmock", "~> 3.18"
  gem "yard", "~> 0.9"
end
```

## API Coverage Tracking

Maintain this list in README.md:

### Core Resources
- [x] Records - Full CRUD
- [x] Objects - List, Get
- [x] Lists - List, Get, Entries, Create/Delete Entry
- [x] Comments - Full CRUD, Reactions
- [x] Threads - Full CRUD, Participants, Status
- [x] Tasks - Full CRUD, Assignment, Completion
- [x] Notes - Full CRUD
- [x] Workspaces - List, Get
- [x] Attributes - List, Create, Update
- [x] Users - List, Get
- [x] Deals - Full CRUD, Win/Loss tracking
- [x] Workspace Members - Management, Invitations
- [x] Meta API - Identify, Validate, Usage Stats
- [x] Bulk Operations - Batch operations with automatic batching

### Enterprise Features
- [x] Enhanced Client - Production-ready client
- [x] Connection Pooling - Thread-safe pool management
- [x] Circuit Breaker - Fault tolerance pattern
- [x] Observability - Metrics and tracing (StatsD, Datadog, Prometheus, OpenTelemetry)
- [x] Webhooks - Signature verification and event handling
- [x] Middleware - Request/response instrumentation

## Quality Metrics to Maintain

- **Test Coverage**: 100% (1311/1311 lines) ✅ ACHIEVED
- **Test Count**: 590 tests ✅ ACHIEVED
- **RuboCop Offenses**: 0 ✅ ACHIEVED
- **Documentation Coverage**: 100% for public methods
- **Example Coverage**: Example for each major feature including enterprise features

## Final Reminders

1. **NEVER** push code with failing tests
2. **NEVER** push code with RuboCop violations
3. **ALWAYS** update documentation with new features
4. **ALWAYS** maintain 100% test coverage
5. **ALWAYS** run the full test suite before committing
6. **ALWAYS** update the version and CHANGELOG for releases
7. **NEVER** create git commits without the co-author attribution

## Useful Commands Reference

```bash
# Build gem locally
gem build attio.gemspec

# Install gem locally
gem install ./attio-0.2.0.gem

# Test gem in IRB
irb -r attio

# Generate YARD documentation
bundle exec yard doc

# View YARD documentation
bundle exec yard server

# Run specific test with line number
bundle exec rspec spec/attio/resources/comments_spec.rb:42

# Check test coverage details
open coverage/index.html

# List all rake tasks
bundle exec rake -T
```

## Contact for Issues

If you encounter any issues or need clarification:
1. Check existing issues on GitHub
2. Review test files for usage examples
3. Consult the API documentation
4. Create a detailed issue with reproduction steps

---

**Remember**: Quality over speed. It's better to take time and deliver production-ready code than to rush and create technical debt.