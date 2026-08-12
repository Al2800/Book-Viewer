# BookQuotes Marketing Website

A literary, elegant landing page for the BookQuotes iOS app. Built with Next.js 15, Tailwind CSS, and Framer Motion.

## Tech Stack

- **Next.js 15** - React framework with App Router
- **Tailwind CSS** - Utility-first styling
- **Framer Motion** - Smooth animations
- **Lucide React** - Beautiful icons
- **TypeScript** - Type safety

## Development

```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Build for production
npm run build

# Start production server
npm start
```

## Deployment to Cloudflare Workers

The production website is the `bookquotes-website` Cloudflare Worker serving
`https://bookquotes.uk`. The checked-in `wrangler.jsonc` is the generated Vinext deployment
manifest; keep it aligned with `vite.config.ts` and the public route read-back.

Use a least-privilege `CLOUDFLARE_API_TOKEN` from the local environment. Never commit or print the
token. Read the account first, then build and deploy from this directory:

```bash
npx wrangler whoami
npx vinext deploy --name bookquotes-website
```

For a build-only check, use `npm run sites:build`. For a no-upload deployment check, use
`npx vinext deploy --dry-run`. After a real deployment, read back `/deployment.json`, the sitemap,
the canonical route matrix, representative guide/journal pages, legal/support routes and normal
TLS before calling the website live.

## Project Structure

```
website/
├── app/                    # Next.js App Router pages
│   ├── layout.tsx          # Root layout with fonts, metadata
│   ├── page.tsx            # Home page
│   ├── privacy/page.tsx    # Privacy policy
│   ├── terms/page.tsx      # Terms of service
│   └── globals.css         # Global styles, CSS variables
│
├── components/
│   ├── layout/             # Header, Footer
│   ├── sections/           # Page sections (Hero, Features, etc.)
│   └── ui/                 # Reusable UI components
│
├── lib/
│   └── utils.ts            # Helper functions
│
├── public/                 # Static assets
│   ├── screenshots/        # App screenshots (add your own)
│   ├── icons/              # Favicons (add your own)
│   └── textures/           # Paper textures
│
├── DESIGN_SPEC.md          # Full design specification
├── tailwind.config.ts      # Tailwind with custom theme
├── next.config.js          # Next.js configuration
└── package.json
```

## Design Tokens

The site uses a warm, literary color palette:

| Token | Value | Usage |
|-------|-------|-------|
| `paper-cream` | #FDFBF7 | Main background |
| `paper-warm` | #F8F5EF | Alternate sections |
| `paper-aged` | #EDE8DE | Cards, surfaces |
| `ink-black` | #1A1915 | Primary text |
| `ink-dark` | #3D3A33 | Body text |
| `gold-primary` | #B8860B | CTAs, accents |

## Current Assets

The reviewed website includes:

- [x] `public/icons/favicon.ico` - Browser favicon
- [x] `public/icons/apple-touch-icon.png` - iOS icon
- [x] `public/screenshots/library.png` - First-party library evidence figure
- [x] `public/og.png` - Open Graph image

## Customization

### Current App Store Link

Use `https://apps.apple.com/app/id6758091579` for the production App Store URL.

### Current Contact Info

Support and legal contact should use `acampbell193@googlemail.com`.

## License

MIT
