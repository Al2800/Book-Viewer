import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: 'BookQuotes — Turn Paper Highlights into a Digital Library',
  description: 'Photograph marked book pages, review extracted passages, and build a searchable personal quote library on iPhone and iPad.',
  keywords: ['book quotes', 'reading app', 'highlight capture', 'margin notes', 'book annotations', 'digital library', 'iOS app'],
  authors: [{ name: 'BookQuotes' }],
  creator: 'BookQuotes',
  metadataBase: new URL('https://bookquotes.app'),
  alternates: { canonical: '/' },
  openGraph: {
    title: 'BookQuotes — Your Paper Highlights, Digitized',
    description: 'Transform underlined passages and margin notes from physical books into a searchable digital library.',
    url: 'https://bookquotes.app',
    siteName: 'BookQuotes',
    locale: 'en_GB',
    type: 'website',
    images: [
      {
        url: '/og.png',
        width: 1730,
        height: 909,
        alt: 'BookQuotes — Keep the lines you underlined',
      },
    ],
  },
  twitter: {
    card: 'summary_large_image',
    title: 'BookQuotes — Your Paper Highlights, Digitized',
    description: 'Transform underlined passages and margin notes from physical books into a searchable digital library.',
    images: ['/og.png'],
  },
  robots: {
    index: true,
    follow: true,
  },
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <head>
        <link rel="icon" href="/icons/favicon.ico" sizes="any" />
        <link rel="apple-touch-icon" href="/icons/apple-touch-icon.png" />
      </head>
      <body className="min-h-screen">
        {children}
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{
            __html: JSON.stringify({
              '@context': 'https://schema.org',
              '@type': 'SoftwareApplication',
              name: 'BookQuotes',
              applicationCategory: 'BooksApplication',
              operatingSystem: 'iOS, iPadOS',
              description: 'Capture marked pages from physical books, review extracted passages, and build a searchable personal quote library.',
              url: 'https://bookquotes.app',
              downloadUrl: 'https://apps.apple.com/app/id6758091579',
              publisher: { '@type': 'Organization', name: 'BookQuotes', url: 'https://bookquotes.app' },
              featureList: [
                'Capture marked book pages',
                'Review and edit extracted passages',
                'Search a personal quote library',
                'Organize books, tags and collections',
                'Export saved reading notes',
              ],
            }),
          }}
        />
      </body>
    </html>
  )
}
