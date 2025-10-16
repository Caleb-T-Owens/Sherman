# Life OS

A personal operating system for managing your life, built with Rails 8 and semantic HTML.

## Design Philosophy

Life OS is built on these core principles:

-   **Semantic HTML First**: Uses clean, accessible HTML without CSS frameworks
-   **Rails 8 Patterns**: Leverages modern Rails conventions and best practices
-   **Minimal Dependencies**: Focuses on Rails-native solutions over external libraries
-   **Server-Side Logic**: Prefers server-side rendering and controller logic over client-side JavaScript
-   **Progressive Enhancement**: Core functionality works without JavaScript
-   **User-Centric**: Clean, focused interface without unnecessary features

## Technology Stack

-   **Ruby on Rails**: 8.0.2
-   **Ruby**: 3.4.1
-   **Database**: SQLite (development/test)
-   **Authentication**: `has_secure_password` (bcrypt)
-   **Frontend**: Semantic HTML with Turbo and Stimulus
-   **Asset Pipeline**: Propshaft with Importmap for JavaScript
-   **Job Queue**: Solid Queue
-   **Caching**: Solid Cache
-   **Real-time**: Solid Cable

## Core Patterns & Methods

### 1. Authentication Concern (`Authentication`)

Located in `app/controllers/concerns/authentication.rb`, this concern provides:

**Key Methods:**
- `allow_unauthenticated_access only: [:action]` - Allow specific actions without login
- `authenticated?` - Helper method to check if user is logged in
- `start_new_session_for(user)` - Create a new session and set secure cookie
- `after_authentication_url` - Get redirect URL after login
- `terminate_session` - Destroy current session and clear cookie
- `Current.user` - Access the currently logged-in user (view/controller)

### 2. Current Object (`Current < ActiveSupport::CurrentAttributes`)

A request-scoped object for storing per-request data without global state.

**Usage:**
- `Current.session` - Access the current session
- `Current.user` - Access the currently authenticated user
- `Current.user.email_address` - Access user properties

**Benefits:**
- Explicitly shows intent in controllers and views
- Rails 8 standard pattern
- Thread-safe and request-scoped
- No magic method lookups

### 3. Models

The application uses three key models:

```mermaid
erDiagram
    USER ||--o{ SESSION : has
    CURRENT ||--|| SESSION : references

    USER {
        int id PK
        string email_address UK
        string password_digest
        timestamp created_at
        timestamp updated_at
    }

    SESSION {
        int id PK
        int user_id FK
        string ip_address
        string user_agent
        timestamp created_at
        timestamp updated_at
    }

    CURRENT {
        session "request-scoped"
        user "delegates to session"
    }
```

**Key Design:**
- **User**: Handles authentication with bcrypt password hashing via `has_secure_password`. Email addresses are normalized (case-insensitive, trimmed). Cascading destroy of sessions on user deletion.
- **Session**: Tracks individual login sessions with IP and user agent data for security monitoring. Enables multi-device login tracking and per-session revocation.
- **Current**: Rails 8 `CurrentAttributes` object providing thread-safe, request-scoped access to `Current.session` and `Current.user`

### 4. Flash Messages

User feedback is displayed using Rails flash messages in the application layout. Flash alerts and notices are rendered as semantic `<section>` elements. See `app/views/layouts/application.html.erb` for the implementation.

## Views & HTML

All views use **semantic HTML** with minimal inline styling for presentation.

**Key principles:**
- Semantic tags (`<header>`, `<nav>`, `<main>`, `<section>`, `<article>`, etc.) for structure
- No CSS framework (Bootstrap, Tailwind, etc.)
- Only implemented links (no broken `href="#"` placeholders)
- Authentication-aware navigation using `authenticated?` helper
- Forms use Rails form helpers with error display and HTML5 validation
- Flash messages displayed for user feedback

See `app/views/` for view implementations.

## Authentication Flow

### Registration

1. User visits `/users/new`
2. Fills out email and password form
3. `UsersController#create` validates and creates user
4. `start_new_session_for` creates session and sets secure cookie
5. User redirected to dashboard, automatically logged in

### Login

1. User visits `/session/new`
2. Enters email and password
3. `User.authenticate_by` verifies credentials
4. On success: Session created, user redirected to dashboard or return URL
5. On failure: Redirect back to login with error message
6. Rate limiting prevents brute force (10 attempts per 3 minutes)

### Logout

1. User clicks "Sign out" link
2. `DELETE /session` → `SessionsController#destroy`
3. `terminate_session` destroys session and deletes cookie
4. User redirected to login page

### Password Reset

1. User visits `/passwords/new` from login page
2. Enters email address
3. `PasswordsMailer` sends reset email with unique token
4. User clicks link in email, visits `/passwords/:token/edit`
5. Enters new password
6. `PasswordsController#update` validates and updates password
7. User can then log in with new password

## Database Schema

See the [Models](#3-models) section for the ER diagram. The database is SQLite in development and test environments. Migrations are located in `db/migrate/`.

## Development

### Getting Started

```bash
# Install dependencies
bundle install

# Set up database
rails db:create db:migrate

# Run the server
bin/dev

# Visit http://localhost:3000
```

### Running Tests

```bash
# Run all tests
rails test

# Run system tests
rails test:system
```

### Database Commands

```bash
# Create database
rails db:create

# Run migrations
rails db:migrate

# Reset database (development only)
rails db:reset

# Seed database
rails db:seed
```

## Security Features

-   **Password hashing**: bcrypt via `has_secure_password`
-   **CSRF protection**: Rails default CSRF tokens
-   **Secure cookies**: HTTPOnly, SameSite:Lax
-   **Session tracking**: IP and user agent recorded
-   **Rate limiting**: Login attempts limited to 10 per 3 minutes
-   **Email normalization**: Case-insensitive, trimmed emails
-   **Password validation**: Minimum 12 characters required
-   **Content Security Policy**: Default Rails CSP in place

## Deployment

The app is configured for deployment with:

-   **Docker**: Dockerfile and .dockerignore included
-   **Kamal**: Deployment orchestration configured
-   **Solid Cache**: Production-ready caching
-   **Solid Queue**: Production-ready job queue
-   **Solid Cable**: Production-ready WebSocket support

See `config/deploy.yml` for deployment configuration.

## Contributing

When adding features to Life OS, follow these patterns:

1. **Use the Current object** instead of helper methods for authentication state
2. **Use `authenticated?`** helper to check authentication status
3. **Write semantic HTML** without CSS frameworks
4. **Avoid client-side redirects** - use controller logic
5. **No JavaScript in script tags** - use Stimulus controllers or Turbo
6. **Only create real links** - don't use `href="#"` for placeholders
7. **Server-side form validation** - with graceful error display

## License

[Add license here if applicable]
