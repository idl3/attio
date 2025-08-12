# Meta Resource Implementation Plan

## Overview
The Meta resource provides information about the current API token, workspace, and permissions. According to the official Attio OpenAPI specification, there is only ONE Meta endpoint.

## API Endpoint
- **GET /v2/self** - Identify the current access token and workspace information

## Response Schema

### When token is active:
```json
{
  "active": true,
  "scope": "space-separated list of permissions",
  "client_id": "OAuth app ID",
  "token_type": "Bearer",
  "exp": null or timestamp,
  "iat": timestamp,
  "sub": "workspace_id",
  "aud": "same as client_id",
  "iss": "attio.com",
  "authorized_by_workspace_member_id": "member_id or null",
  "workspace_id": "uuid",
  "workspace_name": "Workspace Name",
  "workspace_slug": "workspace-slug",
  "workspace_logo_url": "url or null"
}
```

### When token is inactive:
```json
{
  "active": false
}
```

## Implementation Details

### 1. Meta Resource Class (`lib/attio/resources/meta.rb`)

```ruby
module Attio
  module Resources
    class Meta < Base
      # Get information about the current access token and workspace
      # @return [Hash] Token and workspace information
      def identify
        request(:get, "self")
      end
      
      # Alias for backward compatibility and clarity
      alias_method :self, :identify
      alias_method :get, :identify
      
      # Check if the current token is active
      # @return [Boolean] true if token is active
      def active?
        response = identify
        response.dig("data", "active") || false
      end
      
      # Get the workspace information
      # @return [Hash, nil] Workspace details or nil if token inactive
      def workspace
        response = identify
        return nil unless response.dig("data", "active")
        
        {
          "id" => response.dig("data", "workspace_id"),
          "name" => response.dig("data", "workspace_name"),
          "slug" => response.dig("data", "workspace_slug"),
          "logo_url" => response.dig("data", "workspace_logo_url")
        }
      end
      
      # Get the token's permissions/scopes
      # @return [Array<String>] List of permission scopes
      def permissions
        response = identify
        scope = response.dig("data", "scope") || ""
        scope.split(" ")
      end
      
      # Check if token has a specific permission
      # @param permission [String] The permission to check
      # @return [Boolean] true if permission is granted
      def has_permission?(permission)
        permissions.include?(permission)
      end
      
      # Get token expiration information
      # @return [Hash] Expiration details
      def token_info
        response = identify
        return { "active" => false } unless response.dig("data", "active")
        
        {
          "active" => true,
          "type" => response.dig("data", "token_type"),
          "expires_at" => response.dig("data", "exp"),
          "issued_at" => response.dig("data", "iat"),
          "client_id" => response.dig("data", "client_id"),
          "authorized_by" => response.dig("data", "authorized_by_workspace_member_id")
        }
      end
    end
  end
end
```

### 2. Spec File (`spec/attio/resources/meta_spec.rb`)

Tests needed:
1. `#identify` - Returns full token and workspace info
2. `#active?` - Returns true for active tokens, false for inactive
3. `#workspace` - Returns workspace details or nil
4. `#permissions` - Returns array of permission strings
5. `#has_permission?` - Checks specific permissions
6. `#token_info` - Returns token metadata
7. Error handling for network issues
8. Caching behavior (if implemented)

### 3. Integration Points

1. **Client class** - Add meta resource accessor:
```ruby
def meta
  @meta ||= Resources::Meta.new(@connection)
end
```

2. **Health checks** - Can use meta.active? for health verification
3. **Permission checks** - Before operations, can verify permissions
4. **Workspace context** - Get workspace info for context

## Features to Implement

### Core Features (Required)
- [x] GET /v2/self endpoint
- [ ] Response parsing and validation
- [ ] Active token detection
- [ ] Workspace information extraction
- [ ] Permission/scope parsing

### Enhanced Features (Nice to have)
- [ ] Response caching (with TTL)
- [ ] Permission validation helpers
- [ ] Token expiration warnings
- [ ] Automatic token refresh detection
- [ ] Workspace switching support (if multiple workspaces)

## Testing Strategy

### Unit Tests
- Mock API responses for active/inactive tokens
- Test all helper methods
- Test error conditions
- Test edge cases (null values, missing fields)

### Integration Tests
- Test against real API
- Verify response schema matches OpenAPI spec
- Test with different token types/permissions
- Performance testing for caching

## Documentation

### README Example
```ruby
# Get token and workspace information
meta = client.meta.identify
puts "Workspace: #{meta['data']['workspace_name']}"
puts "Permissions: #{meta['data']['scope']}"

# Check if token is active
if client.meta.active?
  puts "Token is valid"
end

# Get workspace details
workspace = client.meta.workspace
puts "Working in: #{workspace['name']} (#{workspace['id']})"

# Check permissions
if client.meta.has_permission?("record_permission:read-write")
  # Can read and write records
end
```

## Migration Notes

Since we previously had a fake Meta implementation that was removed, we should:
1. Note this is a REAL implementation based on actual API
2. Document the breaking changes (different response format)
3. Provide migration guide for users of the old fake implementation

## Success Criteria

1. ✅ Implements the single Meta endpoint from OpenAPI spec
2. ✅ Provides helpful utility methods for common use cases
3. ✅ 100% test coverage
4. ✅ Works with production API
5. ✅ Properly documented with examples
6. ✅ Follows gem's coding standards and patterns