# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0] - 2025-08-11

### Added
- **Workspace Members** resource for managing workspace access and permissions
- **Deals** resource for sales pipeline management with win/loss tracking
- **Meta API** resource for workspace identification and usage statistics
- **Bulk Operations** with automatic batching (100 records per batch)
- **Rate Limiting** with exponential backoff and request queuing
- **SSL/TLS verification** for enhanced security
- **Enhanced error classes** with proper attributes (retry_after for RateLimitError)
- **Thread-safe rate limiter** implementation
- Comprehensive architectural documentation in CONCEPTS.md
- Development guidelines in CLAUDE.md
- 116 new tests (392 total, up from 265)

### Improved
- **Security**: Added explicit SSL verification and disabled automatic redirects
- **Thread Safety**: Fixed race conditions in rate limiter
- **Code Quality**: Achieved 0 RuboCop violations (previously 6)
- **Test Coverage**: 99.86% (718/719 lines)
- **Performance**: Optimized bulk operations with efficient batching
- **Validation**: Enhanced input validation to prevent injection attacks
- **Documentation**: Updated README with comprehensive API coverage

### Fixed
- Thread safety issues in RateLimiter#update_from_headers
- Complex validation methods refactored to reduce cyclomatic complexity
- validate_required_hash now properly handles nil values
- Removed unused api_key parameter from Meta#validate_key
- Fixed conditional validation in Deals#create

### Changed
- **BREAKING**: Error messages for nil validation now say "must be a hash" instead of "is required"
- RateLimitMiddleware simplified to avoid private method calls
- Base resource class validation methods extracted for reusability

## [0.2.0] - 2025-08-11

### Added
- Comments resource with full CRUD operations and emoji reactions
- Threads resource with participant management and status control
- Tasks resource with assignment and completion tracking
- Notes resource for creating and managing notes on records
- DELETE with body support in HttpClient for participant management
- URL encoding for emoji reactions using CGI.escape
- Comprehensive examples for collaboration features
- Advanced filtering and querying examples
- Complete CRM workflow example

### Improved
- Achieved 100% test coverage (376/376 lines)
- Increased test count from 147 to 265 tests
- Refactored Base class to reduce code duplication across resources
- Extracted common validation methods to base class
- Standardized error messages across all resources
- Fixed keyword arguments vs options hash issues in test mocks
- Updated README with all new features and comprehensive examples

### Fixed
- Semantic correctness in all test files
- REST convention compliance for DELETE operations
- Proper URL encoding for special characters in API paths

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