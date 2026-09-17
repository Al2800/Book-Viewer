import Link from 'next/link'

export const homeFaqs = [
  {
    question: 'What is a quote reader for physical books?',
    answer:
      'A quote reader for physical books is a tool that captures marked passages directly from printed pages and turns them into searchable digital text, complete with book title, author, and page citation.',
    detail: (
      <>
        Unlike generic document scanner apps that create flat PDF files or require tedious manual
        typing, a quote reader isolates the specific sentence, paragraph, or margin note you
        underlined on paper. For a step-by-step breakdown of how paper passages move to iPhone, read
        our guide to the{' '}
        <Link
          href="/guides/quote-reader-app-for-physical-books"
          className="text-ink-black underline underline-offset-4 font-medium hover:text-gold-primary"
        >
          quote reader app for physical books
        </Link>
        .
      </>
    ),
  },
  {
    question: 'What is a book quotes website vs a quote dump site?',
    answer:
      'A personal book quotes website or library is a private, indexed record of passages you personally read and marked, whereas a quote dump site is a public catalogue of popular, out-of-context snippets.',
    detail: (
      <>
        Public quote websites and blogs often strip away publication dates, edition details, page
        numbers, and the surrounding argument to serve viral one-liners. BookQuotes acts as your
        personal reading archive instead: every quote anchors to the exact volume in your hands,
        your own margin reflections, and your private collections, with full export to Obsidian and
        Notion.
      </>
    ),
  },
  {
    question: 'How does BookQuotes capture highlights from paper?',
    answer:
      'BookQuotes captures highlights from paper by photographing the marked page, extracting the underlined or highlighted passage using optical recognition or optional remote AI, and letting you verify the wording before saving.',
    detail: (
      <>
        You snap a clear photo in natural light, confirm the detected text against the original page
        image, and attach the verified title and edition via barcode ISBN scan. Once saved, your
        highlights become instantly searchable offline. To see how to handle your notes after
        finishing a book, explore our journal on{' '}
        <Link
          href="/journal/what-to-do-with-book-highlights"
          className="text-ink-black underline underline-offset-4 font-medium hover:text-gold-primary"
        >
          what to do with book highlights
        </Link>
        , or read our practical guide on{' '}
        <Link
          href="/guides/how-to-digitise-book-notes"
          className="text-ink-black underline underline-offset-4 font-medium hover:text-gold-primary"
        >
          how to digitise book notes
        </Link>
        .
      </>
    ),
  },
]

export function HomeFaq() {
  return (
    <section id="faq" className="section-padding-loose">
      <div className="container-standard">
        <h2 className="mb-3">Frequently asked questions</h2>
        <p className="text-lg text-ink-medium max-w-prose mb-12">
          Clear answers on quote readers, personal book quote libraries, and capturing paper
          highlights.
        </p>
        <div className="space-y-10 border-t border-subtle pt-8">
          {homeFaqs.map((faq) => (
            <div key={faq.question} className="max-w-prose">
              <h3 className="text-xl mb-3">{faq.question}</h3>
              <p className="text-lg text-ink-dark mb-3 leading-relaxed">{faq.answer}</p>
              <p className="text-base text-ink-medium leading-relaxed">{faq.detail}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
