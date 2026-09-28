import type { Metadata } from 'next'
import Link from 'next/link'
import { ArrowRight } from 'lucide-react'
import { Header } from '@/components/layout/Header'
import { Footer } from '@/components/layout/Footer'
import { quoteHubs } from '@/lib/quotes'

const title = 'Quotes checked against the original text | BookQuotes'
const description =
  'Public-domain lines checked against a named text before they are published: GCSE set texts, and quotes about reading with the book named.'

export const metadata: Metadata = {
  title,
  description,
  alternates: { canonical: '/quotes' },
  openGraph: {
    title,
    description,
    url: 'https://bookquotes.uk/quotes',
    siteName: 'BookQuotes',
    locale: 'en_GB',
    type: 'website',
  },
}

export default function QuotesPage() {
  return (
    <>
      <Header />
      <main className="pt-8 md:pt-12">
        <header className="container-standard pb-14 md:pb-20">
          <p className="font-ui text-sm text-ink-medium mb-4">Quotes</p>
          <h1 className="mb-5">Quotes checked against the original text</h1>
          <p className="text-xl text-ink-medium max-w-2xl">
            Public-domain books, with the lines a student or a reader actually needs. Every quotation is checked against a named text. A line is left out if it only sounds familiar.
          </p>
          <p className="text-lg text-ink-medium max-w-2xl mt-4">
            For the set texts, the{' '}
            <Link href="/guides/gcse-english-quote-bank" className="underline underline-offset-4 text-ink-black">
              GCSE English literature quote bank
            </Link>{' '}
            lists every literature hub published here, and how to learn a short line from it.
          </p>
        </header>

        <section className="bg-paper-warm border-y border-subtle">
          <div className="container-wide py-6 md:py-10">
            {quoteHubs.map((hub) => (
              <article key={hub.slug} className="grid md:grid-cols-[190px_1fr_auto] gap-4 md:gap-10 py-8">
                <div className="font-ui text-sm text-ink-medium">
                  <p>{hub.indexLabel ?? 'GCSE English'}</p>
                  <p className="mt-1">{hub.quotes.length} quotes</p>
                </div>
                <div>
                  <h2 className="text-2xl mb-3">
                    <Link href={`/quotes/${hub.slug}`} className="hover:text-gold-primary">
                      {hub.title}
                    </Link>
                  </h2>
                  <p className="text-ink-medium max-w-2xl">{hub.description}</p>
                </div>
                <Link
                  href={`/quotes/${hub.slug}`}
                  aria-label={`Read ${hub.title}`}
                  className="self-center text-navy hover:text-gold-primary"
                >
                  <ArrowRight className="w-6 h-6" />
                </Link>
              </article>
            ))}
          </div>
        </section>
      </main>
      <Footer />
    </>
  )
}
