# Not A Forge

A lightweight Git forge alternative built with Rails 8.1.

## Tech Stack

- **Framework**: Rails 8.1
- **Database**: SQLite3
- **JavaScript**: Bun (bundler) + Turbo + Stimulus
- **Authentication**: Rails built-in authentication
- **Type Checking**: RBS + Steep

## Getting Started

### Prerequisites

- Ruby 3.4.1
- Bun
- SQLite3

### Setup

```bash
bundle install
bin/rails db:setup
bin/dev  # Starts Rails server + Bun watcher
```

The app runs on `http://localhost:3000`

## Features

- User registration and authentication
- Session management with IP and user agent tracking
- Password reset functionality
- Repository management
- Access token system
- Responsive layout

## Type Checking with RBS

This project uses RBS (Ruby Signature) for static type checking with Steep.

### Quick Commands

```bash
# Generate RBS signatures for Rails models and helpers
bin/rails rbs_rails:all

# Install/update gem type signatures
bundle exec rbs collection install

# Run type checker
bundle exec steep check

# Watch mode (checks on file changes)
bundle exec steep watch
```

### How It Works

- **RBS files** define type signatures in `sig/` directory
- **rbs_rails** auto-generates signatures for Rails code (models, controllers, helpers)
- **RBS Collection** provides signatures for gems
- **Steep** analyzes your Ruby code against these signatures

### Configuration

- `Steepfile` - Steep type checker configuration
- `rbs_collection.yaml` - Gem signature dependencies
- `sig/` - Type signature files
- `sig/rbs_rails/` - Auto-generated Rails signatures

### Adding Type Signatures

Create `.rbs` files in `sig/` for your custom classes:

```ruby
# sig/my_service.rbs
class MyService
  def initialize: (User user) -> void
  def process: (String data) -> Integer
end
```

### Type Checking in CI

Add to your CI pipeline:

```bash
bundle exec steep check --severity-level=error
```

### Gradual Adoption

The project uses `lenient` diagnostics mode for Rails code. This allows gradual adoption:

1. Start by checking critical paths (models, services)
2. Add signatures incrementally
3. Tighten strictness over time by editing `Steepfile`

For stricter checking, change in `Steepfile`:
```ruby
configure_code_diagnostics(D::Ruby.strict)  # or .default
```

## Development

### Database

```bash
bin/rails db:migrate        # Run migrations
bin/rails db:reset          # Reset database
```

### Tests

```bash
bin/rails test              # Run all tests
bin/rails test:system       # Run system tests
```

### Code Quality

```bash
bundle exec rubocop         # Ruby style checking
bundle exec brakeman        # Security scanning
bundle exec bundler-audit   # Dependency security
```

## Project Structure

```
app/
  controllers/
    concerns/authentication.rb        # Auth logic
    registrations_controller.rb       # User signup
    sessions_controller.rb            # Login/logout
    passwords_controller.rb           # Password reset
    repositories_controller.rb        # Repository CRUD
    settings/
      profile_controller.rb           # User settings
      tokens_controller.rb            # Access tokens
  models/
    user.rb                           # User model
    session.rb                        # Session model
    repository.rb                     # Repository model
    token.rb                          # Access token model
  views/
    shared/
      _top_bar.html.erb              # Top navigation
      _side_bar.html.erb             # Sidebar (authenticated)
config/
  routes.rb                          # Route definitions
sig/
  rbs_rails/                         # Generated Rails signatures
```

## Deployment

The app includes Kamal for Docker-based deployment:

```bash
kamal setup       # Initial deployment
kamal deploy      # Deploy updates
```

## License

[Add your license here]
