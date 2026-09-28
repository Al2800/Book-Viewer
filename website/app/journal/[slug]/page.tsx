import type { Metadata } from 'next'
import Link from 'next/link'
import { notFound } from 'next/navigation'
import { ArrowLeft, ExternalLink } from 'lucide-react'
import { Header } from '@/components/layout/Header'
import { Footer } from '@/components/layout/Footer'
import { Button } from '@/components/ui/Button'
import { ProductEvidence } from '@/components/sections/ProductEvidence'
import { getJournalArticle, journalArticles } from '@/lib/journal'
import { seoAppStoreUrl, seoShareImage } from '@/lib/seo'
import { formatLongDate, splitInlineLinks } from '@/lib/utils'

type ArticlePageProps = {
  params: Promise<{ slug: string }>
}

export function generateStaticParams() {
  return journalArticles.map((article) => ({ slug: article.slug }))
}

export async function generateMetadata({ params }: ArticlePageProps): Promise<Metadata> {
  const { slug } = await params
  const article = getJournalArticle(slug)

  if (!article) {
    return {}
  }

  const title = `${article.title} | BookQuotes`

  return {
    title,
    description: article.summary,
    alternates: { canonical: `/journal/${article.slug}` },
    openGraph: {
      title,
      description: article.summary,
      url: `https://bookquotes.uk/journal/${article.slug}`,
      type: 'article',
      publishedTime: `${article.publishedISO}T00:00:00.000Z`,
      modifiedTime: `${article.updatedISO || article.publishedISO}T00:00:00.000Z`,
      section: article.category,
      images: [seoShareImage],
    },
  }
}

export default async function ArticlePage({ params }: ArticlePageProps) {
  const { slug } = await params
  const article = getJournalArticle(slug)

  if (!article) {
    notFound()
  }

  const canonicalUrl = `https://bookquotes.uk/journal/${article.slug}`
  const articleSchema = {
    '@context': 'https://schema.org',
    '@type': 'Article',
    headline: article.title,
    description: article.summary,
    datePublished: article.publishedISO,
    dateModified: article.updatedISO || article.publishedISO,
    author: { '@type': 'Organization', name: 'BookQuotes', url: 'https://bookquotes.uk' },
    publisher: { '@type': 'Organization', name: 'BookQuotes', url: 'https://bookquotes.uk' },
    mainEntityOfPage: canonicalUrl,
  }
  const breadcrumbSchema = {
    '@context': 'https://schema.org',
    '@type': 'BreadcrumbList',
    itemListElement: [
      { '@type': 'ListItem', position: 1, name: 'Home', item: 'https://bookquotes.uk/' },
      { '@type': 'ListItem', position: 2, name: 'Journal', item: 'https://bookquotes.uk/journal' },
      { '@type': 'ListItem', position: 3, name: article.title, item: canonicalUrl },
    ],
  }
  const faqSchema = article.faqs && article.faqs.length > 0 ? {
    '@context': 'https://schema.org',
    '@type': 'FAQPage',
    mainEntity: article.faqs.map((faq) => ({
      '@type': 'Question',
      name: faq.question,
      acceptedAnswer: { '@type': 'Answer', text: faq.answer },
    })),
  } : null

  return (
    <>
      <Header />
      <main className="pt-8 md:pt-12">
        <article>
          <header className="container-standard pb-12 md:pb-16">
            <Link
              href="/journal"
              className="inline-flex items-center gap-2 font-ui text-sm text-ink-medium mb-10"
            >
              <ArrowLeft className="w-4 h-4" />
              Back to Journal
            </Link>
            <p className="font-ui text-sm text-ink-medium mb-4">
              {article.category}
            </p>
            <h1 className="text-balance mb-6">{article.title}</h1>
            <p className="text-xl text-ink-medium max-w-2xl mb-6">{article.summary}</p>
            <p className="font-ui text-sm text-ink-light mb-8">
              Published {formatLongDate(article.publishedISO)}
              {article.updatedISO ? ` · Updated ${formatLongDate(article.updatedISO)}` : ''}
              {' · '}
              {article.readingTime}
            </p>

            <div className="p-5 md:p-6 bg-paper-warm border border-subtle flex flex-col sm:flex-row sm:items-center justify-between gap-4">
              <div>
                <p className="font-display text-lg text-ink-black font-semibold mb-1">
                  A quote reader for physical books
                </p>
                <p className="font-ui text-sm text-ink-medium">
                  Photograph marked pages, extract your underlines, and build a searchable quote library on iPhone and iPad.
                </p>
              </div>
              <a
                href={seoAppStoreUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="shrink-0"
              >
                <Button size="default" className="w-full sm:w-auto">
                  Get the app
                  <ExternalLink className="w-4 h-4 ml-2" />
                </Button>
              </a>
            </div>
          </header>

          <ProductEvidence
            alt="BookQuotes library screen showing search, saved-quote counts, book cards, and grid/list controls without a visible quote passage."
          />

          <div className="bg-paper-warm border-y border-subtle">
            <div className="container-narrow py-12 md:py-16">
              {article.sections.map((section) => (
                <section key={section.heading} className="mb-12 last:mb-0">
                  <h2 className="mb-5">{section.heading}</h2>
                  {section.paragraphs.map((paragraph) => (
                    <p key={paragraph} className="text-lg text-ink-dark mb-5 last:mb-0">
                      <InlineText text={paragraph} />
                    </p>
                  ))}
                  {section.bullets && (
                    <ul className="mt-5 space-y-3 list-disc pl-6 text-lg text-ink-dark">
                      {section.bullets.map((bullet) => (
                        <li key={bullet}>
                          <InlineText text={bullet} />
                        </li>
                      ))}
                    </ul>
                  )}
                </section>
              ))}

              {article.related.length > 0 && (
                <section className="mt-14 pt-10 border-t border-subtle">
                  <h2 className="mb-5">Related reading</h2>
                  <ul className="space-y-3 text-lg">
                    {article.related.map((item) => (
                      <li key={item.href}>
                        <Link href={item.href} className="underline underline-offset-4 hover:text-gold-primary">
                          {item.label}
                        </Link>
                      </li>
                    ))}
                  </ul>
                </section>
              )}

              {article.faqs && article.faqs.length > 0 && (
                <section className="mt-14 pt-10 border-t border-subtle">
                  <h2 className="mb-6">Questions readers ask</h2>
                  <div className="space-y-7">
                    {article.faqs.map((faq) => (
                      <div key={faq.question}>
                        <h3 className="text-xl mb-2">{faq.question}</h3>
                        <p className="text-lg text-ink-dark">{faq.answer}</p>
                      </div>
                    ))}
                  </div>
                </section>
              )}
            </div>
          </div>
        </article>

        <section className="container-standard py-14 md:py-20">
          <h2 className="mb-4">Keep the lines that matter</h2>
          <p className="text-ink-medium text-lg mb-7">
            BookQuotes is available now on iPhone and iPad.
          </p>
          <a
            href={seoAppStoreUrl}
            target="_blank"
            rel="noopener noreferrer"
          >
            <Button size="lg">
              View on the App Store
              <ExternalLink className="w-4 h-4 ml-2" />
            </Button>
          </a>
        </section>
      </main>
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(articleSchema) }} />
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(breadcrumbSchema) }} />
      {faqSchema && (
        <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(faqSchema) }} />
      )}
      <Footer />
    </>
  )
}

function InlineText({ text }: { text: string }) {
  return (
    <>
      {splitInlineLinks(text).map((part, index) =>
        part.type === 'text' ? (
          <span key={index}>{part.value}</span>
        ) : (
          <Link
            key={index}
            href={part.href}
            className="underline underline-offset-4 hover:text-gold-primary"
          >
            {part.label}
          </Link>
        ),
      )}
    </>
  )
}
