import type { Metadata } from 'next'
import Link from 'next/link'
import { ArrowLeft, ExternalLink } from 'lucide-react'
import { notFound } from 'next/navigation'
import { Header } from '@/components/layout/Header'
import { Footer } from '@/components/layout/Footer'
import { Button } from '@/components/ui/Button'
import { ProductEvidence } from '@/components/sections/ProductEvidence'
import { getGuide, guides } from '@/lib/guides'
import { seoAppStoreUrl, seoShareImage } from '@/lib/seo'

type GuidePageProps = {
  params: Promise<{ slug: string }>
}

export function generateStaticParams() {
  return guides.map((guide) => ({ slug: guide.slug }))
}

export async function generateMetadata({ params }: GuidePageProps): Promise<Metadata> {
  const { slug } = await params
  const guide = getGuide(slug)

  if (!guide) return {}

  return {
    title: `${guide.title} | BookQuotes`,
    description: guide.description,
    keywords: [guide.query, ...guide.relatedQueries],
    alternates: { canonical: `/guides/${guide.slug}` },
    openGraph: {
      title: `${guide.title} | BookQuotes`,
      description: guide.description,
      type: 'article',
      publishedTime: '2026-08-03T00:00:00:00.000Z',
      modifiedTime: '2026-08-03T00:00:00:00.000Z',
      section: guide.category,
      images: [seoShareImage],
    },
  }
}

export default async function GuidePage({ params }: GuidePageProps) {
  const { slug } = await params
  const guide = getGuide(slug)

  if (!guide) notFound()

  const articleSchema = {
    '@context': 'https://schema.org',
    '@type': 'Article',
    headline: guide.title,
    description: guide.description,
    dateModified: '2026-08-03',
    datePublished: '2026-08-03',
    author: { '@type': 'Organization', name: 'BookQuotes', url: 'https://bookquotes.uk' },
    publisher: { '@type': 'Organization', name: 'BookQuotes', url: 'https://bookquotes.uk' },
    mainEntityOfPage: `https://bookquotes.uk/guides/${guide.slug}`,
  }

  const breadcrumbSchema = {
    '@context': 'https://schema.org',
    '@type': 'BreadcrumbList',
    itemListElement: [
      { '@type': 'ListItem', position: 1, name: 'Home', item: 'https://bookquotes.uk' },
      { '@type': 'ListItem', position: 2, name: 'Guides', item: 'https://bookquotes.uk/guides' },
      { '@type': 'ListItem', position: 3, name: guide.title, item: `https://bookquotes.uk/guides/${guide.slug}` },
    ],
  }

  const faqSchema = {
    '@context': 'https://schema.org',
    '@type': 'FAQPage',
    mainEntity: guide.faqs.map((faq) => ({
      '@type': 'Question',
      name: faq.question,
      acceptedAnswer: { '@type': 'Answer', text: faq.answer },
    })),
  }

  return (
    <>
      <Header />
      <main className="pt-8 md:pt-12">
        <article>
          <header className="container-standard pb-12 md:pb-16">
            <Link href="/guides" className="inline-flex items-center gap-2 font-ui text-sm text-ink-medium mb-10">
              <ArrowLeft className="w-4 h-4" />
              Back to guides
            </Link>
            <p className="font-ui text-sm text-ink-medium mb-4">{guide.category}</p>
            <h1 className="text-balance mb-6">{guide.title}</h1>
            <p className="text-xl text-ink-medium max-w-2xl mb-6">{guide.intro}</p>
            <div className="flex flex-wrap gap-x-4 gap-y-2 font-ui text-sm text-ink-light">
              <span>Updated {guide.updated}</span>
              <span>{guide.readingTime}</span>
              <span>Primary search: {guide.query}</span>
            </div>
          </header>

          <ProductEvidence
            alt="BookQuotes library screen showing search, saved-quote counts, book cards, and grid/list controls without a visible quote passage."
          />

          <div className="bg-paper-warm border-y border-subtle">
            <div className="container-narrow py-12 md:py-16">
              {guide.sections.map((section) => (
                <section key={section.heading} className="mb-12 last:mb-0">
                  <h2 className="mb-5">{section.heading}</h2>
                  {section.paragraphs.map((paragraph) => (
                    <p key={paragraph} className="text-lg text-ink-dark mb-5 last:mb-0">{paragraph}</p>
                  ))}
                  {section.bullets && (
                    <ul className="mt-5 space-y-3 list-disc pl-6 text-lg text-ink-dark">
                      {section.bullets.map((bullet) => <li key={bullet}>{bullet}</li>)}
                    </ul>
                  )}
                </section>
              ))}

              <section className="mt-14 pt-10 border-t border-subtle">
                <h2 className="mb-6">Questions readers ask</h2>
                <div className="space-y-7">
                  {guide.faqs.map((faq) => (
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

        <section className="container-standard py-14 md:py-20">
          <h2 className="mb-4">Keep the lines that matter</h2>
          <p className="text-ink-medium text-lg mb-7">BookQuotes is available on iPhone and iPad.</p>
          <a href={seoAppStoreUrl} target="_blank" rel="noopener noreferrer">
            <Button size="lg">
              View BookQuotes on the App Store
              <ExternalLink className="w-4 h-4 ml-2" />
            </Button>
          </a>
        </section>
      </main>
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(articleSchema) }} />
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(breadcrumbSchema) }} />
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(faqSchema) }} />
      <Footer />
    </>
  )
}
