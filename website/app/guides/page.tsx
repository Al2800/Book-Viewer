import type { Metadata } from 'next'
import Link from 'next/link'
import { ArrowRight, BookOpen } from 'lucide-react'
import { Header } from '@/components/layout/Header'
import { Footer } from '@/components/layout/Footer'
import { guides } from '@/lib/guides'

export const metadata: Metadata = {
  title: 'Book Reading and Quote Guides | BookQuotes',
  description:
    'Practical guides for saving quotes from physical books, scanning marked pages, digitising notes, and building a searchable reading library.',
  alternates: { canonical: '/guides' },
}

export default function GuidesPage() {
  return (
    <>
      <Header />
      <main className="pt-8 md:pt-12">
        <header className="container-standard pb-14 md:pb-20">
          <p className="font-ui text-sm text-ink-medium mb-4">Guides</p>
          <h1 className="mb-5">Save the ideas you want to find again</h1>
          <p className="text-xl text-ink-medium max-w-2xl">
            Clear, practical answers for readers who underline paper books, keep margin notes, and want a better way to revisit them.
          </p>
        </header>

        <section className="bg-paper-warm border-y border-subtle">
          <div className="container-wide py-6 md:py-10">
            {guides.map((guide, index) => (
              <article
                key={guide.slug}
                className={`grid md:grid-cols-[190px_1fr_auto] gap-4 md:gap-10 py-8 ${
                  index < guides.length - 1 ? 'border-b border-subtle' : ''
                }`}
              >
                <div className="font-ui text-sm text-ink-medium">
                  <p>{guide.category}</p>
                  <p className="mt-1">{guide.readingTime}</p>
                </div>
                <div>
                  <h2 className="text-2xl mb-3">
                    <Link href={`/guides/${guide.slug}`} className="hover:text-gold-primary">
                      {guide.title}
                    </Link>
                  </h2>
                  <p className="text-ink-medium max-w-2xl">{guide.description}</p>
                </div>
                <Link
                  href={`/guides/${guide.slug}`}
                  aria-label={`Read ${guide.title}`}
                  className="self-center text-navy hover:text-gold-primary"
                >
                  <ArrowRight className="w-6 h-6" />
                </Link>
              </article>
            ))}
          </div>
        </section>

        <section className="container-standard py-14 md:py-20">
          <div className="flex gap-4 items-start bg-paper-aged rounded-xl p-6 md:p-8">
            <BookOpen className="w-6 h-6 text-gold-primary shrink-0 mt-1" />
            <div>
              <h2 className="text-2xl mb-3">The principle behind the guides</h2>
              <p className="text-ink-medium">
                The point is not to collect every sentence. It is to keep the passages that matter, preserve their context, and make them available when your future self needs them.
              </p>
            </div>
          </div>
        </section>
      </main>
      <Footer />
    </>
  )
}
