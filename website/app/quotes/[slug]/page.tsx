import type { Metadata } from 'next'
import Link from 'next/link'
import { ArrowLeft, ExternalLink } from 'lucide-react'
import { notFound } from 'next/navigation'
import { Header } from '@/components/layout/Header'
import { Footer } from '@/components/layout/Footer'
import { QuoteBank } from '@/components/quotes/QuoteBank'
import { gcseQuoteLinks, getQuoteHub, quoteHubs, type QuoteHub } from '@/lib/quotes'
import { seoAppStoreUrl, seoShareImage } from '@/lib/seo'

type QuotePageProps = {
  params: Promise<{ slug: string }>
}

const carolFaqs = [
  {
    question: 'Which A Christmas Carol quotes are worth learning for a grade 9 answer?',
    answer:
      'There is no official list, and no line earns a grade by itself. A strong answer uses a few quotations that let you write about change. A useful set runs across the book: the chain and "Mankind was my business" in Stave 1, Belle on Gain in Stave 2, the surplus-population echo and Ignorance and Want in Stave 3, the promise at the gravestone in Stave 4, and the raised salary in Stave 5. Learn the wording, the stave, and what the line is doing.',
  },
  {
    question: 'How many quotes should I learn for GCSE English?',
    answer:
      'The mark scheme does not publish a number. Learn fewer lines than you are tempted to, and know them well enough to place them in the right stave. A quotation you cannot find in the story will not help you. The 37 lines on this page are a bank to choose from, not a list to memorise in full.',
  },
  {
    question: 'What are the famous Scrooge quotes that are actually in the book?',
    answer:
      'The lines people reach for are "Bah!" said Scrooge, "Humbug!", the remark about decreasing the surplus population, and "I will honour Christmas in my heart". His late lines are "I am not the man I was" and the speech to Bob about his salary. Do not collapse the first of those into "Bah, humbug!" That phrase is not in this text. The chain, "I wear the chain I forged in life", belongs to Marley.',
  },
  {
    question: 'What does Tiny Tim say: "God bless us, every one"?',
    answer:
      'At the Cratchits\' dinner he says "God bless us every one!" with no comma and no capitals on "us". The last line of the book, spoken by the narrator, is "God bless Us, Every One!" with capitals and a comma. Both are in the Project Gutenberg text. They are not the same sentence. Quote the one you mean, and say who says it.',
  },
  {
    question: 'Which quotes fit poverty, greed and redemption?',
    answer:
      'Poverty: the prisons, the surplus population, Tiny Tim\'s empty chair, Ignorance and Want. Greed: the "squeezing, wrenching" list, Belle\'s golden idol, and the word Gain. Redemption: Marley\'s offer of a chance, "I am not the man I was", the promise to honour Christmas, and the salary. The clearer paragraphs use one early line and one late line, so the essay shows a change.',
  },
  {
    question: 'What if my school edition looks slightly different?',
    answer:
      'Editions differ in punctuation, and some capitalise Tiny Tim differently. Check the line against the copy you will have in the exam, and keep the stave rather than a page number. This page follows the Project Gutenberg text of A Christmas Carol, eBook 46. Page numbers move from edition to edition. The five staves do not.',
  },
]

const carolDescription =
  'Thirty-seven A Christmas Carol quotes for GCSE, checked against Dickens word for word. Each line has its stave, speaker, context and a short essay note.'

const carolLead =
  "These are key A Christmas Carol quotes for GCSE English, arranged by stave, character and theme, and checked word for word against Dickens's text."

const carolArrangement =
  'Each one gives the stave, who speaks, a sentence of what is happening, and a short note on how you might use the line in an essay. Filters narrow the list. The quotations stay in stave order underneath, so you can still read the book through.'

const carolSourceNote = 'Double hyphens inside a quotation are printed that way in that text.'

const carolAppNote =
  'Finish the page before you pick up the phone. Photograph the marked lines, check every word against the print, and keep the stave with the sentence. Add a tag only when you would reach for it in a paragraph: poverty, family, redemption.'

function hubDescription(hub: QuoteHub) {
  return hub.metaDescription ?? carolDescription
}

export function generateStaticParams() {
  return quoteHubs.map((hub) => ({ slug: hub.slug }))
}

export async function generateMetadata({ params }: QuotePageProps): Promise<Metadata> {
  const { slug } = await params
  const hub = getQuoteHub(slug)
  if (!hub) return {}

  const description = hubDescription(hub)

  return {
    title: hub.title,
    description,
    alternates: { canonical: `/quotes/${hub.slug}` },
    openGraph: {
      title: hub.title,
      description,
      url: `https://bookquotes.uk/quotes/${hub.slug}`,
      type: 'article',
      publishedTime: `${hub.publishedISO}T00:00:00.000Z`,
      modifiedTime: `${hub.updatedISO}T00:00:00.000Z`,
      images: [seoShareImage],
    },
  }
}

export default async function QuoteHubPage({ params }: QuotePageProps) {
  const { slug } = await params
  const hub = getQuoteHub(slug)
  if (!hub) notFound()

  const faqs = hub.faqs ?? carolFaqs
  const related = gcseQuoteLinks.filter(
    (item) => item.slug !== hub.slug && quoteHubs.some((entry) => entry.slug === item.slug),
  )
  const canonicalUrl = `https://bookquotes.uk/quotes/${hub.slug}`
  const articleSchema = {
    '@context': 'https://schema.org',
    '@type': 'Article',
    headline: hub.title,
    description: hubDescription(hub),
    datePublished: hub.publishedISO,
    dateModified: hub.updatedISO,
    author: { '@type': 'Organization', name: 'BookQuotes', url: 'https://bookquotes.uk/' },
    publisher: { '@type': 'Organization', name: 'BookQuotes', url: 'https://bookquotes.uk/' },
    mainEntityOfPage: canonicalUrl,
    citation: hub.sourceUrl,
  }
  const breadcrumbSchema = {
    '@context': 'https://schema.org',
    '@type': 'BreadcrumbList',
    itemListElement: [
      { '@type': 'ListItem', position: 1, name: 'Home', item: 'https://bookquotes.uk/' },
      { '@type': 'ListItem', position: 2, name: 'Quotes', item: 'https://bookquotes.uk/quotes' },
      { '@type': 'ListItem', position: 3, name: hub.title, item: canonicalUrl },
    ],
  }
  const quotationSchema = {
    '@context': 'https://schema.org',
    '@type': 'ItemList',
    name: hub.title,
    itemListElement: hub.quotes.map((quote, index) => ({
      '@type': 'ListItem',
      position: index + 1,
      item: {
        '@type': 'Quotation',
        text: quote.text,
        ...(quote.speaker === 'Narrator'
          ? {}
          : { spokenByCharacter: { '@type': 'Person', name: quote.speaker } }),
      },
    })),
  }

  return (
    <>
      <Header />
      <main className="pt-8 md:pt-12">
        <article>
          <header className="container-standard pb-10 md:pb-14">
            <Link href="/quotes" className="inline-flex items-center gap-2 font-ui text-sm text-ink-medium mb-10">
              <ArrowLeft className="w-4 h-4" />
              All quotes
            </Link>
            <p className="font-ui text-sm text-ink-medium mb-4">GCSE English Literature</p>
            <h1 className="text-balance mb-6">{hub.title}</h1>
            <p className="text-xl text-ink-dark max-w-2xl mb-4">{hub.lead ?? carolLead}</p>
            <p className="text-lg text-ink-medium max-w-2xl mb-4">
              There are {hub.quotes.length}. {hub.arrangement ?? carolArrangement}
            </p>
            <p className="font-ui text-sm text-ink-medium">
              Source:{' '}
              <a href={hub.sourceUrl} className="underline underline-offset-4" rel="noopener noreferrer">
                {hub.sourceName}
              </a>
              . {hub.sourceNote ?? carolSourceNote}
            </p>
            {related.length > 0 && (
              <p className="text-lg text-ink-dark max-w-2xl mt-4">
                Other GCSE hubs on this site:{' '}
                {related.map((item, index) => (
                  <span key={item.slug}>
                    {index > 0 && (index === related.length - 1 ? ' and ' : ', ')}
                    <Link href={`/quotes/${item.slug}`} className="underline underline-offset-4">
                      {item.label}
                    </Link>
                  </span>
                ))}
                .
              </p>
            )}
          </header>

          <div className="bg-paper-warm border-y border-subtle">
            <div className="container-narrow py-12 md:py-16">
              <QuoteBank
                quotes={hub.quotes}
                sections={hub.sections}
                filterLabel={hub.filterLabel}
                allFilterLabel={hub.allFilterLabel}
                sectionKey={hub.sectionKey}
              />

              <section className="mt-4 pt-10 border-t border-subtle">
                <h2 className="mb-5">Build your own quote bank from the copy you have marked</h2>
                <p className="text-lg text-ink-dark mb-4">
                  A printed list is a start. The bank that helps in an exam is the one you made from your own book: the line you underlined, and a note in your words about why it is there.
                </p>
                <p className="text-lg text-ink-dark mb-4">{hub.appNote ?? carolAppNote}</p>
                <p className="text-lg text-ink-dark mb-6">
                  BookQuotes is an iPhone app for that job. On capture it can detect the page number. You name your own markings, and collections and tags keep one theme together. It does not import Kindle highlights. The steps are written out in{' '}
                  <Link href="/guides/how-to-save-quotes-from-physical-books" className="underline underline-offset-4">
                    how to save quotes from physical books
                  </Link>
                  .
                </p>
                <a
                  href={seoAppStoreUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="btn-primary inline-flex items-center"
                >
                  View BookQuotes on the App Store
                  <ExternalLink className="w-4 h-4 ml-2" />
                </a>
              </section>

              <section className="mt-14 pt-10 border-t border-subtle">
                <h2 className="mb-6">Questions students ask</h2>
                <div className="space-y-7">
                  {faqs.map((faq) => (
                    <div key={faq.question}>
                      <h3 className="text-xl mb-2">{faq.question}</h3>
                      <p className="text-lg text-ink-dark">{faq.answer}</p>
                    </div>
                  ))}
                </div>
              </section>
            </div>
          </div>
        </article>
      </main>
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(articleSchema) }} />
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(breadcrumbSchema) }} />
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(quotationSchema) }} />
      <Footer />
    </>
  )
}
