import { Header } from '@/components/layout/Header'
import { Footer } from '@/components/layout/Footer'
import { Hero } from '@/components/sections/Hero'
import { Problem } from '@/components/sections/Problem'
import { HowItWorks } from '@/components/sections/HowItWorks'
import { Features } from '@/components/sections/Features'
import { JournalPreview } from '@/components/sections/JournalPreview'
import { Pricing } from '@/components/sections/Pricing'
import { SearchGuidesPreview } from '@/components/sections/SearchGuidesPreview'

export default function Home() {
  return (
    <>
      <Header />
      <main>
        <Hero />
        <Problem />
        <HowItWorks />
        <Features />
        <SearchGuidesPreview />
        <JournalPreview />
        <Pricing />
      </main>
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
            url: 'https://bookquotes.uk',
            downloadUrl: 'https://apps.apple.com/app/id6758091579',
            publisher: { '@type': 'Organization', name: 'BookQuotes', url: 'https://bookquotes.uk' },
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
      <Footer />
    </>
  )
}
