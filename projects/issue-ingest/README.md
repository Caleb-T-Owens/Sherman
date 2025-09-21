# Issue Ingest - Project Architecture & Coding Patterns

## Overview

Issue Ingest is a modern Rails 8.0.2+ web application designed for managing GitHub repository issues. It follows Rails conventions with a clean, authentication-first architecture that manages user repositories and their associated GitHub tokens securely.

## Testing Philosophy & Development Ethos

**Every feature must have comprehensive system tests before it's considered complete.**

We prioritize system tests as our first line of defense against regressions. System tests validate the entire user experience from the browser through the database, ensuring that:

- **User workflows remain intact** - Every user-facing feature has end-to-end test coverage
- **Integration points don't break** - Tests verify that all layers work together correctly
- **Regressions are caught immediately** - No feature ships without automated verification
- **Refactoring is safe** - Comprehensive tests enable confident code improvements

### Testing Standards

1. **System Tests First**: Write system tests that cover the happy path and key edge cases for every feature
2. **User-Centric Scenarios**: Tests should mirror real user interactions, not implementation details
3. **Regression Prevention**: When fixing bugs, add a system test that reproduces the bug first
4. **Continuous Integration**: All tests must pass before merging any code
5. **Test Maintenance**: Keep tests readable, maintainable, and fast enough for rapid feedback

This test-driven approach ensures our application remains reliable and maintainable as it grows.

## Technology Stack

### Core Framework
- **Rails 8.0.2+** - Latest Rails version with modern defaults
- **Ruby 3.x** - Modern Ruby with performance optimizations
- **SQLite3** - Database for development/testing (production-ready with proper configuration)

### Frontend Stack
- **Hotwire Suite**:
  - **Turbo Rails** - SPA-like navigation without JavaScript complexity
  - **Stimulus Rails** - Modest JavaScript framework for HTML enhancements
  - **Import Maps** - Native ES6 modules without bundling complexity
- **Propshaft** - Modern asset pipeline replacing Sprockets
- **ERB Templates** - Server-side rendering with Rails view helpers

### Infrastructure & Operations
- **Puma** - High-performance web server
- **Kamal** - Docker deployment tooling
- **Thruster** - HTTP asset caching/compression layer
- **Solid Suite**:
  - **Solid Cache** - Database-backed caching
  - **Solid Queue** - Database-backed job processing
  - **Solid Cable** - Database-backed WebSockets

### Security & Quality
- **BCrypt** - Secure password hashing
- **Brakeman** - Static security analysis
- **Rubocop Rails Omakase** - Standardized Ruby style guide

## Core Architectural Patterns

### 1. Authentication Pattern

The application uses a **concern-based authentication system** (`Authentication` module) that provides:

- **Session-based authentication** using encrypted cookies
- **Current user context** via `ActiveSupport::CurrentAttributes`
- **Automatic authentication enforcement** with opt-out capability
- **Return-to-URL tracking** for post-login redirects

**Key Pattern**: The `Current` class provides thread-safe request context:
```ruby
class Current < ActiveSupport::CurrentAttributes
  attribute :session
  delegate :user, to: :session, allow_nil: true
end
```

### 2. Data Model Patterns

#### Encrypted Attributes
Sensitive data like GitHub tokens are encrypted at rest:
```ruby
class Repository < ApplicationRecord
  encrypts :gh_token  # Rails 7+ native encryption
end
```

#### Validation Patterns
- **Presence validations** for required fields
- **Format validations** for emails (using URI::MailTo::EMAIL_REGEXP)
- **Custom validations** for business logic
- **Normalization** for consistent data storage

#### Association Patterns
- **Many-to-Many through join models**: Users ↔ UserRepositories ↔ Repositories
- **Dependent destruction cascades** to maintain referential integrity
- **Has-secure-password** for user authentication

### 3. Controller Patterns

#### RESTful Resource Controllers
Standard Rails REST patterns with strong parameters:
```ruby
before_action :set_repository, only: [:show, :edit, :update, :destroy]
```

#### Security Patterns
- **Strong parameters** for mass assignment protection
- **Authorization via scoping**: `Current.user.repositories.find(params[:id])`
- **CSRF protection** enabled by default
- **Modern browser enforcement** for security features

### 4. View Patterns

#### Hotwire Integration
- **Turbo Drive** for SPA-like navigation
- **Turbo Frames** for partial page updates
- **Data attributes** for Turbo methods: `data: { turbo_method: :delete }`

#### Responsive ERB Templates
- **Semantic HTML structure** with header/main sections
- **Conditional rendering** based on data presence
- **Rails helpers** for links, forms, and assets

### 5. Security Patterns

#### Password Security
- **BCrypt hashing** with secure salt
- **Minimum password length** enforcement (6 characters)
- **Password reset tokens** for account recovery

#### Token Management
- **Encrypted storage** for API tokens
- **Optional updates** - blank tokens preserve existing values
- **Never exposed in logs** via parameter filtering

### 6. Code Organization Patterns

#### Concerns for Shared Behavior
Modular code organization using Rails concerns:
- Authentication logic extracted to `Authentication` concern
- Included in `ApplicationController` for app-wide use
- Class methods for configuration (e.g., `allow_unauthenticated_access`)

#### Conventional File Structure
- **Models** contain business logic and validations
- **Controllers** handle HTTP requests and responses
- **Views** handle presentation logic
- **Helpers** provide view utility methods
- **Jobs** handle background processing

### 7. Testing & Quality Patterns

#### Security-First Development
- **Brakeman** for automated security scanning
- **Rubocop** for consistent code style
- **Strong parameter filtering** prevents mass assignment

#### Development Tools
- **bin/dev** - Procfile-based development server
- **bin/setup** - Automated setup script
- **Docker support** via Dockerfile and docker-entrypoint

## Key Design Decisions

### Why Hotwire over SPA Framework?
The application uses server-side rendering with Hotwire enhancements rather than a JavaScript SPA framework. This provides:
- Simplified development with less JavaScript complexity
- Better SEO and initial page load performance
- Reduced client-side state management complexity
- Native browser features (back button, etc.) work naturally

### Why SQLite in Development?
SQLite provides zero-configuration database setup ideal for:
- Quick development environment setup
- Simplified testing with in-memory databases
- Easy data portability between environments
- Production-ready with proper configuration (Litestack, etc.)

### Why Encrypted Credentials?
GitHub tokens are encrypted at the database level to:
- Protect against database breaches
- Comply with security best practices
- Prevent accidental token exposure in logs/dumps
- Enable secure token sharing between users

## Running the Application

### Prerequisites
- Ruby 3.x
- SQLite3
- Node.js (for JavaScript runtime)

### Setup
```bash
# Install dependencies
bundle install

# Setup database
bin/rails db:create
bin/rails db:migrate

# Start development server
bin/dev
```

### Testing
```bash
# Run test suite
bin/rails test

# Run security analysis
bin/brakeman

# Run style checks
bin/rubocop
```

## Next Steps & Extensibility

The current architecture is well-positioned for:

1. **GitHub API Integration** - Add background jobs to fetch issues
2. **Real-time Updates** - Leverage Solid Cable for WebSocket updates
3. **Advanced Search** - Add full-text search with PostgreSQL
4. **Team Collaboration** - Extend user_repositories for team access
5. **Webhook Support** - Add GitHub webhook endpoints for real-time sync
6. **API Layer** - Add JSON API endpoints for mobile/CLI clients

The clean separation of concerns and Rails conventions make these extensions straightforward to implement while maintaining code quality and security.
