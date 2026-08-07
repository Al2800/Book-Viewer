import type { MetadataRoute } from 'next'
import { guides } from '@/lib/guides'
import { journalArticles } from '@/lib/journal'

const baseUrl = 'https://bookquotes.uk'

export default function sitemap(): MetadataRoute.Sitemap {
  const staticPages = ['', '/guides', '/journal', '/support', '/privacy', '/terms']
  const guidePages = guides.map((guide) => `/guides/${guide.slug}`)
  const journalPages = journalArticles.map((article) => `/journal/${article.slug}`)

  return [...staticPages, ...guidePages, ...journalPages].map((path) => ({
    url: `${baseUrl}${path}`,
    lastModified: new Date('2026-08-03'),
    changeFrequency: path === '' ? 'weekly' : 'monthly',
    priority: path === '' ? 1 : path.startsWith('/guides/') ? 0.8 : 0.6,
  }))
}
