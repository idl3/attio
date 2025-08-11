# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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