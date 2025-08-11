# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.3] - 2025-08-11

### Fixed
- Ruby 3.0 and 3.1 compatibility by using bundler 2.4.22
- All CI workflows now explicitly specify compatible bundler version

## [0.1.2] - 2025-08-11 (yanked)

### Added
- Ruby 3.4 support in CI/CD pipelines
- GitHub Actions badges for tests and coverage
- Comprehensive documentation for all classes

### Improved
- Applied RuboCop with Stripe's best practices configuration
- Refactored HttpClient#handle_response to reduce cyclomatic complexity
- Fixed all code style violations (284 auto-corrected)
- Enhanced CI/CD workflows with proper bundler configuration

### Removed
- Unnecessary test files (test_basic.rb, test_typhoeus.rb, run_tests.rb)
- .rubocop_todo.yml (all violations fixed)

## [0.1.1] - 2025-08-11

### Changed
- Updated gem description to remove "Official" designation

## [0.1.0] - 2025-08-11 - Initial Release (yanked)

### Added
- Initial implementation of Attio Ruby client
- Support for all major Attio API endpoints:
  - Records (CRUD operations, querying)
  - Objects (list, get schema)  
  - Lists (list, get entries)
  - Workspaces (list, get current)
  - Attributes (list, create, update)
  - Users (list, get current user)
- Comprehensive error handling
- Connection pooling and retry logic
- Full test suite with RSpec
- Code coverage reporting

### Documentation
- Complete API documentation with YARD
- Usage examples and guides
- Development setup instructions