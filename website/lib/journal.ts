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
  sections: JournalSection[]
  faqs?: JournalFaq[]
}

export const journalArticles: JournalArticle[] = [
  {
    slug: 'build-a-digital-commonplace-book',
    title: 'How to Build a Digital Commonplace Book from Paper Books',
    summary:
      'A simple system for keeping the passages you underline without turning reading into administration.',
    category: 'Reading practice',
    readingTime: '5 min read',
    published: '24 July 2026',
    publishedISO: '2026-07-24',
    sections: [
      {
        heading: 'Start with a reason to keep the line',
        paragraphs: [
          'A commonplace book is a personal collection of ideas, passages, observations, and questions. Its value does not come from collecting everything. It comes from keeping the things you expect to revisit.',
          'When a sentence earns an underline, pause long enough to ask why. It may explain an idea clearly, challenge an assumption, or give language to something you already felt. That short reason is often more useful than a complicated tagging system.',
        ],
      },
      {
        heading: 'Use one dependable capture ritual',
        paragraphs: [
          'Finish the page before reaching for your phone. Then photograph the marked passage, review the extracted text, and correct anything that the camera or extraction missed. Keep the book title and page number with the quote whenever possible.',
          'The review matters. A searchable transcription is useful only when it still says what the author wrote. Treat extraction as a first draft and let your own eyes make the final decision.',
        ],
      },
      {
        heading: 'Return to the collection',
        paragraphs: [
          'A commonplace book becomes valuable through reuse. Search it while writing, revisit a few saved passages at the end of each week, or choose one idea to discuss with somebody else.',
          'BookQuotes supports this paper-to-library workflow: add the book by ISBN, capture marked pages, review the result, and keep the passage in a searchable local library.',
        ],
      },
    ],
  },
  {
    slug: 'what-to-do-with-book-highlights',
    title: 'What to Do with Book Highlights After Finishing a Book: A Practical Review System',
    summary:
      'What to do with book highlights once you close the back cover: how to filter your underlines, extract paper passages, and turn reading notes into a searchable personal library.',
    category: 'Annotation',
    readingTime: '6 min read',
    published: '24 July 2026',
    publishedISO: '2026-07-24',
    updatedISO: '2026-09-17',
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
          'A useful quote library is defined by what you choose to discard. If you preserve every sentence you underlined, you do not build a commonplace book—you create a second unmanageable reading backlog.',
          'Treat your initial paper marks as candidates rather than permanent fixtures. Ask three simple questions during your review: Does this sentence articulate an idea better than I could? Does it challenge an assumption I currently hold? Will I genuinely want to cite or re-read this twelve months from now?',
          'If a mark fails those tests, leave it on the paper page. It served its purpose by sharpening your focus while reading. Only the lines that pass deserve a place in your searchable archive.',
        ],
      },
      {
        heading: 'Capture paper highlights without manual typing',
        paragraphs: [
          'Manual transcription is where good reading intentions go to die. Setting up a laptop, opening a blank document, and typing out long paragraphs from a paperback with one hand holding the binding open creates too much friction to sustain over a year of reading.',
          'A dedicated quote reader cuts the capture ritual down to seconds. Photograph the marked page in natural light, allow optical recognition or AI extraction to isolate the underlined sentence, and compare the detected words directly against the printed page.',
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
          'Store your notes in a private, local library where you can search across every book you own by keyword, author, or tag. When you want to work on a larger project, export your collection directly into Markdown, Obsidian, or Notion.',
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
          'You can digitise physical book highlights by photographing the marked page with a quote reader app like BookQuotes, which extracts the underlined text, transcribes the passage, and pairs it with the book ISBN and page number. This bypasses the friction of manual keyboard typing while ensuring exact page citations and author attribution.',
      },
      {
        question: 'How many book highlights should you keep from an average book?',
        answer:
          'Keeping five to ten carefully curated book highlights is usually ideal for both retention and practical retrieval. Saving dozens of excerpts creates an unmanageable archive that you will rarely revisit. A concise selection of the most transformative thoughts preserves the book core argument without clutter.',
      },
      {
        question: 'Is it better to keep book highlights in an app or a physical commonplace notebook?',
        answer:
          'A physical commonplace book offers tactile satisfaction, but an on-device digital quote reader gives you instant keyword search, tag filtering, and export across your entire physical library. Many readers find the best balance is reading quietly with pencil in hand, then digitising their chosen highlights into a private app for effortless retrieval.',
      },
    ],
  },
  {
    slug: 'ai-extraction-and-reader-control',
    title: 'How BookQuotes Handles AI Extraction and Reader Control',
    summary:
      'What leaves the device, what stays local, and why every extracted passage is reviewed before saving.',
    category: 'Product and privacy',
    readingTime: '4 min read',
    published: '24 July 2026',
    publishedISO: '2026-07-24',
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
          'BookQuotes does not use advertising or behavioural tracking. The privacy policy and in-app consent controls describe the remote processing flow in more detail.',
        ],
      },
    ],
  },
]

export function getJournalArticle(slug: string) {
  return journalArticles.find((article) => article.slug === slug)
}
