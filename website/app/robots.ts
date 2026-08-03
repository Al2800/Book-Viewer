import type { MetadataRoute } from 'next'

export default function robots(): MetadataRoute.Robots {
  return {
    rules: { userAgent: '*', allow: '/' },
    sitemap: 'https://bookquotes.app/sitemap.xml',
    host: 'https://bookquotes.app',
  }
}
