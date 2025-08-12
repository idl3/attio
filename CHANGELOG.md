# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.5.0] - 2025-01-12

### Added
- **Custom Objects Support**: Create and update operations for custom objects
  - Create custom objects with `client.objects.create(api_slug:, singular_noun:, plural_noun:)`
  - Update custom objects with `client.objects.update(id_or_slug:, ...)`
  - Delete method raises `NotImplementedError` with helpful message directing to Attio UI
  - Proper validation and error handling for all operations
  - Comprehensive test coverage with 28 new test cases

### Improved
- Test coverage maintained at 99.86% (1392/1394 lines)
- Total test count increased to 658 tests

### Notes
- Delete operation for custom objects is not supported by the Attio API v2.0.0
- Users are directed to delete objects through Settings > Data Model > Objects in the Attio UI

## [0.4.0] - 2025-01-12

### Breaking Changes
- **Webhook Headers**: Fixed header names (removed X- prefix) - now uses `Attio-Signature` and `Attio-Timestamp`
- **Method Naming**: Renamed `has_permission?` to `permission?` in Meta resource (alias provided for backward compatibility)

### Added
- **Meta Resource**: Proper implementation of /v2/self endpoint for token and workspace information
  - Get token status and permissions with `client.meta.identify`
  - Check if token is active with `client.meta.active?`
  - Get workspace details with `client.meta.workspace`
  - Check permissions with `client.meta.permission?("scope")`
  - Get token metadata with `client.meta.token_info`
- **Rate Limiter Integration**: Now actively enforces rate limits and handles 429 responses
- **Pagination Support**: Added automatic pagination with `list_all` methods
- **Filtering and Sorting**: Full support for Attio's filter and sort parameters
- **Enterprise Features**:
  - **EnhancedClient** with connection pooling, circuit breaker, observability, and webhook support
  - **CircuitBreaker** pattern for fault tolerance with configurable thresholds and timeouts
  - **ConnectionPool** for efficient connection management with thread-safe implementation
  - **Observability** framework with support for multiple backends (StatsD, Datadog, Prometheus, OpenTelemetry)
  - **Webhook** processing with signature verification and event handling
  - **Middleware** support for request/response instrumentation
- **Background thread error handling** for production stability

### Improved
- **Test Quality**: Achieved 99.85% code coverage (1373/1375 lines) with 638 tests
- **Error Handling**: Added graceful error messages and proper retry logic
- **Health Checks**: Now use real API endpoint (`/v2/self`) through Meta resource
- **HTTP Client**: Properly extracts and handles rate limit headers
- **Documentation**: All features properly tested and documented
- **RuboCop Compliance**: Fixed all violations, maintaining clean code standards

### Fixed
- Webhook signature verification headers (removed X- prefix)
- Health check endpoint to use real API through Meta resource
- Background thread error handling in EnhancedClient
- Rate limiter integration - now actually enforces limits
- Bulk operations validation (max is 1000, not 100)
- Invalid retry-after header handling
- RuboCop naming convention violations

## [0.3.0] - 2025-08-11

### Added
- **Workspace Members** resource for managing workspace access and permissions
- **Deals** resource for sales pipeline management with win/loss tracking
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