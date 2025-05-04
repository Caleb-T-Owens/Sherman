# The Wistful Fox

A modern Rails application for conversation and discussion.

## Project Overview

The Wistful Fox is built with Ruby on Rails and follows modern web development practices. This document provides an overview of the project's architecture, authentication system, styling approach, and form handling.

## Database

The application uses PostgreSQL as its primary database system with a multi-database architecture for different concerns.

### Database Structure

The main database contains the following tables:

1. **Users**

    - `email_address` (string, unique)
    - `password_digest` (string)
    - `name` (string)
    - Timestamps (`created_at`, `updated_at`)

2. **Sessions**

    - `user_id` (foreign key)
    - `ip_address` (string)
    - `user_agent` (string)
    - Timestamps

3. **Posts**

    - `content` (string)
    - `user_id` (foreign key)
    - `likes_count` (integer, default: 0)
    - Timestamps

4. **Likes**
    - `user_id` (foreign key)
    - `post_id` (foreign key)
    - Timestamps
    - Unique index on `[user_id, post_id]`

### Database Configuration

The application uses a multi-database setup with separate databases for different concerns:

1. **Primary Database**

    - Main application data
    - Configured via environment variables:
        - `THEWISTFULFOX_DATABASE_HOST`
        - `THEWISTFULFOX_DATABASE_USERNAME`
        - `THEWISTFULFOX_DATABASE_PASSWORD`

2. **Cache Database**

    - Used for caching purposes
    - Located at `db/cache_migrate`

3. **Queue Database**

    - Used for background job processing
    - Located at `db/queue_migrate`

4. **Cable Database**
    - Used for Action Cable (WebSocket) functionality
    - Located at `db/cable_migrate`

### Database Setup

To set up the database:

```bash
rails db:create db:migrate
```

For development, the database name will be `thewistfulfox_development` with separate databases for cache, queue, and cable functionality.

## Authentication System

The application uses a custom authentication system built on top of Rails' session management. Key features include:

-   Session-based authentication with secure cookie handling
-   Password reset functionality via email
-   Rate limiting on authentication attempts
-   Secure password storage and validation

### Authentication Helpers

The following helpers are available in views and controllers:

-   `authenticated?` - Check if a user is currently logged in
-   `Current.user` - Access the current user object
-   `Current.session` - Access the current session object

Controllers can skip authentication requirements using:

```ruby
allow_unauthenticated_access only: %i[ new create ]
```

## Styling

The application uses a combination of:

1. **BeerCSS** - A modern Material Design framework

    - Loaded via CDN: `https://cdn.jsdelivr.net/npm/beercss@3.10.8`
    - Provides Material Design components and utilities

2. **Custom CSS**
    - Located in `app/assets/stylesheets/application.css`
    - Uses modern CSS features like nesting and flexbox
    - Common utility classes:
        - `.flex` - Flexbox container with various modifiers
        - `.flow` - Vertical spacing between elements

## Form Structure

Forms follow a consistent pattern throughout the application:

1. **Error Handling**

    - Use the shared error messages partial:

    ```erb
    <%= render "shared/error_messages", model: @model %>
    ```

2. **Form Fields**

    - Use `form_with` helper for model-backed forms
    - Fields are wrapped in `.field.border` divs
    - Labels are displayed above inputs
    - Required fields are marked with `required: true`
    - Password fields have `maxlength: 72` for security

3. **Form Actions**
    - Submit buttons use the `.button` class
    - Form actions are often wrapped in `.flex.space-between`

## Development Setup

1. Install dependencies:

    ```bash
    bundle install
    ```

2. Set up the database:

    ```bash
    rails db:create db:migrate
    ```

3. Start the server:
    ```bash
    rails server
    ```

## Environment Variables

The following environment variables are required:

-   `THEWISTFULFOX_DATABASE_HOST`
-   `THEWISTFULFOX_DATABASE_USERNAME`
-   `THEWISTFULFOX_DATABASE_PASSWORD`

## Testing

The application uses Rails' built-in testing framework. Run tests with:

```bash
rails test
```
