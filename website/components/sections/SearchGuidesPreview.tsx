import Link from 'next/link'
import { ArrowRight, Search } from 'lucide-react'
import { guides } from '@/lib/guides'

export function SearchGuidesPreview() {
  return (
    <section className="section-padding bg-paper-warm border-y border-subtle">
      <div className="container-wide">
        <div className="flex flex-col md:flex-row md:items-end md:justify-between gap-6 mb-10">
          <div>
            <div className="flex items-center gap-2 text-rust font-ui text-sm font-semibold mb-3">
              <Search className="w-5 h-5" />
              Reading guides
            </div>
            <h2 className="mb-3">Make your marked pages useful again</h2>
            <p className="text-ink-medium text-lg max-w-2xl">
              Practical answers for saving quotes, scanning underlined pages, and building a reading library you can actually revisit.
            </p>
          </div>
          <Link
            href="/guides"
            className="inline-flex items-center gap-2 text-gold-primary font-ui font-medium"
          >
            See all guides
            <ArrowRight className="w-4 h-4" />
          </Link>
        </div>

        <div className="grid md:grid-cols-3 gap-5">
          {guides.slice(0, 3).map((guide) => (
            <article key={guide.slug} className="bg-paper-cream border border-subtle rounded-xl p-6">
              <p className="font-ui text-xs font-semibold uppercase tracking-wide text-rust mb-4">
                {guide.category}
              </p>
              <h3 className="text-xl mb-3">
                <Link href={`/guides/${guide.slug}`} className="hover:text-gold-primary">
                  {guide.title}
                </Link>
              </h3>
              <p className="text-ink-medium mb-5">{guide.description}</p>
              <Link
                href={`/guides/${guide.slug}`}
                className="font-ui text-sm font-semibold text-navy inline-flex items-center gap-2"
              >
                Read the guide
                <ArrowRight className="w-4 h-4" />
              </Link>
            </article>
          ))}
        </div>
      </div>
    </section>
  )
}
