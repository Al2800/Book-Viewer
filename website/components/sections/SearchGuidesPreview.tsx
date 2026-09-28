import Link from 'next/link'
import { guides } from '@/lib/guides'

export function SearchGuidesPreview() {
  return (
    <section className="section-padding">
      <div className="container-wide">
        <div className="max-w-2xl mb-8">
          <h2 className="mb-3">Guides</h2>
          <p className="text-lg text-ink-medium">
            Short, practical notes on saving, scanning and finding the lines you mark in paper books.
          </p>
        </div>
        <ul className="border-y border-subtle">
          {guides.map((guide) => (
            <li key={guide.slug} className="py-4 border-b border-subtle last:border-b-0">
              <Link href={`/guides/${guide.slug}`} className="font-display text-xl hover:underline">
                {guide.title}
              </Link>
              <p className="text-ink-medium mt-1 max-w-2xl">{guide.description}</p>
            </li>
          ))}
        </ul>
        <p className="mt-8 text-lg text-ink-medium max-w-2xl">
          For lines from a public-domain book, checked against the text, see{' '}
          <Link href="/quotes/a-christmas-carol" className="underline underline-offset-4 text-ink-black">
            A Christmas Carol quotes
          </Link>
          .
        </p>
      </div>
    </section>
  )
}
