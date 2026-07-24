import Link from 'next/link'
import { ArrowRight, BookMarked } from 'lucide-react'
import { journalArticles } from '@/lib/journal'

export function JournalPreview() {
  return (
    <section className="section-padding">
      <div className="container-wide">
        <div className="flex flex-col md:flex-row md:items-end md:justify-between gap-6 mb-10">
          <div>
            <div className="flex items-center gap-2 text-rust font-ui text-sm font-semibold mb-3">
              <BookMarked className="w-5 h-5" />
              The BookQuotes Journal
            </div>
            <h2 className="mb-3">Read, Mark, Remember</h2>
            <p className="text-ink-medium text-lg max-w-2xl">
              Practical ideas for getting more value from paper-book annotations.
            </p>
          </div>
          <Link
            href="/journal"
            className="inline-flex items-center gap-2 text-gold-primary font-ui font-medium"
          >
            Browse the journal
            <ArrowRight className="w-4 h-4" />
          </Link>
        </div>

        <div className="grid md:grid-cols-3 border-y border-subtle">
          {journalArticles.map((article, index) => (
            <article
              key={article.slug}
              className={`py-8 md:px-8 ${index === 0 ? 'md:pl-0' : ''} ${
                index < journalArticles.length - 1 ? 'border-b md:border-b-0 md:border-r border-subtle' : ''
              }`}
            >
              <p className="font-ui text-xs font-semibold uppercase text-rust mb-4">
                {article.category}
              </p>
              <h3 className="text-xl mb-3">
                <Link href={`/journal/${article.slug}`} className="hover:text-gold-primary">
                  {article.title}
                </Link>
              </h3>
              <p className="text-ink-medium mb-5">{article.summary}</p>
              <Link
                href={`/journal/${article.slug}`}
                className="font-ui text-sm font-semibold text-navy inline-flex items-center gap-2"
              >
                Read article
                <ArrowRight className="w-4 h-4" />
              </Link>
            </article>
          ))}
        </div>
      </div>
    </section>
  )
}
