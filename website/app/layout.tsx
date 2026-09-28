import type { Metadata } from 'next'
import './globals.css'

const homeTitle = 'Save quotes from paper books on iPhone | BookQuotes'
const homeDescription =
  'Save the passages you underline in paper books. BookQuotes keeps them in a private, searchable library on iPhone, with the page number and your own notes.'

export const metadata: Metadata = {
  title: homeTitle,
  description: homeDescription,
  authors: [{ name: 'BookQuotes' }],
  creator: 'BookQuotes',
  metadataBase: new URL('https://bookquotes.uk'),
  alternates: { canonical: '/' },
  openGraph: {
    title: homeTitle,
    description: homeDescription,
    url: 'https://bookquotes.uk/',
    siteName: 'BookQuotes',
    locale: 'en_GB',
    type: 'website',
    images: [
      {
        url: '/og.png',
        width: 1730,
        height: 909,
        alt: 'BookQuotes: save quotes from paper books on iPhone',
      },
    ],
  },
  twitter: {
    card: 'summary_large_image',
    title: homeTitle,
    description: homeDescription,
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
