import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: 'Quote Reader & Book Quote Finder for Physical Books | BookQuotes',
  description: 'A dedicated quote reader and book quote finder for physical books. Unlike a public book quotes website, BookQuotes turns your paper underlines and book highlights into a private, searchable digital library on iPhone and iPad.',
  keywords: [
    'quote reader',
    'book quote finder',
    'book quotes website',
    'book highlights',
    'book quote search',
    'book quotes finder',
    'searchable book quotes',
    'physical book quotes',
    'reading app',
    'highlight capture',
    'margin notes',
    'book annotations',
    'commonplace book',
    'iOS app',
  ],
  authors: [{ name: 'BookQuotes' }],
  creator: 'BookQuotes',
  metadataBase: new URL('https://bookquotes.uk'),
  alternates: { canonical: '/' },
  openGraph: {
    title: 'Quote Reader & Book Quote Finder for Physical Books | BookQuotes',
    description: 'A dedicated quote reader and book quote finder for physical books. Unlike a public book quotes website, BookQuotes turns your paper underlines and book highlights into a private, searchable digital library.',
    url: 'https://bookquotes.uk',
    siteName: 'BookQuotes',
    locale: 'en_GB',
    type: 'website',
    images: [
      {
        url: '/og.png',
        width: 1730,
        height: 909,
        alt: 'BookQuotes — Quote Reader & Book Quote Finder for Physical Books',
      },
    ],
  },
  twitter: {
    card: 'summary_large_image',
    title: 'Quote Reader & Book Quote Finder for Physical Books | BookQuotes',
    description: 'A dedicated quote reader and book quote finder for physical books. Unlike a public book quotes website, BookQuotes turns your paper underlines and book highlights into a private, searchable digital library.',
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
      </body>
    </html>
  )
}
