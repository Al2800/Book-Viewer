export type JournalSection = {
  heading: string
  paragraphs: string[]
  bullets?: string[]
}

export type JournalFaq = {
  question: string
  answer: string
}

export type JournalArticle = {
  slug: string
  title: string
  summary: string
  category: string
  readingTime: string
  published: string
  publishedISO: string
  updatedISO?: string
  related: { href: string; label: string }[]
  sections: JournalSection[]
  faqs?: JournalFaq[]
}

export const journalArticles: JournalArticle[] = [
  {
    slug: 'what-to-do-with-book-highlights',
    title: 'What to Do with Highlights After a Book',
    summary:
      'What to do with book highlights once you close the book: filter the underlines, save the paper passages, and keep a private library you can search later.',
    category: 'Annotation',
    readingTime: '6 min read',
    published: '24 July 2026',
    publishedISO: '2026-07-24',
    updatedISO: '2026-09-28',
    related: [
      { href: '/guides/digital-commonplace-book', label: 'What is a digital commonplace book?' },
      { href: '/guides/how-to-save-quotes-from-physical-books', label: 'How to save quotes from physical books' },
      { href: '/guides/export-book-quotes-to-obsidian', label: 'Export book quotes to Obsidian and Notion' },
      { href: '/guides/book-quotes-vs-kindle-highlights', label: 'Book quotes vs Kindle highlights' },
    ],
    sections: [
      {
        heading: 'Why most book highlights get abandoned',
        paragraphs: [
          'Underlining a book while reading gives an immediate feeling of accomplishment. A pencil glides under a striking sentence, a margin bracket captures a tight argument, and for a moment, it feels as though the insight has settled permanently into your memory.',
          'Then you reach the final chapter, close the volume, and slot it back on the shelf. Months later, you remember that the author made a sharp point about attention or habit, but the exact phrasing, the page number, and the context are stranded in paper. Because transcribing quotes by hand is slow and typing them into a document feels like office administration, most book highlights remain locked inside closed covers.',
          'Highlighting is only the first half of reading. The second half is deciding what to do with those book highlights once the reading is done.',
        ],
      },
      {
        heading: 'The 24-hour cooling-off rule',
        paragraphs: [
          'The most common mistake is trying to process your book highlights the moment you reach the final page. When a book is fresh, every marked sentence still carries emotional momentum. Everything feels equally profound because the narrative tension is still vibrating in your head.',
          'Give the book a day or two of quiet space. When you return with cool eyes, leaf back through your dog-ears, pencil marks, and slips of paper. The passages that still carry genuine weight will stand out clearly from clever turns of phrase that only felt urgent in the flow of the chapter.',
          'A disciplined target is five to ten passages for an average non-fiction work, or the few sentences that best preserve the atmosphere and voice of a novel. Curation is what keeps a reading collection alive.',
        ],
      },
      {
        heading: 'Filter your highlights before saving them',
        paragraphs: [
          'A useful quote library is defined by what you leave out. If you keep every sentence you underlined, you build a second reading backlog. A [commonplace book](/guides/digital-commonplace-book) stays small on purpose.',
          'Treat your initial paper marks as candidates rather than permanent fixtures. Ask three simple questions during your review: Does this sentence articulate an idea better than I could? Does it challenge an assumption I currently hold? Will I genuinely want to cite or re-read this twelve months from now?',
          'If a mark fails those tests, leave it on the paper page. It served its purpose by sharpening your focus while reading. Only the lines that pass deserve a place in your searchable archive.',
        ],
      },
      {
        heading: 'Capture paper highlights without manual typing',
        paragraphs: [
          'Typing the lines out by hand is the step most people drop. You need a laptop, a blank document, and one hand on the book so the page stays flat. That is a lot of fuss for a sentence, and it rarely lasts a year of reading.',
          'Photograph the marked page in ordinary light, let OCR or AI extraction isolate the underlined sentence, and compare the detected words with the printed page. [How to save quotes from physical books](/guides/how-to-save-quotes-from-physical-books) is the same routine written out.',
          'Scanning the book barcode ISBN attaches the catalogue title and author automatically, while you verify the page number and line breaks. You get a faithful digital record of the author words without interrupting your evening.',
        ],
      },
      {
        heading: 'Attach why the passage stopped you',
        paragraphs: [
          'An isolated quote easily loses its context. When you re-read a passage two years down the line, you may wonder what on earth compelled you to underline it.',
          'Alongside the author text, record a single concise sentence answering one question: why did this stop me? A note such as “Use when revising the team onboarding doc” or “Contradicts Kahneman on intuitive judgment” connects the author thought to your own life.',
          'Keep your personal reflection clearly separated from the author prose. Maintaining this boundary prevents accidental misattribution later when drafting articles, preparing presentations, or writing essays.',
        ],
      },
      {
        heading: 'Put your highlights to work with search and export',
        paragraphs: [
          'Book highlights should not sit in an intellectual museum. The point of digitising reading notes is to have them reappear at the moment you need them: while drafting an essay, preparing a talk, or thinking through a stubborn problem.',
          'Keep the notes in a private library on the phone. Search looks through the passage, the margin note, the title and the author. It does not search tag names. When you want the notes on a computer, export one book or the whole library as Markdown, plain text, JSON, Notion or Obsidian.',
          'When your physical reading feeds your everyday thinking and writing tools, the physical book can rest on your shelf while its best ideas remain within arm reach.',
        ],
      },
    ],
    faqs: [
      {
        question: 'What should I do with my book highlights after finishing a book?',
        answer:
          'After finishing a book, wait twenty-four to forty-eight hours, review your underlines with fresh eyes, select the five to ten passages that truly matter, and save them into a searchable personal library. Giving yourself a short cooling-off period prevents highlight hoarding and ensures your collection holds only the ideas you will genuinely revisit and put to work.',
      },
      {
        question: 'How do I digitise highlights from physical paper books?',
        answer:
          'Photograph the marked page in BookQuotes. The app reads the line with on-device OCR, or with remote AI if you are signed in and you agree to send the page. You check the words before saving. An ISBN scan can fill in the title and author. The page number is the one printed on the photo, or the one you type. It is not guaranteed.',
      },
      {
        question: 'How many book highlights should you keep from an average book?',
        answer:
          'Five to ten lines from an ordinary non-fiction book is enough to find again later. A few dozen excerpts turn into a second book you will not reopen. Keep the sentences that still say what you wanted from the chapter, and leave the rest on the paper.',
      },
      {
        question: 'Is it better to keep book highlights in an app or a physical commonplace notebook?',
        answer:
          'A physical commonplace book is pleasant to keep. An on-device library adds search, tags and export across the paper books you have already marked. Many readers do both: pencil in the book, then save the lines they still want into a private app.',
      },
    ],
  },
  {
    slug: 'ai-extraction-and-reader-control',
    title: 'AI Extraction and Reader Control',
    summary:
      'What leaves the device, what stays local, and why every extracted passage is reviewed before saving.',
    category: 'Product and privacy',
    readingTime: '4 min read',
    published: '24 July 2026',
    publishedISO: '2026-07-24',
    updatedISO: '2026-09-28',
    related: [
      { href: '/guides/private-book-notes-app-iphone', label: 'Privacy-first book notes on iPhone' },
      { href: '/privacy', label: 'Privacy policy' },
      { href: '/guides/scan-underlined-book-pages', label: 'How to scan underlined book pages' },
    ],
    sections: [
      {
        heading: 'Remote AI is optional',
        paragraphs: [
          'BookQuotes can use remote AI to identify marked passages for eligible subscribers. This happens only after sign-in and explicit consent to send the relevant page image for processing.',
          'Book cover details follow a different route. Books are added by ISBN catalogue lookup or manual entry; cover photographs are not sent to an AI provider for identification.',
        ],
      },
      {
        heading: 'The reader reviews the result',
        paragraphs: [
          'Extraction is not treated as a final answer. The app presents the detected passage for review so that the reader can correct wording, boundaries, page numbers, and notes before saving.',
          'That review step is especially important for unusual layouts, faint marks, curved pages, and annotations that cross more than one paragraph.',
        ],
      },
      {
        heading: 'The library stays local',
        paragraphs: [
          'Books, quotes, tags, collections, and captured images remain on the device in the current release. When remote processing is unavailable, the app offers an on-device fallback and clear recovery choices.',
          'BookQuotes does not use advertising or behavioural tracking. The [privacy policy](/privacy) and the in-app consent controls describe the remote processing flow in more detail. The [privacy guide](/guides/private-book-notes-app-iphone) is the shorter version for someone deciding whether to use the app.',
        ],
      },
    ],
  },
]

export function getJournalArticle(slug: string) {
  return journalArticles.find((article) => article.slug === slug)
}
