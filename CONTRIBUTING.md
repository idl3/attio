# Contributing to Attio Ruby Client

Thank you for your interest in contributing to the Attio Ruby client! This guide will help you get started with contributing to the project.

## Table of Contents

- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [How to Contribute](#how-to-contribute)
- [Reporting Issues](#reporting-issues)
- [Submitting Pull Requests](#submitting-pull-requests)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Documentation](#documentation)
- [Release Process](#release-process)

## Getting Started

1. Fork the repository on GitHub
2. Clone your fork locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/attio.git
   cd attio
   ```
3. Add the upstream remote:
   ```bash
   git remote add upstream https://github.com/idl3/attio.git
   ```

## Development Setup

1. Install Ruby 3.0 or higher (tested with Ruby 3.0 - 3.4)
2. Install dependencies:
   ```bash
   bundle install
   ```
3. Run tests to verify setup:
   ```bash
   bundle exec rspec
   ```
4. Run linting:
   ```bash
   bundle exec rubocop
   ```

### Setting up API credentials for testing

Create a `.env` file in the project root:
```bash
ATTIO_API_KEY=your_test_api_key
```

## How to Contribute

### Finding Issues to Work On

- Check our [issue tracker](https://github.com/idl3/attio-ruby/issues) for open issues
- Look for issues labeled `good first issue` or `help wanted`
- Comment on an issue to let others know you're working on it

### Creating New Features

1. Open an issue to discuss the feature before starting work
2. Wait for maintainer feedback and approval
3. Follow the pull request process below

## Reporting Issues

### Bug Reports

When reporting bugs, please include:
- Ruby version (`ruby -v`)
- Gem version
- Minimal code example that reproduces the issue
- Full error messages and stack traces
- Expected vs actual behavior

Use our [bug report template](.github/ISSUE_TEMPLATE/bug_report.md) when creating issues.

### Feature Requests

For feature requests:
- Clearly describe the problem you're trying to solve
- Provide use cases and examples
- Explain why this would benefit other users

Use our [feature request template](.github/ISSUE_TEMPLATE/feature_request.md).

## Submitting Pull Requests

### Before Submitting

1. Create a feature branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Make your changes following our coding standards

3. Write or update tests for your changes

4. Update documentation if needed

5. Run the test suite:
   ```bash
   bundle exec rspec
   bundle exec rubocop
   ```

6. Update CHANGELOG.md with your changes under "Unreleased"

### Commit Messages

We use [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` New features
- `fix:` Bug fixes
- `docs:` Documentation changes
- `style:` Code style changes (formatting, etc.)
- `refactor:` Code refactoring
- `test:` Test additions or changes
- `chore:` Maintenance tasks
- `perf:` Performance improvements

Examples:
```
feat: add batch operations support for records
fix: handle rate limit errors correctly
docs: update README with pagination examples
```

### Pull Request Process

1. Push your branch to your fork:
   ```bash
   git push origin feature/your-feature-name
   ```

2. Create a pull request from your fork to the main repository

3. Fill out the PR template completely

4. Wait for automated checks to pass

5. Address any review feedback

6. Once approved, a maintainer will merge your PR

## Coding Standards

### Ruby Style Guide

We use RuboCop to enforce style guidelines. Key points:

- Use 2 spaces for indentation
- Maximum line length of 120 characters
- Use descriptive variable and method names
- Prefer symbols over strings for hash keys
- Use guard clauses to reduce nesting

### Code Organization

- Keep classes focused and single-purpose
- Extract complex logic into private methods
- Use modules for shared behavior
- Place one class per file

### Error Handling

- Create specific error classes for different error types
- Include helpful error messages
- Preserve original error context when re-raising

## Testing

### Writing Tests

- Write tests for all new functionality
- Maintain test coverage above 85%
- Use descriptive test names
- Test both success and failure cases
- Use fixtures for API response data

### Test Structure

```ruby
RSpec.describe Attio::Resources::Records do
  describe '#list' do
    context 'with valid parameters' do
      it 'returns a list of records' do
        # test implementation
      end
    end
    
    context 'with invalid parameters' do
      it 'raises an appropriate error' do
        # test implementation
      end
    end
  end
end
```

### Running Tests

```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/attio/resources/records_spec.rb

# Run with coverage report
COVERAGE=true bundle exec rspec
```

## Documentation

### Code Documentation

- Document all public methods with YARD
- Include parameter types and return values
- Add usage examples for complex methods
- Keep documentation up-to-date with code changes

Example:
```ruby
# Creates a new record in Attio
#
# @param object [String] The object type (e.g., 'people', 'companies')
# @param attributes [Hash] The record attributes
# @return [Hash] The created record
# @raise [Attio::InvalidRequestError] if parameters are invalid
#
# @example Create a person
#   client.records.create(
#     object: 'people',
#     attributes: { name: 'John Doe', email: 'john@example.com' }
#   )
def create(object:, attributes:)
  # implementation
end
```

### README Updates

Update the README when:
- Adding new features
- Changing API interfaces
- Adding configuration options
- Updating requirements

## Release Process

Releases are managed by maintainers. The process:

1. Update version in `lib/attio/version.rb`
2. Update CHANGELOG.md with release notes
3. Create a git tag: `git tag v1.2.3`
4. Push tag to trigger release workflow: `git push origin v1.2.3`
5. GitHub Actions will automatically:
   - Run tests
   - Build the gem
   - Publish to RubyGems
   - Create GitHub release

## Getting Help

- Join our [discussions](https://github.com/idl3/attio-ruby/discussions)
- Check existing issues and PRs
- Reach out to maintainers if needed

## Recognition

Contributors will be recognized in:
- CHANGELOG.md for their contributions
- GitHub's contributor graph
- Release notes when applicable

Thank you for contributing to the Attio Ruby client!