export type GuideSection = {
  heading: string
  paragraphs: string[]
  bullets?: string[]
}

export type GuideFaq = {
  question: string
  answer: string
}

export type Guide = {
  slug: string
  title: string
  query: string
  description: string
  category: string
  readingTime: string
  updated: string
  intro: string
  relatedQueries: string[]
  sections: GuideSection[]
  faqs: GuideFaq[]
}

export const guides: Guide[] = [
  {
    slug: 'how-to-save-quotes-from-physical-books',
    title: 'How to Save Quotes from Physical Books',
    query: 'how to save quotes from physical books',
    description:
      'A practical workflow for moving a marked passage from a paper book into a corrected, searchable personal library.',
    category: 'Book quote capture',
    readingTime: '6 min read',
    updated: '3 August 2026',
    intro:
      'The easiest way to lose a good passage is to assume you will remember where it was. A photo in the camera roll helps, but it still leaves the wording, book, page, and reason for keeping the line scattered. A dependable capture ritual keeps those pieces together without asking you to stop reading and type everything out.',
    relatedQueries: ['book quote app', 'save book highlights', 'capture quotes from paper books'],
    sections: [
      {
        heading: '1. Mark the passage while you read',
        paragraphs: [
          'Underline, highlight, or add the margin mark that has meaning for you. Do not try to build the digital record at the same time. The first job is to stay with the book and notice why the passage matters.',
          'When you return to the page, include enough of the surrounding text for your future self to understand the thought. A short passage with its book and page context is more useful than a fragment that looks impressive on its own.',
        ],
      },
      {
        heading: '2. Photograph the marked page',
        paragraphs: [
          'Use even light, keep the phone parallel to the page, and leave a little space around the marked area. Glare, curved pages, tight crops, and faint pencil marks make extraction harder. A clear photograph is still the most important part of the workflow.',
          'BookQuotes is designed for this physical-book moment. Capture the page, keep the image with the reading session, and continue once the page is safely recorded.',
        ],
      },
      {
        heading: '3. Review the extracted text',
        paragraphs: [
          'Text extraction is a first pass, not a substitute for checking the page. Compare the result with the photograph, correct punctuation or line breaks, and remove text that was not actually marked. This is especially important for margin lines, unusual layouts, and pages with more than one marked passage.',
          'BookQuotes lets you edit the detected passage before it is saved. If the image is too difficult to read, retake it or use the available on-device route rather than treating a poor result as final.',
        ],
      },
      {
        heading: '4. Keep the book context attached',
        paragraphs: [
          'Add the book before or after capture. ISBN scanning is the most reliable way to bring in the title and cover metadata; manual entry is useful when a catalogue lookup is unavailable. Keep the page number and a short personal note when they will help you return to the idea.',
          'The goal is not to publish a database of quotations. It is to build a private reference to the passages you chose from your own reading.',
        ],
      },
      {
        heading: '5. Make the collection useful later',
        paragraphs: [
          'Search the saved text when you are writing, planning, teaching, or preparing for a book-club conversation. Add a small number of tags only when they improve retrieval. A collection becomes useful through return visits, not through perfect filing.',
          'BookQuotes keeps the library searchable on the device in the current release and provides export options when you want a copy in another tool.',
        ],
      },
    ],
    faqs: [
      {
        question: 'Can I save quotes from a paper book without typing them?',
        answer: 'Yes. Photograph the marked page, review the extracted text, and correct it before saving. Manual editing is still available when the page or marking is difficult to read.',
      },
      {
        question: 'Should I photograph the whole page or only the quote?',
        answer: 'Start with the marked area plus a little surrounding context. A straight, well-lit page makes it easier to review the result and identify the correct passage.',
      },
      {
        question: 'Does BookQuotes provide a public quote database?',
        answer: 'No. BookQuotes is for building your own personal library of passages from your reading. It is not a catalogue of full book quotations.',
      },
    ],
  },
  {
    slug: 'scan-underlined-book-pages',
    title: 'How to Scan Underlined Book Pages',
    query: 'scan underlined book pages',
    description:
      'How to frame, capture, review, and correct an underlined page when you want searchable reading notes.',
    category: 'Page scanning',
    readingTime: '5 min read',
    updated: '3 August 2026',
    intro:
      'Scanning an underlined book page is less about taking a fast photograph and more about producing an image that can be checked. Good framing gives the text extractor a fair chance, while the review step protects the wording you actually meant to keep.',
    relatedQueries: ['scan book page to text', 'OCR underlined book page', 'book page scanner app'],
    sections: [
      {
        heading: 'Prepare the page before you open the camera',
        paragraphs: [
          'Flatten the page as much as you can without forcing the binding. Move away from direct glare, turn on enough light to make the print clear, and remove objects that cast shadows across the text. If you have marked several separate areas, decide whether they belong together before capturing.',
          'The app can help with a page image, but it cannot recover text hidden by a fold, reflection, finger, or heavy shadow.',
        ],
      },
      {
        heading: 'Frame the page squarely',
        paragraphs: [
          'Hold the phone parallel to the page and keep all relevant lines inside the frame. Avoid an aggressive crop until you know which marked passages you want to review. Slightly wider context makes it easier to check where a passage starts and ends.',
          'If the page is curved near the spine, move the phone rather than stretching the image in editing. A second clear capture is usually faster than correcting a distorted one.',
        ],
      },
      {
        heading: 'Choose the extraction route deliberately',
        paragraphs: [
          'BookQuotes supports an on-device OCR path for local processing and a separate remote AI route for eligible signed-in subscribers who choose it. The app should make the current route visible while a page is being processed.',
          'Remote processing is not a guarantee of perfect selection. It can be useful for marked-page analysis, but the image and result still need a reader review. When a network request fails, use the recovery choice or continue with the on-device route when appropriate.',
        ],
      },
      {
        heading: 'Check selection boundaries, not just spelling',
        paragraphs: [
          'An extraction can contain correctly recognised words and still be the wrong quote. Check that it includes the full marked thought, excludes nearby unmarked text, and does not turn a margin line into a long selection. Then correct punctuation, hyphenation, and line breaks.',
          'This review is part of the feature, not a failure of the workflow. The saved passage should represent what you selected on the physical page.',
        ],
      },
    ],
    faqs: [
      {
        question: 'What makes a book page scan easier to extract?',
        answer: 'Even light, a straight camera angle, visible print, and enough surrounding context. Glare, curved pages, and faint marks are the most common causes of a difficult result.',
      },
      {
        question: 'Can I scan several marked passages on one page?',
        answer: 'Yes, but review each detected passage carefully. Separate marks may be returned as separate items, and a margin line may not indicate the exact boundary you intended.',
      },
      {
        question: 'Is on-device OCR the same as remote AI extraction?',
        answer: 'No. They are separate processing routes. On-device OCR keeps processing local, while remote AI requires the relevant app flow, sign-in and network availability. Both routes still require review.',
      },
    ],
  },
  {
    slug: 'how-to-digitise-book-notes',
    title: 'How to Digitise Book Notes Without Losing Context',
    query: 'how to digitise book notes',
    description:
      'A simple system for preserving the passage, book, page and personal note when moving from paper to a searchable library.',
    category: 'Reading workflow',
    readingTime: '6 min read',
    updated: '3 August 2026',
    intro:
      'Digitising book notes is not just a transcription task. A line without its book, page, and reason for keeping it quickly becomes another orphaned note. The better system preserves enough context for you to recognise the idea when you meet it again.',
    relatedQueries: ['digitise reading notes', 'turn paper notes into digital notes', 'book annotation app'],
    sections: [
      {
        heading: 'Decide what belongs in the record',
        paragraphs: [
          'A useful book-note record usually has four parts: the exact passage, the title and author, the page or location, and your own short note. You do not need a long summary for every line. The personal note is there to preserve your connection to the passage, not to rewrite the book.',
          'Keep the wording separate from your interpretation. This makes it easier to search the author text and to tell, later, what came from the book and what came from you.',
        ],
      },
      {
        heading: 'Use ISBN lookup for the book identity',
        paragraphs: [
          'A book cover is not a reliable title-recognition system. Editions vary, covers can be hard to read, and a photograph may contain too little information. BookQuotes uses ISBN scanning and catalogue lookup to help attach the correct book metadata, with manual entry available when lookup is not enough.',
          'This keeps book identification separate from page extraction. The page is captured for the passage; the ISBN is used for the book record.',
        ],
      },
      {
        heading: 'Capture, then correct',
        paragraphs: [
          'Photograph the marked page, wait for the available extraction route to finish, and read the result against the photograph. Correct the text before adding tags or moving on. A small correction now prevents a frustrating search later.',
          'If the page contains several markings, check each boundary. A selection that includes an adjacent paragraph may look plausible while still being the wrong note.',
        ],
      },
      {
        heading: 'Create a review habit instead of a filing project',
        paragraphs: [
          'Use a few tags that describe how you will look for the idea later: a project, theme, question, or person. Avoid building a taxonomy so elaborate that it stops you from saving the passage.',
          'Once a week, search the library for one theme and revisit a handful of passages. This is where digitising notes becomes useful: retrieval connects the old page to something you are thinking about now.',
        ],
      },
    ],
    faqs: [
      {
        question: 'What should I include with a digitised book note?',
        answer: 'Keep the exact passage, book identity, page or location, and a short note about why it mattered. Add tags only when they improve future retrieval.',
      },
      {
        question: 'Can a photo of the book cover identify the book?',
        answer: 'It can be a useful visual reference, but it is not the primary identification route. ISBN scanning or manual entry is more dependable for attaching the correct title and edition metadata.',
      },
      {
        question: 'Where are digitised notes stored in BookQuotes?',
        answer: 'The current release stores books, quotes, tags, collections and related library data locally on the device. Export the library when you want a separate copy.',
      },
    ],
  },
  {
    slug: 'digital-commonplace-book',
    title: 'What Is a Digital Commonplace Book?',
    query: 'digital commonplace book',
    description:
      'A plain-English introduction to commonplace books and a low-friction way to begin with passages from your paper reading.',
    category: 'Reading practice',
    readingTime: '6 min read',
    updated: '3 August 2026',
    intro:
      'A commonplace book is a personal collection of passages, observations, questions, and ideas worth returning to. A digital version does not need to imitate a social feed or become a productivity dashboard. Its job is to make your chosen ideas easier to keep, connect, and revisit.',
    relatedQueries: ['commonplace book app', 'digital reading journal', 'personal quote library'],
    sections: [
      {
        heading: 'A commonplace book is selective',
        paragraphs: [
          'The practice works because it involves judgment. You do not need to save every interesting sentence. Keep the lines that clarify a question, change how you see something, or give you language you expect to use again.',
          'That selectiveness also protects the collection from becoming a second inbox. A smaller library that you revisit is more valuable than an archive you never open.',
        ],
      },
      {
        heading: 'Paper and digital can work together',
        paragraphs: [
          'The physical book remains the place where you read, mark, and make the first connection. The digital library handles retrieval. This division means you can keep the feel of paper while still searching the ideas when you are away from the shelf.',
          'BookQuotes is built around that handoff: capture a marked page, review the text, connect it to the book, and return to the passage through search or a collection.',
        ],
      },
      {
        heading: 'Start with one weekly question',
        paragraphs: [
          'Choose a question you are already carrying, such as “What am I learning about attention?” or “Which passages change how I approach this project?” Save only the passages that help answer it.',
          'At the end of the week, search the collection and write one short connection in your own words. The act of connecting is what turns a stored passage into a useful commonplace.',
        ],
      },
      {
        heading: 'Keep the tool subordinate to the practice',
        paragraphs: [
          'A digital commonplace book should reduce friction, not create a new admin routine. Use a few tags, preserve context, and review the result before trusting the transcription. The reader remains responsible for deciding what the passage means and why it belongs.',
        ],
      },
    ],
    faqs: [
      {
        question: 'Is a digital commonplace book the same as a notes app?',
        answer: 'It can be made with a notes app, but the practice is more specific: collecting selected ideas with enough context to revisit and connect them later. A dedicated quote library can reduce the work of organising passages from physical books.',
      },
      {
        question: 'How many passages should I save?',
        answer: 'There is no correct number. Start with the passages you expect to use or revisit, then review the collection regularly so it stays selective.',
      },
      {
        question: 'Does BookQuotes tell me what a passage means?',
        answer: 'No. The app helps capture, extract, organise and retrieve your passages. Your reading and judgment remain the important part of the commonplace-book practice.',
      },
    ],
  },
  {
    slug: 'organise-book-quotes-on-iphone',
    title: 'The Best Way to Organise Book Quotes on iPhone',
    query: 'organise book quotes on iPhone',
    description:
      'A practical comparison of camera rolls, general notes, and a dedicated personal quote library for readers who want to find passages again.',
    category: 'iPhone reading tools',
    readingTime: '6 min read',
    updated: '3 August 2026',
    intro:
      'The best book-quote system is the one you will use while reading and trust when you return later. For some readers, Apple Notes is enough. For others, a dedicated library removes the repeated work of naming books, transcribing passages, and searching through screenshots.',
    relatedQueries: ['book notes app iPhone', 'book quote organiser iPhone', 'app to save book highlights'],
    sections: [
      {
        heading: 'Start by identifying the retrieval problem',
        paragraphs: [
          'If you only save a few quotes each month, a single note may be perfectly adequate. If you have photographs in your camera roll, handwritten scraps in books, and passages spread across several notes, the real problem is retrieval rather than storage.',
          'Ask what you will want to search later: the wording, the book, a page, a theme, or your own note. Your answer should shape the structure of the library.',
        ],
      },
      {
        heading: 'Compare the common approaches',
        paragraphs: [
          'A camera roll is fast but weak at context and search. A general notes app is flexible, but often leaves you to create book records and transcribe the page yourself. A dedicated quote library can put capture, book identity, correction, tags, and search in one flow.',
          'None of these choices removes the need to review the wording. The difference is how much repeated setup you want to do around each passage.',
        ],
        bullets: [
          'Camera roll: quickest capture, weakest retrieval.',
          'General notes: flexible, but book context is usually manual.',
          'Dedicated quote library: structured around passages, books, review, and search.',
        ],
      },
      {
        heading: 'Use ISBN scanning for the book record',
        paragraphs: [
          'When a title matters, identify the book separately from the page photograph. BookQuotes uses ISBN scanning and catalogue lookup to help create the book record, which is more dependable than trying to infer the title from a cover image.',
          'Once the book is in the library, add the marked passage, check the extracted text, and keep the page details that will help you find the physical source again.',
        ],
      },
      {
        heading: 'Choose a small organisation system',
        paragraphs: [
          'Use collections for a broad reading project and tags for a recurring theme or question. Do not tag every possible category. If you can search the passage text and book title, a small amount of organisation is usually enough.',
          'Export when you need to work in another tool. Keeping an independent copy is especially sensible for a local-first library.',
        ],
      },
    ],
    faqs: [
      {
        question: 'Is a book quote app better than Apple Notes?',
        answer: 'It depends on your reading volume and retrieval needs. Apple Notes may be enough for occasional captures; a dedicated library is useful when you want book-linked passages, structured review, and search across your reading history.',
      },
      {
        question: 'Can I organise quotes by book and theme?',
        answer: 'Yes. BookQuotes links passages to books and supports tags and collections for organising a personal library.',
      },
      {
        question: 'Can I export my book quotes?',
        answer: 'The current app includes export options for formats including Markdown, plain text, JSON, Notion and Obsidian.',
      },
    ],
  },
  {
    slug: 'private-book-notes-app-iphone',
    title: 'Privacy-First Book Notes on iPhone',
    query: 'private book notes app iPhone',
    description:
      'What to check when you want searchable reading notes without casually exposing your personal reading history.',
    category: 'Privacy and trust',
    readingTime: '5 min read',
    updated: '3 August 2026',
    intro:
      'Your reading history can reveal your interests, questions, beliefs, and unfinished thinking. A book-notes app should explain what stays on the phone, what requires a network, and how you can delete or export your library before you depend on it.',
    relatedQueries: ['private reading notes app', 'offline book notes app', 'local book quote library'],
    sections: [
      {
        heading: 'Ask where the library lives',
        paragraphs: [
          'The most important distinction is between the personal library and a processing request. In the current BookQuotes release, books, quotes, tags, collections, and related library data are stored locally on the device. Cloud sync is not enabled.',
          'That means the device is also part of your backup plan. Export the library when you want a separate copy, and remember that deleting the app removes local data unless you have exported it elsewhere.',
        ],
      },
      {
        heading: 'Understand the processing boundary',
        paragraphs: [
          'BookQuotes can use on-device OCR for local processing. A separate remote AI route is available in the relevant signed-in subscriber flow and requires network processing of the marked-page image and extraction request. The app should not describe those routes as interchangeable.',
          'Remote processing is optional in the product flow. Read the current privacy policy before enabling it, especially if the page contains material you do not want to send to a third-party provider.',
        ],
      },
      {
        heading: 'Check deletion and export before building a library',
        paragraphs: [
          'A trustworthy note-taking tool should give you a clear way to remove account data and should not make export an afterthought. BookQuotes provides in-app account deletion for server-side account and usage records, while the local library remains on the device unless you delete it yourself.',
          'Subscriptions are managed through Apple. Deleting an account does not cancel an App Store subscription, so manage billing separately in Apple subscription settings.',
        ],
      },
      {
        heading: 'Privacy is a product feature, not a slogan',
        paragraphs: [
          '“Private” should answer a concrete question. Look for a current privacy policy, a clear remote-processing explanation, a deletion route, and export. Avoid absolute claims such as “nothing ever leaves your phone” when a feature can use remote processing.',
        ],
      },
    ],
    faqs: [
      {
        question: 'Does BookQuotes store my personal book library in the cloud?',
        answer: 'Not in the current release. The local library is stored on the device and cloud sync is not enabled. Account and subscription records are separate service data described in the privacy policy.',
      },
      {
        question: 'Can remote AI process a book page?',
        answer: 'Yes, when the eligible signed-in subscriber flow is enabled and the user chooses remote processing. That route requires sending the relevant request for processing, so it should be treated separately from on-device OCR.',
      },
      {
        question: 'Does deleting my account delete my local books and quotes?',
        answer: 'No. Account deletion removes the relevant server-side account and usage records. Your local library remains on the device unless you delete it yourself.',
      },
    ],
  },
]

export function getGuide(slug: string) {
  return guides.find((guide) => guide.slug === slug)
}
