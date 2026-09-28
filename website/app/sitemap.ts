import type { MetadataRoute } from 'next'
import { guides } from '@/lib/guides'
import { journalArticles } from '@/lib/journal'

const baseUrl = 'https://bookquotes.uk'
const revisedOn = new Date('2026-09-28T00:00:00.000Z')

export default function sitemap(): MetadataRoute.Sitemap {
  const staticPages: { path: string; lastModified: Date; changeFrequency: 'weekly' | 'monthly'; priority: number }[] = [
    { path: '/', lastModified: revisedOn, changeFrequency: 'weekly', priority: 1.0 },
    { path: '/guides', lastModified: revisedOn, changeFrequency: 'weekly', priority: 0.8 },
    { path: '/journal', lastModified: revisedOn, changeFrequency: 'weekly', priority: 0.8 },
    { path: '/support', lastModified: revisedOn, changeFrequency: 'monthly', priority: 0.5 },
    { path: '/privacy', lastModified: revisedOn, changeFrequency: 'monthly', priority: 0.3 },
    { path: '/terms', lastModified: revisedOn, changeFrequency: 'monthly', priority: 0.3 },
  ]

  const guidePages = guides.map((guide) => ({
    url: `${baseUrl}/guides/${guide.slug}`,
    lastModified: new Date(`${guide.updatedISO}T00:00:00.000Z`),
    changeFrequency: 'monthly' as const,
    priority: 0.8,
  }))

  const journalPages = journalArticles.map((article) => ({
    url: `${baseUrl}/journal/${article.slug}`,
    lastModified: new Date(article.updatedISO ? `${article.updatedISO}T00:00:00.000Z` : `${article.publishedISO}T00:00:00.000Z`),
    changeFrequency: 'monthly' as const,
    priority: 0.7,
  }))

  return [
    ...staticPages.map((page) => ({
      url: `${baseUrl}${page.path}`,
      lastModified: page.lastModified,
      changeFrequency: page.changeFrequency,
      priority: page.priority,
    })),
    ...guidePages,
    ...journalPages,
  ]
}
