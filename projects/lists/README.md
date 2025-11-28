# Lists

A Rails 8 app using Inertia.js for building server-driven SPAs.

## Stack

- **Rails 8.1** (Ruby 3.4.1) with the new Solid\* stack (Cache/Queue/Cable)
- **Inertia.js** bridging Rails to React—no API layer needed
- **React 19** + TypeScript for the frontend
- **Bun** for JS bundling and running the page registry generator
- **Stimulus** available for lightweight interactivity
- SQLite, Puma, Propshaft for the Rails bits
- Kamal + Thruster for deployment

## Development Notes

- Components use semantic HTML without styling—designer will handle CSS later
- Session-based authentication with bcrypt (login/register/logout flows
  implemented)
- Admin dashboard powered by Administrate v1, accessible at `/admin` for
  authorized users (see `User#admin?` in `app/models/user.rb`)
