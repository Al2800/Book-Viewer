# BookQuotes Landing Page — Design Specification

## Vision

A literary, elegant landing page that feels like opening a beautiful book. The site should resonate with serious readers—people who underline passages, write margin notes, and treasure their physical libraries. Think: the warmth of aged paper, the sophistication of a well-designed book cover, the satisfaction of a curated reading list.

---

## Design Philosophy

### Core Principles

1. **Literary First** — Typography and layout inspired by fine book design
2. **Warm & Inviting** — Paper-like colors, not sterile white
3. **Subtle Craft** — Small details that delight (micro-animations, textures)
4. **Trust Through Simplicity** — Clean, focused, no marketing noise
5. **Mobile Excellence** — Beautiful on phones where app downloads happen

### Inspiration

| Reference | What to Take |
|-----------|--------------|
| **Readwise** | Clean feature explanations, intellectual aesthetic |
| **Goodreads** | Book-lover community feel, warm tones |
| **Literal.club** | Modern literary design, beautiful typography |
| **Standard Notes** | Privacy-focused messaging, trust signals |
| **Linear.app** | Smooth animations, premium feel |

---

## Color Palette

```css
:root {
  /* Primary - Warm Paper Tones */
  --paper-cream: #FDFBF7;        /* Main background - like book pages */
  --paper-warm: #F8F5EF;         /* Secondary sections */
  --paper-aged: #EDE8DE;         /* Cards, elevated surfaces */

  /* Text - Rich Book Ink */
  --ink-black: #1A1915;          /* Primary text - warm black */
  --ink-dark: #3D3A33;           /* Secondary text */
  --ink-medium: #6B665A;         /* Tertiary, captions */
  --ink-light: #9C9687;          /* Subtle text, placeholders */

  /* Accent - Library Gold */
  --gold-primary: #B8860B;       /* CTAs, highlights */
  --gold-light: #D4A84B;         /* Hover states */
  --gold-muted: #C9B896;         /* Subtle accents */

  /* Supporting */
  --sage-green: #7A8B6F;         /* Success, nature connection */
  --rust-red: #A65D57;           /* Emphasis, alerts */
  --navy-deep: #2C3E50;          /* Trust, depth */

  /* Borders & Shadows */
  --border-subtle: rgba(26, 25, 21, 0.08);
  --shadow-soft: rgba(26, 25, 21, 0.04);
}
```

### Color Usage

- **Background**: `paper-cream` primary, `paper-warm` for alternating sections
- **Text**: `ink-black` for headings, `ink-dark` for body
- **CTAs**: `gold-primary` buttons with `paper-cream` text
- **Links**: `ink-dark` with `gold-primary` underline on hover
- **Cards**: `paper-aged` background with subtle shadow

---

## Typography

### Font Stack

```css
/* Display & Headings - Sophisticated Serif */
--font-display: 'Playfair Display', 'Crimson Pro', 'Georgia', serif;

/* Body - Readable Modern Serif */
--font-body: 'Source Serif Pro', 'Crimson Text', 'Georgia', serif;

/* UI Elements - Clean Sans */
--font-ui: 'Inter', 'SF Pro Text', -apple-system, sans-serif;

/* Monospace - For quotes/code */
--font-mono: 'JetBrains Mono', 'SF Mono', monospace;
```

### Type Scale

```css
/* Mobile-first, scales up on larger screens */
--text-xs: 0.75rem;      /* 12px - Fine print */
--text-sm: 0.875rem;     /* 14px - Captions */
--text-base: 1rem;       /* 16px - Body */
--text-lg: 1.125rem;     /* 18px - Lead text */
--text-xl: 1.25rem;      /* 20px - Subheadings */
--text-2xl: 1.5rem;      /* 24px - Section titles */
--text-3xl: 2rem;        /* 32px - Page titles */
--text-4xl: 2.5rem;      /* 40px - Hero subtitle */
--text-5xl: 3.5rem;      /* 56px - Hero headline */

/* Line heights */
--leading-tight: 1.2;
--leading-normal: 1.6;
--leading-relaxed: 1.8;
```

### Heading Styles

```css
h1 {
  font-family: var(--font-display);
  font-size: var(--text-5xl);
  font-weight: 700;
  line-height: var(--leading-tight);
  letter-spacing: -0.02em;
  color: var(--ink-black);
}

h2 {
  font-family: var(--font-display);
  font-size: var(--text-3xl);
  font-weight: 600;
  line-height: var(--leading-tight);
  color: var(--ink-black);
}

.body-text {
  font-family: var(--font-body);
  font-size: var(--text-lg);
  line-height: var(--leading-relaxed);
  color: var(--ink-dark);
}
```

---

## Layout & Spacing

### Grid System

```css
/* Container widths */
--container-sm: 640px;   /* Text-heavy sections */
--container-md: 768px;   /* Standard content */
--container-lg: 1024px;  /* Feature showcases */
--container-xl: 1280px;  /* Maximum width */

/* Spacing scale */
--space-1: 0.25rem;      /* 4px */
--space-2: 0.5rem;       /* 8px */
--space-3: 0.75rem;      /* 12px */
--space-4: 1rem;         /* 16px */
--space-6: 1.5rem;       /* 24px */
--space-8: 2rem;         /* 32px */
--space-12: 3rem;        /* 48px */
--space-16: 4rem;        /* 64px */
--space-24: 6rem;        /* 96px */
--space-32: 8rem;        /* 128px */
```

### Section Rhythm

- **Section padding**: `space-24` vertical on desktop, `space-16` on mobile
- **Content gaps**: `space-8` between elements within sections
- **Card padding**: `space-6` internal padding
- **Max line width**: `65ch` for body text (optimal reading)

---

## Page Structure

### 1. Navigation

```
┌─────────────────────────────────────────────────────────────┐
│  [Logo: BookQuotes]                    Features  Pricing  │
│                                        [Download App ▼]   │
└─────────────────────────────────────────────────────────────┘
```

- Sticky on scroll with subtle backdrop blur
- Minimal - logo left, links right
- CTA button with App Store link
- Mobile: Hamburger menu or simplified

### 2. Hero Section

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│         Your Paper Highlights,                              │
│           Digitized Beautifully                             │
│                                                             │
│    Transform underlined passages and margin notes from      │
│    physical books into a searchable digital library.        │
│                                                             │
│    [Download on App Store]  [See How It Works ↓]           │
│                                                             │
│              ┌─────────────────────────┐                   │
│              │    [iPhone Mockup]      │                   │
│              │    showing app in use   │                   │
│              └─────────────────────────┘                   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

- Full viewport height on desktop
- Headline in `Playfair Display`, large
- Subheadline in `Source Serif Pro`
- Two CTAs: Primary (App Store) + Secondary (scroll to demo)
- iPhone mockup showing the app with real content
- Subtle paper texture in background

### 3. Problem/Solution

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│  ┌─────────────────┐    ┌─────────────────┐                │
│  │ THE PROBLEM     │    │ THE SOLUTION    │                │
│  │                 │    │                 │                │
│  │ Your insights   │ →  │ Snap a photo.   │                │
│  │ are trapped in  │    │ AI extracts     │                │
│  │ physical books. │    │ your highlights.│                │
│  │                 │    │ Search forever. │                │
│  └─────────────────┘    └─────────────────┘                │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

- Two-column layout that becomes stacked on mobile
- Emotional connection: "Your insights deserve better"
- Clear before/after transformation

### 4. How It Works (3-Step Process)

```
┌─────────────────────────────────────────────────────────────┐
│                    How It Works                             │
│                                                             │
│   ┌──────────┐      ┌──────────┐      ┌──────────┐        │
│   │    1     │      │    2     │      │    3     │        │
│   │  Capture │  →   │ Extract  │  →   │  Enjoy   │        │
│   │          │      │          │      │          │        │
│   │ [Photo]  │      │ [AI]     │      │ [Library]│        │
│   │          │      │          │      │          │        │
│   │ Snap your│      │ AI finds │      │ Search,  │        │
│   │ marked   │      │ underlines│      │ organize,│        │
│   │ pages    │      │ & notes  │      │ export   │        │
│   └──────────┘      └──────────┘      └──────────┘        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

- Three cards with icons/illustrations
- Subtle connecting arrows
- Each step has: number, title, icon, brief description
- Animation: Cards fade in sequentially on scroll

### 5. Features Showcase

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│   ┌──────────────────────────────────────────────────────┐ │
│   │                                                       │ │
│   │  [Screenshot: Batch Capture]                         │ │
│   │                                                       │ │
│   │                               Batch Capture Mode     │ │
│   │                               ───────────────────    │ │
│   │                               Photograph 20 pages    │ │
│   │                               in a session. AI       │ │
│   │                               processes them all     │ │
│   │                               while you make tea.    │ │
│   │                                                       │ │
│   └──────────────────────────────────────────────────────┘ │
│                                                             │
│   ┌──────────────────────────────────────────────────────┐ │
│   │                                                       │ │
│   │  Smart Search                [Screenshot: Search]    │ │
│   │  ───────────────                                     │ │
│   │  Full-text search across                             │ │
│   │  all your quotes. Find that                          │ │
│   │  passage about "atomic"                              │ │
│   │  in milliseconds.                                    │ │
│   │                                                       │ │
│   └──────────────────────────────────────────────────────┘ │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

- Alternating left/right layout
- Large app screenshots with device frames
- Features to highlight:
  1. **Batch Capture** — Process multiple pages
  2. **Smart Search** — FTS5 instant search
  3. **Custom Markings** — Define your annotation style
  4. **Offline Mode** — Capture anywhere, sync later
  5. **Export** — Markdown, Obsidian, Notion
- Subtle parallax on screenshots

### 6. Social Proof / Quote Display

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│              "Finally, my margin notes have                 │
│               a home outside the book."                     │
│                                                             │
│                   — A Happy Reader                          │
│                                                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │ ★★★★★    │  │ ★★★★★    │  │ ★★★★★    │  │ ★★★★★    │   │
│  │ "Best    │  │ "Changed │  │ "So      │  │ "Worth   │   │
│  │  reading │  │  how I   │  │  elegant │  │  every   │   │
│  │  app"    │  │  read"   │  │  & fast" │  │  penny"  │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

- Large pull quote in serif italic
- Horizontal carousel of testimonial cards
- Star ratings prominent
- Real user names if available

### 7. Pricing / CTA Section

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│              Start Capturing Your Insights                  │
│                                                             │
│   ┌─────────────────┐      ┌─────────────────────────────┐ │
│   │      Free       │      │        Premium              │ │
│   │                 │      │                             │ │
│   │  10 extractions │      │  Unlimited extractions      │ │
│   │  per month      │      │  Batch mode                 │ │
│   │                 │      │  Export to Obsidian/Notion  │ │
│   │  [Get Started]  │      │  Priority support           │ │
│   │                 │      │                             │ │
│   │                 │      │  $4.99/month                │ │
│   │                 │      │  [Subscribe]                │ │
│   └─────────────────┘      └─────────────────────────────┘ │
│                                                             │
│         Privacy-first. Your data stays on your device.     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

- Two-tier pricing cards
- Free tier to lower barrier
- Premium benefits clearly listed
- Trust badge about privacy

### 8. Footer

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│  BookQuotes                                                 │
│  Transform your reading.                                    │
│                                                             │
│  Product        Company        Legal                        │
│  ────────       ────────       ──────                       │
│  Features       About          Privacy Policy               │
│  Pricing        Blog           Terms of Service             │
│  Download       Contact        Cookie Policy                │
│                                                             │
│  ─────────────────────────────────────────────────────────  │
│                                                             │
│  © 2024 BookQuotes. Made with ♥ for book lovers.           │
│                                                             │
│  [Twitter]  [Instagram]  [GitHub]                          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Micro-Interactions & Animation

### Principles

- **Subtle, not showy** — Animations should feel natural, like turning a page
- **Purpose-driven** — Every animation communicates something
- **Performance** — 60fps, use `transform` and `opacity` only

### Specific Animations

| Element | Animation | Timing |
|---------|-----------|--------|
| Hero text | Fade up + slight scale | 0.6s ease-out, staggered |
| Screenshots | Fade in + parallax on scroll | 0.8s ease-out |
| Feature cards | Fade up when in viewport | 0.5s, 0.1s stagger |
| CTAs | Subtle scale on hover (1.02) | 0.2s ease |
| Navigation | Backdrop blur on scroll | 0.3s |
| Testimonials | Auto-scroll carousel | 5s per card |

### Scroll Animations

```javascript
// Intersection Observer for fade-in
const observer = new IntersectionObserver(
  (entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        entry.target.classList.add('visible');
      }
    });
  },
  { threshold: 0.1 }
);
```

---

## Visual Elements

### App Screenshots

Need high-quality screenshots showing:
1. **Library view** — Grid of books with covers
2. **Quote capture** — Camera interface with quality overlay
3. **Extraction review** — AI-extracted quotes with confidence
4. **Search results** — Instant search with highlights
5. **Quote detail** — Beautiful quote card view
6. **Export options** — Markdown/Obsidian export

### Icons

Use a consistent icon set:
- **Lucide Icons** or **Heroicons** for UI elements
- Custom illustrations for feature explanations
- Book/reading themed where appropriate

### Illustrations (Optional)

Consider custom illustrations:
- Stack of books with highlights visible
- Person reading with phone nearby
- Abstract representation of "physical to digital"

### Background Textures

Subtle paper texture overlay:
```css
.paper-texture {
  background-image: url('/textures/paper-grain.png');
  background-blend-mode: multiply;
  opacity: 0.03;
}
```

---

## Mobile Considerations

### Breakpoints

```css
/* Mobile first */
@media (min-width: 640px) { /* sm */ }
@media (min-width: 768px) { /* md */ }
@media (min-width: 1024px) { /* lg */ }
@media (min-width: 1280px) { /* xl */ }
```

### Mobile-Specific Adjustments

- Hero: Reduce headline size, stack CTAs vertically
- Features: Single column, screenshots full width
- Navigation: Hamburger menu with slide-out
- Screenshots: Use phone-sized mockups
- Touch targets: Minimum 44px

---

## SEO & Meta

### Page Title
```
BookQuotes — Turn Paper Highlights into a Digital Library
```

### Meta Description
```
Photograph your underlined passages and margin notes. AI extracts them instantly. Search, organize, and export your reading insights. Free for iOS.
```

### Open Graph

```html
<meta property="og:title" content="BookQuotes — Your Paper Highlights, Digitized" />
<meta property="og:description" content="Transform underlined passages and margin notes from physical books into a searchable digital library." />
<meta property="og:image" content="/og-image.jpg" /> <!-- 1200x630 -->
<meta property="og:url" content="https://bookquotes.app" />
```

### Structured Data

```json
{
  "@context": "https://schema.org",
  "@type": "MobileApplication",
  "name": "BookQuotes",
  "operatingSystem": "iOS",
  "applicationCategory": "LifestyleApplication",
  "offers": {
    "@type": "Offer",
    "price": "0",
    "priceCurrency": "USD"
  },
  "aggregateRating": {
    "@type": "AggregateRating",
    "ratingValue": "4.8",
    "ratingCount": "150"
  }
}
```

---

## Technical Stack

### Framework
- **Next.js 14** (App Router) — SSR, great SEO, Vercel native
- **TypeScript** — Type safety
- **Tailwind CSS** — Rapid styling with design tokens
- **Framer Motion** — Smooth animations

### Deployment
- **Vercel** — Zero-config deployment, edge functions
- **Domain**: `bookquotes.app` or similar

### Performance Targets
- **Lighthouse**: 95+ all categories
- **Core Web Vitals**: Green across the board
- **First Contentful Paint**: < 1s
- **Time to Interactive**: < 2s

---

## File Structure

```
website/
├── app/
│   ├── layout.tsx          # Root layout with fonts, metadata
│   ├── page.tsx            # Home page
│   ├── privacy/page.tsx    # Privacy policy
│   ├── terms/page.tsx      # Terms of service
│   └── globals.css         # Global styles, CSS variables
│
├── components/
│   ├── layout/
│   │   ├── Header.tsx
│   │   └── Footer.tsx
│   ├── sections/
│   │   ├── Hero.tsx
│   │   ├── Problem.tsx
│   │   ├── HowItWorks.tsx
│   │   ├── Features.tsx
│   │   ├── Testimonials.tsx
│   │   └── Pricing.tsx
│   └── ui/
│       ├── Button.tsx
│       ├── Card.tsx
│       ├── DeviceMockup.tsx
│       └── AnimatedSection.tsx
│
├── lib/
│   └── utils.ts            # Helper functions
│
├── public/
│   ├── screenshots/        # App screenshots
│   ├── icons/              # Favicons, app icons
│   ├── textures/           # Paper textures
│   └── og-image.jpg        # Social sharing image
│
├── tailwind.config.ts      # Tailwind with custom theme
├── next.config.js
└── package.json
```

---

## Content Checklist

### Copy Needed
- [ ] Hero headline and subheadline
- [ ] Problem/solution text
- [ ] Feature descriptions (6)
- [ ] Testimonials (4-6) — can be placeholder initially
- [ ] Pricing tier descriptions
- [ ] Privacy policy
- [ ] Terms of service

### Assets Needed
- [ ] App icon (for favicon, header)
- [ ] App screenshots (6)
- [ ] iPhone mockup template
- [ ] Paper texture PNG
- [ ] OG image (1200x630)
- [ ] Feature icons

---

## Next Steps

1. **Set up project** — `npx create-next-app@latest website`
2. **Configure Tailwind** — Add custom theme tokens
3. **Build components** — Start with Header, Hero, Footer
4. **Add content** — Real copy and screenshots
5. **Polish animations** — Framer Motion integration
6. **Test mobile** — Responsive refinements
7. **Deploy to Vercel** — Connect repo, configure domain
8. **SEO audit** — Lighthouse, meta tags, structured data
