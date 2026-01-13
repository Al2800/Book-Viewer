import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: 'BookQuotes — Turn Paper Highlights into a Digital Library',
  description: 'Photograph your underlined passages and margin notes. AI extracts them instantly. Search, organize, and export your reading insights. Free for iOS.',
  keywords: ['book quotes', 'reading app', 'highlight capture', 'margin notes', 'book annotations', 'digital library', 'iOS app'],
  authors: [{ name: 'BookQuotes' }],
  creator: 'BookQuotes',
  metadataBase: new URL('https://bookquotes.app'),
  openGraph: {
    title: 'BookQuotes — Your Paper Highlights, Digitized',
    description: 'Transform underlined passages and margin notes from physical books into a searchable digital library.',
    url: 'https://bookquotes.app',
    siteName: 'BookQuotes',
    locale: 'en_US',
    type: 'website',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'BookQuotes — Your Paper Highlights, Digitized',
    description: 'Transform underlined passages and margin notes from physical books into a searchable digital library.',
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
