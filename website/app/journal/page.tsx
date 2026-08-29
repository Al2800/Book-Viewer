import type { Metadata } from 'next'
import Link from 'next/link'
import { ArrowRight } from 'lucide-react'
import { Header } from '@/components/layout/Header'
import { Footer } from '@/components/layout/Footer'
import { journalArticles } from '@/lib/journal'

export const metadata: Metadata = {
  title: 'Journal | BookQuotes',
  description: 'Practical ideas for book annotation, commonplace books, and remembering what you read.',
  alternates: { canonical: '/journal' },
}

export default function JournalPage() {
  return (
    <>
      <Header />
      <main className="pt-8 md:pt-12">
        <header className="container-standard pb-14 md:pb-20">
          <p className="font-ui text-sm text-ink-medium mb-4">Journal</p>
          <h1 className="mb-5">Read, mark, remember</h1>
          <p className="text-xl text-ink-medium max-w-2xl">
            Practical methods for keeping the ideas you find in paper books.
          </p>
        </header>

        <section className="bg-paper-warm border-y border-subtle">
          <div className="container-wide py-6 md:py-10">
            {journalArticles.map((article, index) => (
              <article
                key={article.slug}
                className={`grid md:grid-cols-[180px_1fr_auto] gap-4 md:gap-10 py-8 ${
                  index < journalArticles.length - 1 ? 'border-b border-subtle' : ''
                }`}
              >
                <div className="font-ui text-sm text-ink-medium">
                  <p>{article.category}</p>
                  <p className="mt-1">{article.readingTime}</p>
                </div>
                <div>
                  <h2 className="text-2xl mb-3">
                    <Link href={`/journal/${article.slug}`} className="hover:text-gold-primary">
                      {article.title}
                    </Link>
                  </h2>
                  <p className="text-ink-medium max-w-2xl">{article.summary}</p>
                </div>
                <Link
                  href={`/journal/${article.slug}`}
                  aria-label={`Read ${article.title}`}
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
