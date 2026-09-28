import carol from '@/content/quotes/a-christmas-carol.json'
import reading from '@/content/quotes/about-reading.json'

export type QuoteEntry = {
  id: string
  text: string
  speaker: string
  themes: string[]
  context: string
  analysis: string
  stave?: number
  citation?: string
  sourceUrl?: string
  sourceName?: string
}

export type QuoteFaq = {
  question: string
  answer: string
}

export type Misattribution = {
  id: string
  claim: string
  detail: string
  sourceName: string
  sourceUrl: string
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
  eyebrow?: string
  indexLabel?: string
  intro?: string[]
  sourceNote?: string
  sourcesArePerQuote?: boolean
  groupBy?: 'stave' | 'theme'
  themeOrder?: string[]
  themeHeadings?: Record<string, string>
  faqHeading?: string
  faqs?: QuoteFaq[]
  misattributions?: Misattribution[]
  misattributionIntro?: string
}

export const quoteHubs: QuoteHub[] = [carol, reading as QuoteHub]

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
