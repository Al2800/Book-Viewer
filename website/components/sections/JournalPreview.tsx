import Link from 'next/link'
import { journalArticles } from '@/lib/journal'

export function JournalPreview() {
  return (
    <section className="bg-paper-warm">
      <div className="container-wide section-padding">
        <div className="max-w-2xl mb-12">
          <h2 className="mb-3">Read, mark, remember</h2>
          <p className="text-lg text-ink-medium">
            Practical ideas for getting more value from paper-book annotations.
          </p>
        </div>
        <div className="border-y border-subtle">
          {journalArticles.map((article) => (
            <article
              key={article.slug}
              className="grid md:grid-cols-[11rem_1fr] gap-3 md:gap-10 py-8 border-b border-subtle last:border-b-0"
            >
              <p className="font-ui text-sm text-ink-medium">{article.category}</p>
              <div>
                <h3 className="text-xl mb-3">
                  <Link href={`/journal/${article.slug}`} className="hover:underline">
                    {article.title}
                  </Link>
                </h3>
                <p className="text-ink-medium mb-4">{article.summary}</p>
                <Link
                  href={`/journal/${article.slug}`}
                  className="font-ui text-sm text-ink-black underline underline-offset-4"
                >
                  Read article
                </Link>
              </div>
            </article>
          ))}
        </div>
        <p className="mt-8">
          <Link
            href="/journal"
            className="font-ui text-sm text-ink-black underline underline-offset-4"
          >
            Browse the journal
          </Link>
        </p>
      </div>
    </section>
  )
}
