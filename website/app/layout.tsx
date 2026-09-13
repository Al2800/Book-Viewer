import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: 'BookQuotes — Book Quote Finder & Quote Reader for Physical Books',
  description: 'A privacy-first book quote finder and quote reader for physical books. Photograph marked pages, capture underlines and margin notes, and search your personal quote library on iOS.',
  keywords: [
    'book quote finder',
    'quote reader',
    'book quote search',
    'book quotes finder',
    'searchable book quotes',
    'book quotes website',
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
    title: 'BookQuotes — Book Quote Finder & Quote Reader for Physical Books',
    description: 'A privacy-first book quote finder and quote reader for physical books. Photograph marked pages, capture underlines and margin notes, and search your personal quote library.',
    url: 'https://bookquotes.uk',
    siteName: 'BookQuotes',
    locale: 'en_GB',
    type: 'website',
    images: [
      {
        url: '/og.png',
        width: 1730,
        height: 909,
        alt: 'BookQuotes — Book Quote Finder & Quote Reader for Physical Books',
      },
    ],
  },
  twitter: {
    card: 'summary_large_image',
    title: 'BookQuotes — Book Quote Finder & Quote Reader for Physical Books',
    description: 'A privacy-first book quote finder and quote reader for physical books. Photograph marked pages, capture underlines and margin notes, and search your personal quote library.',
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
