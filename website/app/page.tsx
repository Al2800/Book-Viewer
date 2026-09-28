import { Header } from '@/components/layout/Header'
import { Footer } from '@/components/layout/Footer'
import { Hero } from '@/components/sections/Hero'
import { Problem } from '@/components/sections/Problem'
import { HowItWorks } from '@/components/sections/HowItWorks'
import { Features } from '@/components/sections/Features'
import { HomeFaq, homeFaqs } from '@/components/sections/HomeFaq'
import { JournalPreview } from '@/components/sections/JournalPreview'
import { Pricing } from '@/components/sections/Pricing'
import { SearchGuidesPreview } from '@/components/sections/SearchGuidesPreview'

export default function Home() {
  const softwareAppSchema = {
    '@context': 'https://schema.org',
    '@type': 'SoftwareApplication',
    name: 'BookQuotes',
    applicationCategory: 'BooksApplication',
    operatingSystem: 'iOS, iPadOS',
    description:
      'Save the passages you underline in paper books. BookQuotes keeps them in a private, searchable library on iPhone, with the page number and your own notes.',
    url: 'https://bookquotes.uk/',
    downloadUrl: 'https://apps.apple.com/app/id6758091579',
    publisher: { '@type': 'Organization', name: 'BookQuotes', url: 'https://bookquotes.uk' },
    featureList: [
      'Capture marked book pages',
      'Review and edit extracted passages',
      'Search a personal quote library',
      'Organize books, tags and collections',
      'Export saved reading notes',
    ],
  }

  const faqPageSchema = {
    '@context': 'https://schema.org',
    '@type': 'FAQPage',
    mainEntity: homeFaqs.map((faq) => ({
      '@type': 'Question',
      name: faq.question,
      acceptedAnswer: {
        '@type': 'Answer',
        text: `${faq.answer} ${
          faq.question === 'What is a quote reader for physical books?'
            ? 'Unlike generic document scanner apps that create flat PDF files or require tedious manual typing, a quote reader isolates the specific sentence, paragraph, or margin note you underlined on paper.'
            : faq.question === 'What is a book quotes website vs a quote dump site?'
              ? 'Public quote websites and blogs often strip away publication dates, edition details, page numbers, and the surrounding argument to serve viral one-liners. BookQuotes acts as your personal reading archive instead: every quote anchors to the exact volume in your hands, your own margin reflections, and your private collections, with full export to Obsidian and Notion.'
              : 'You snap a clear photo in natural light, confirm the detected text against the original page image, and attach the verified title and edition via barcode ISBN scan. Once saved, your highlights become instantly searchable offline.'
        }`,
      },
    })),
  }

  return (
    <>
      <Header />
      <main>
        <Hero />
        <Problem />
        <HowItWorks />
        <Features />
        <HomeFaq />
        <SearchGuidesPreview />
        <JournalPreview />
        <Pricing />
      </main>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{
          __html: JSON.stringify(softwareAppSchema),
        }}
      />
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{
          __html: JSON.stringify(faqPageSchema),
        }}
      />
      <Footer />
    </>
  )
}
