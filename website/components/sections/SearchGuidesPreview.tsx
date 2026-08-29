import Link from 'next/link'
import { guides } from '@/lib/guides'

export function SearchGuidesPreview() {
  return (
    <section className="section-padding">
      <div className="container-wide">
        <div className="max-w-2xl mb-12">
          <h2 className="mb-3">Make your marked pages useful again</h2>
          <p className="text-lg text-ink-medium">
            Practical answers for saving quotes, scanning underlined pages, and
            building a reading library you can actually revisit.
          </p>
        </div>
        <div className="border-y border-subtle">
          {guides.slice(0, 3).map((guide) => (
            <article
              key={guide.slug}
              className="grid md:grid-cols-[11rem_1fr] gap-3 md:gap-10 py-8 border-b border-subtle last:border-b-0"
            >
              <p className="font-ui text-sm text-ink-medium">{guide.category}</p>
              <div>
                <h3 className="text-xl mb-3">
                  <Link href={`/guides/${guide.slug}`} className="hover:underline">
                    {guide.title}
                  </Link>
                </h3>
                <p className="text-ink-medium mb-4">{guide.description}</p>
                <Link
                  href={`/guides/${guide.slug}`}
                  className="font-ui text-sm text-ink-black underline underline-offset-4"
                >
                  Read the guide
                </Link>
              </div>
            </article>
          ))}
        </div>
        <p className="mt-8">
          <Link
            href="/guides"
            className="font-ui text-sm text-ink-black underline underline-offset-4"
          >
            See all guides
          </Link>
        </p>
      </div>
    </section>
  )
}
