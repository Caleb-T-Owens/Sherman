# Master Sherman

Master Sherman is a web application for deploying and managing compose projects over multiple nodes.

## Technical Stack

-   Ruby on Rails 8.0.1
-   SQLite3 database
-   Hotwire (Turbo + Stimulus) for modern, SPA-like experience
-   Propshaft for asset pipeline
-   Kamal for deployment
-   Solid Queue for background jobs
-   Solid Cache for caching
-   Solid Cable for Action Cable

## Project Structure

### Models

-   `User`: Core user model with email/password authentication
-   `Session`: Manages user sessions with IP and user agent tracking
-   `Current`: Thread-safe access to current session and user

### Controllers

-   `ApplicationController`: Base controller with authentication
-   `SessionsController`: Handles login/logout
-   `RegistrationsController`: User registration
-   `PasswordsController`: Password reset flow
-   `PagesController`: Static pages (home, dashboard)

### Views

-   `layouts/`: Application layout and shared components
-   `sessions/`: Login/logout views
-   `registrations/`: Signup views
-   `passwords/`: Password reset views
-   `pages/`: Static page views
-   `pwa/`: Progressive Web App configuration

## Authentication & Authorization

The application uses a session-based authentication system:

-   Access the current user via `Current.user`
-   Sessions are managed through cookies with `httponly` and `same_site: :lax` security
-   User sessions are tracked with IP and user agent information
-   Password requirements: minimum 8 characters
-   Email addresses are normalized (stripped and downcased)

### Common Authentication Patterns

```ruby
# In controllers:
class MyController < ApplicationController
  # All actions require authentication by default
  # Use this to allow unauthenticated access:
  allow_unauthenticated_access only: [:index]
end

# Access current user:
Current.user # => Returns current user or nil
authenticated? # => Returns true if user is logged in
```

## Programming Patterns & Preferences

### Controllers

-   Use resourceful routing and RESTful patterns
-   Keep controllers thin, delegate business logic to models
-   Use concerns for shared functionality
-   Example routes:
    ```ruby
    resource :session # singular resource for login/logout
    resource :registration, only: [:new, :create]
    resources :passwords, param: :token
    ```

### Views

-   Use unstyled semantic HTML
-   Leverage Turbo for reactivity:
    -   Turbo Frames for partial page updates
    -   Turbo Streams for real-time updates
    -   Turbo Drive for SPA-like navigation
-   Avoid writing JavaScript or CSS directly
-   Use shared partials for common components

### Authentication

-   Use `Authentication` concern for controller authentication
-   `allow_unauthenticated_access` class method to bypass auth
-   Session management through `Current` class

### Code Style

-   Follow Rails Omakase style guide
-   Use ERB beautifier for consistent view formatting
-   Brakeman for security analysis

## Development Setup

1. Install dependencies:

    ```bash
    bundle install
    ```

2. Setup the database:

    ```bash
    bin/rails db:setup
    ```

3. Start the development server:
    ```bash
    bin/dev
    ```

### Common Development Tasks

```bash
# Generate a new controller
bin/rails generate controller ControllerName action1 action2

# Generate a new model
bin/rails generate model ModelName field1:type field2:type

# Run tests
bin/rails test

# Check code style
bundle exec rubocop
```

## Security

-   Modern browser requirements enforced
-   Secure password handling with bcrypt
-   Session security with httponly cookies
-   IP and user agent tracking for sessions

## Planned Features

-   [ ] Managing connections between different nodes
-   [ ] Managing shared storage
