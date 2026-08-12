export type JournalSection = {
  heading: string
  paragraphs: string[]
}

export type JournalArticle = {
  slug: string
  title: string
  summary: string
  category: string
  readingTime: string
  published: string
  publishedISO: string
  sections: JournalSection[]
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
    title: 'What to Do with Book Highlights After You Finish Reading',
    summary:
      'Turn a finished book into a small set of ideas you can actually remember and use.',
    category: 'Annotation',
    readingTime: '4 min read',
    published: '24 July 2026',
    publishedISO: '2026-07-24',
    sections: [
      {
        heading: 'Wait a day before reviewing',
        paragraphs: [
          'The moment you finish a book, everything still feels equally close. Give it a little space. When you return the next day, the passages that still feel alive are usually the ones worth carrying forward.',
          'Leaf through your marks and choose a small number. A useful limit is five to ten passages for an ordinary nonfiction book, or the lines that best preserve the voice and feeling of a novel.',
        ],
      },
      {
        heading: 'Add context, not clutter',
        paragraphs: [
          'Keep the exact wording, title, author, and page number. Add a short note only when it explains why the passage matters to you. A sentence such as “use this when planning difficult work” is more useful than a broad tag such as “productivity”.',
          'Avoid turning every quote into a miniature essay. The goal is to preserve enough context for your future self to understand why the line survived the review.',
        ],
      },
      {
        heading: 'Make retrieval part of reading',
        paragraphs: [
          'Searchable highlights are most useful when they reappear in real situations. Look through them before writing, planning, teaching, or joining a book-club discussion.',
          'A physical book can stay on the shelf while its strongest lines remain within reach. That is the gap BookQuotes is designed to close.',
        ],
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
