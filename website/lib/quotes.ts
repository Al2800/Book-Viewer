import carol from '@/content/quotes/a-christmas-carol.json'
import jekyll from '@/content/quotes/jekyll-and-hyde.json'

export type QuoteEntry = {
  id: string
  text: string
  speaker: string
  themes: string[]
  context: string
  analysis: string
  stave?: number
  chapter?: number
  act?: number
  scene?: number
  lineStart?: number
  lineEnd?: number
}

export type QuoteFaq = {
  question: string
  answer: string
}

export type QuoteSection = {
  number: number
  label: string
  short: string
}

export type QuoteHub = {
  slug: string
  title: string
  description: string
  publishedISO: string
  updatedISO: string
  sourceName: string
  sourceUrl: string
  quotes: QuoteEntry[]
  metaDescription?: string
  lead?: string
  arrangement?: string
  sourceNote?: string
  filterLabel?: string
  allFilterLabel?: string
  sectionKey?: string
  sections?: QuoteSection[]
  appNote?: string
  faqs?: QuoteFaq[]
}

export const quoteHubs: QuoteHub[] = [carol, jekyll]

export function getQuoteHub(slug: string) {
  return quoteHubs.find((hub) => hub.slug === slug)
}

export const staveLabels: Record<number, string> = {
  1: "Stave 1: Marley's Ghost",
  2: 'Stave 2: The First of the Three Spirits',
  3: 'Stave 3: The Second of the Three Spirits',
  4: 'Stave 4: The Last of the Spirits',
  5: 'Stave 5: The End of It',
}

export const gcseQuoteLinks = [
  { slug: 'a-christmas-carol', label: 'A Christmas Carol quotes' },
  { slug: 'jekyll-and-hyde', label: 'Jekyll and Hyde quotes' },
  { slug: 'macbeth', label: 'Macbeth quotes' },
]

export function quoteReference(quote: QuoteEntry, sectionKey?: string) {
  if (sectionKey === 'chapter') return `Chapter ${quote.chapter}`
  if (sectionKey === 'act') {
    const lines =
      quote.lineStart == null
        ? ''
        : quote.lineEnd != null && quote.lineEnd !== quote.lineStart
          ? `, lines ${quote.lineStart}-${quote.lineEnd}`
          : `, line ${quote.lineStart}`
    return `Act ${quote.act}, Scene ${quote.scene}${lines}`
  }
  return `Stave ${quote.stave}`
}
