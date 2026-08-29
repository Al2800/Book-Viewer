# Design — BookQuotes

A locked design system for the bookquotes.uk marketing site. Every page
redesign reads this file before emitting code. Do not regenerate per page —
extend or amend this file when the system needs to grow.

## Genre
editorial

## Macrostructure family
- Marketing pages: Split Studio (home). Diptych of claim + first-party proof.
  How-it-works is a vertical step sequence, not three equal cards.
- App pages: none on this site.
- Content pages: Long Document for journal/guide articles. Index-First for
  `/journal` and `/guides` listings. Legal and support stay Long Document.

## Theme
Locked to the existing BookQuotes paper-and-ink brand. Do not rotate catalog
themes on later pages.

- `--color-paper`   oklch(98.6% 0.008 95)
- `--color-paper-2` oklch(96.8% 0.012 90)
- `--color-paper-3` oklch(93.2% 0.016 88)
- `--color-ink`     oklch(21.5% 0.012 95)
- `--color-ink-2`   oklch(35% 0.014 90)
- `--color-rule`    oklch(21.5% 0.012 95 / 0.12)
- `--color-accent`  oklch(64% 0.132 85)
- `--color-focus`   oklch(64% 0.132 85)

## Typography
- Display: Playfair Display, weight 600, style normal
- Body:    Source Serif Pro, weight 400
- UI:      Inter, weight 500
- Mono:    JetBrains Mono, weight 400
- Display tracking: -0.02em
- Type scale anchor: `--text-display` = clamp(2.25rem, 6vw, 3.75rem)

## Spacing
4-point named scale. The values are in `tokens.css`. Pages must use named
tokens (`var(--space-md)`), never raw one-off values.

## Motion
- Easings: `--ease-out` cubic-bezier(0.16, 1, 0.3, 1)
- Reveal pattern: none. The page is present.
- Reduced-motion fallback: opacity-only, ≤ 150 ms, if any motion is added later.

## Microinteractions stance
- silent success
- hover delay 800 ms · focus delay 0 ms
- no hover-scale, no `transition-all`, no scroll-triggered fade-up
- focus rings appear instantly

## CTA voice
- Primary CTA: outlined chip, hairline ink border, roman label, no fill on
  rest. Accent fill is allowed only for the App Store action, ≤ 5% of the
  viewport.
- Secondary CTA: typographic link with a 1px underline.

## Nav and footer
- Nav: N6 Newspaper masthead. Destinations: Journal, Guides, Get the app.
  No Features / How It Works / Access sitemap.
- Footer: Ft6 Letter close. Legal links in the postscript. No Product /
  Resources / Legal columns.

## Per-page allowances
- Marketing pages MAY use first-party screenshots in a hairline `<figure>`.
  No re-drawn phone or browser chrome.
- Content pages: typography only, plus one first-party screenshot where the
  article already shows product evidence.
- Do not invent metrics, testimonials, or issue numbers.

## What pages MUST share
- The BookQuotes wordmark, set in Playfair.
- Paper, ink, and library-gold accent (accent ≤ 5% per viewport).
- Display + body pairing.
- Outlined / typographic CTA voice.
- In-flow masthead. No sticky frost glass.

## What pages MAY differ on
- Home uses Split Studio. Indexes use Index-First. Articles use Long Document.
- Home may show the library screenshot once in the hero.

## Exports
See `tokens.css`.
