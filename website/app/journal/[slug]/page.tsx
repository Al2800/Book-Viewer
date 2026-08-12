import type { Metadata } from 'next'
import Link from 'next/link'
import { notFound } from 'next/navigation'
import { ArrowLeft, ExternalLink } from 'lucide-react'
import { Header } from '@/components/layout/Header'
import { Footer } from '@/components/layout/Footer'
import { Button } from '@/components/ui/Button'
import { ProductEvidence } from '@/components/sections/ProductEvidence'
import { getJournalArticle, journalArticles } from '@/lib/journal'
import { seoAppStoreUrl } from '@/lib/seo'

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

  return {
    title: `${article.title} | BookQuotes`,
    description: article.summary,
    alternates: { canonical: `/journal/${article.slug}` },
    openGraph: {
      title: `${article.title} | BookQuotes`,
      description: article.summary,
      url: `https://bookquotes.uk/journal/${article.slug}`,
      type: 'article',
      publishedTime: `${article.publishedISO}T00:00:00.000Z`,
      modifiedTime: `${article.publishedISO}T00:00:00.000Z`,
      section: article.category,
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
    dateModified: article.publishedISO,
    author: { '@type': 'Organization', name: 'BookQuotes', url: 'https://bookquotes.uk' },
    publisher: { '@type': 'Organization', name: 'BookQuotes', url: 'https://bookquotes.uk' },
    mainEntityOfPage: canonicalUrl,
  }
  const breadcrumbSchema = {
    '@context': 'https://schema.org',
    '@type': 'BreadcrumbList',
    itemListElement: [
      { '@type': 'ListItem', position: 1, name: 'Home', item: 'https://bookquotes.uk' },
      { '@type': 'ListItem', position: 2, name: 'Journal', item: 'https://bookquotes.uk/journal' },
      { '@type': 'ListItem', position: 3, name: article.title, item: canonicalUrl },
    ],
  }

  return (
    <>
      <Header />
      <main className="pt-28 md:pt-36">
        <article>
          <header className="container-standard pb-12 md:pb-16">
            <Link
              href="/journal"
              className="inline-flex items-center gap-2 font-ui text-sm text-navy mb-10"
            >
              <ArrowLeft className="w-4 h-4" />
              Back to Journal
            </Link>
            <p className="font-ui text-sm font-semibold uppercase text-rust mb-4">
              {article.category}
            </p>
            <h1 className="text-balance mb-6">{article.title}</h1>
            <p className="text-xl text-ink-medium max-w-2xl mb-6">{article.summary}</p>
            <p className="font-ui text-sm text-ink-light">
              {article.published} · {article.readingTime}
            </p>
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
                      {paragraph}
                    </p>
                  ))}
                </section>
              ))}
            </div>
          </div>
        </article>

        <section className="container-standard py-14 md:py-20 text-center">
          <h2 className="mb-4">Keep the Lines That Matter</h2>
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
      <Footer />
    </>
  )
}
