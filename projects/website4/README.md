# Website4

A complete 1:1 remake of website3, rebuilt with Astro and MDX support.

## Tech Stack

- **Astro** - Modern static site generator with islands architecture
- **MDX** - Markdown with JSX support for enhanced content authoring
- **TypeScript** - Type-safe development

## What's New

Website4 is a complete port of website3 from Angular to Astro. This migration provides:

- **MDX Support**: Write content in Markdown with embedded components
- **Better Performance**: Static site generation by default
- **Simpler Architecture**: No framework overhead for static content
- **Improved Developer Experience**: Faster builds and hot module replacement

## Features

All features from website3 have been preserved:

- Font size selector with localStorage persistence
- Navigation with multiple sections (Main, Tech, External)
- SEO support with canonical URLs
- Responsive design with readable width constraints
- API integration for devlog entries (PocketBase)

## Pages

- **Home** (`/`) - About Caleb with biographical information
- **Phrases** (`/phrases`) - Collection of interesting terms and phrases
  - **Magpie's Nest** (`/phrases/magpies-nest`) - Detailed explanation of the term
- **Projects** (`/projects`) - List of personal projects
- **Devlog** (`/devlog`) - Development logs fetched from PocketBase API

## Development

```bash
# Install dependencies
pnpm install

# Start development server
pnpm dev

# Build for production
pnpm build

# Preview production build
pnpm preview
```

## Project Structure

```
website4/
├── public/              # Static assets (favicons, images)
├── src/
│   ├── components/      # Reusable Astro components
│   │   ├── FontSelector.astro
│   │   └── Navigation.astro
│   ├── layouts/         # Page layouts
│   │   └── MainLayout.astro
│   ├── pages/           # Route pages (MDX for content, Astro for logic)
│   │   ├── index.mdx
│   │   ├── phrases/
│   │   │   ├── index.mdx
│   │   │   └── magpies-nest.mdx
│   │   ├── projects.mdx
│   │   └── devlog.astro         # Uses Astro for API fetching
│   └── styles/          # Global styles
│       └── global.css
└── astro.config.mjs     # Astro configuration
```

## Migration from Website3

Website3 was built with Angular SSR. Website4 replaces this with Astro, which provides:

1. **Static Generation**: Pages are pre-rendered at build time
2. **No Client-Side Framework**: Pure HTML/CSS/JS for better performance
3. **MDX Support**: Enhanced content authoring capabilities
4. **Simpler Deployment**: Just static files, no Node.js server needed

The font selector component maintains the same localStorage-based persistence logic, reimplemented with vanilla JavaScript in an Astro component script.

The devlog page uses Astro's server-side data fetching to call the PocketBase API at build time, eliminating the need for client-side HTTP calls and RxJS observables.

Content pages (home, phrases, projects) are written in MDX for clean, maintainable Markdown-based authoring. The devlog page remains as .astro to handle API fetching logic.

## Design Philosophy

Website4 maintains the same minimalist, accessible design as website3:

- Serif fonts (Georgia) for headings, sans-serif (Arial) for body text
- User-controlled font sizing (small/medium/large)
- Clean semantic HTML structure
- No JavaScript required for core functionality (except font selector)
- CSS custom properties for theming

## Future Enhancements

With MDX support, future content can include:

- Interactive components embedded in articles
- Reusable content blocks
- Custom styling per article
- Rich media embeds
