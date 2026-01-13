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

## Deployment to Vercel

1. Push the `website` folder to a GitHub repository (or subfolder)
2. Connect to Vercel
3. Set the root directory to `website` if it's a subfolder
4. Vercel auto-detects Next.js and deploys

Or use the Vercel CLI:

```bash
npm i -g vercel
cd website
vercel
```

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

## Assets Needed

Before deploying, add:

- [ ] `public/icons/favicon.ico` - Browser favicon
- [ ] `public/icons/apple-touch-icon.png` - iOS icon
- [ ] `public/screenshots/*.png` - App screenshots for mockups
- [ ] `public/og-image.jpg` - Open Graph image (1200x630)

## Customization

### Update App Store Link

Search for `https://apps.apple.com/app/bookquotes` and replace with your actual App Store URL.

### Update Contact Info

Search for `@bookquotes.app` email addresses and update with your actual contact info.

## License

MIT
