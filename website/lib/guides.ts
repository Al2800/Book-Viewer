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
    relatedQueries: [
      'book quote app',
      'save book highlights',
      'capture quotes from paper books',
      'book quote finder',
      'quote reader',
      'book quote search',
      'quote reader app for physical books',
    ],
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
    relatedQueries: ['scan book page to text', 'OCR underlined book page', 'book page scanner app', 'quote reader for physical books'],
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
    relatedQueries: [
      'book notes app iPhone',
      'book quote organiser iPhone',
      'app to save book highlights',
      'book quote search',
      'book quote finder',
      'how to search quotes from paper books',
      'export book quotes to obsidian',
    ],
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
  {
    slug: 'book-quote-finder-iphone',
    title: 'How to Use an iPhone as a Book Quote Finder for Paper Books',
    query: 'book quote finder',
    description:
      'Turn your iPhone into a reliable book quote finder: capture marked passages, link them to the right edition, and search your personal quote library.',
    category: 'Book quote search',
    readingTime: '6 min read',
    updated: '13 September 2026',
    intro:
      'Looking for a half-remembered sentence across five physical paperbacks on your shelf usually ends in frustration. A book quote finder on your iPhone solves this by turning physical underlines, margin marks, and dog-eared pages into an indexed, searchable personal library without manual typing.',
    relatedQueries: [
      'book quote finder',
      'book quote search',
      'quote finder app iPhone',
      'search quotes from paper books',
      'quote reader app for physical books',
    ],
    sections: [
      {
        heading: 'Why camera roll search fails for paper book quotes',
        paragraphs: [
          'Most readers start by snapping photos of marked pages. Within a month, those snapshots sit buried between grocery receipts, family photos, and screenshots. Even with iOS visual text lookup, a raw photo rarely preserves the book title, author, exact publication page, or the reason you stopped to mark the line.',
          'A proper book quote finder needs three parts working together: clear page capture, structured book identity, and instant text search across your saved passages. Without the book metadata attached at the moment of capture, you still end up thumbing through physical shelves trying to verify which edition held the thought.',
        ],
      },
      {
        heading: 'Step 1: Attach the book identity with ISBN scanning',
        paragraphs: [
          'Before or immediately after photographing a marked passage, identify the volume. Book cover photography is notoriously brittle because distinct printings share similar artwork or typography.',
          'BookQuotes uses barcode ISBN scanning to query catalogue metadata directly, bringing in verified title and author records. For older paperbacks or private editions lacking barcodes, manual entry provides an accurate fallback. Keeping book records clean prevents duplicate entries and ensures every passage anchors to the exact work on your shelf.',
        ],
      },
      {
        heading: 'Step 2: Capture the marked page with clean framing',
        paragraphs: [
          'Good text extraction starts with basic physics. Lay the book flat or gently hold down the margin away from the text block. Angle your iPhone parallel to the paper surface to avoid keystoning, and seek indirect daylight or soft room lighting that does not bounce off glossy paper stocks.',
          'Leave a small border around your pencil line or highlighter mark. Cropping too close to the words can cut off ascenders or drop punctuation marks that define the sentence.',
        ],
      },
      {
        heading: 'Step 3: Review and correct the extracted quote',
        paragraphs: [
          'No OCR engine or remote model should be trusted blindly with literary prose or philosophical argument. Footnote markers, curved margins, and dialogue dashes can easily confuse automated parsing.',
          'BookQuotes treats extraction as an editable draft. You compare the highlighted detection directly against your captured page photo, trim stray words, fix punctuation, and verify page numbers before saving. Once confirmed, the text enters your searchable local library.',
        ],
      },
      {
        heading: 'Step 4: Search your personal quote library instantly',
        paragraphs: [
          'Once saved, your passages become instantly searchable by keyword, author, title, tag, or collection. When you sit down to write an essay, prepare a talk, or recall an argument, searching for a single distinct word brings up the exact quote alongside its page number.',
          'Your collection lives locally on your device in the current release. You can search your library offline on a train or plane without needing an active data connection.',
        ],
      },
    ],
    faqs: [
      {
        question: 'How does an iPhone book quote finder work with paper books?',
        answer:
          'You photograph the marked page with your iPhone camera. The app extracts the underlined or highlighted text using on-device OCR or optional remote AI, lets you review and correct the transcription against the image, and stores the quote linked to its book title, author, and page number for keyword search.',
      },
      {
        question: 'Can I search quotes offline without an internet connection?',
        answer:
          'Yes. In BookQuotes, your library is stored locally on your iPhone or iPad. Once quotes are saved, full-text search across titles, authors, passages, and personal notes works completely offline.',
      },
      {
        question: 'Does BookQuotes search the full text of books I have not read?',
        answer:
          'No. BookQuotes is a personal quote finder for the books you own, read, and annotate. It indexes your own captured passages rather than offering a commercial database of entire books.',
      },
      {
        question: 'Can I export my searchable quotes to my computer?',
        answer:
          'Yes. You can export your saved library to Markdown, plain text, JSON, Obsidian, or Notion whenever you want a desktop copy.',
      },
    ],
  },
  {
    slug: 'quote-reader-app-for-physical-books',
    title: 'Quote Reader App for Physical Books: From Paper Margin to iPhone',
    query: 'quote reader app for physical books',
    description:
      'How a dedicated quote reader app transforms paper underlines and margin notes into an accurate, searchable digital library on iOS.',
    category: 'Quote reader',
    readingTime: '6 min read',
    updated: '13 September 2026',
    intro:
      'Underlining a physical book deepens attention, but finding those passages months later is notoriously tedious. A dedicated quote reader app bridges the physical-digital divide: it reads marked sentences off paper pages, extracts the text, and organises quotes alongside your own margin commentary.',
    relatedQueries: [
      'quote reader',
      'quote reader app for physical books',
      'book quote finder',
      'scan book page to text',
      'book annotation app iPhone',
    ],
    sections: [
      {
        heading: 'The difference between a generic scanner and a quote reader',
        paragraphs: [
          'Standard document scanner apps treat a book page like an office invoice: they generate flattened PDF scans or dump entire walls of unformatted OCR text into a file. A dedicated quote reader operates with a completely different objective.',
          'Instead of archiving whole pages, a quote reader isolates the specific sentence, paragraph, or margin note you marked. It recognises where your pencil line begins and ends, pairs the passage with book catalogue metadata, and records the page number so you can reference the physical volume at any time.',
        ],
      },
      {
        heading: 'How BookQuotes processes physical page markings',
        paragraphs: [
          'Readers mark paper in varied ways: neat ruler underlines, fluorescent highlighter pens, pencil brackets in margins, or short personal notes scribbled in blank space. BookQuotes is built to handle this physical variety.',
          'For eligible subscribers who consent to remote processing, an AI extraction route analyses the marked page image to discern intended boundaries. For readers who prefer strictly local processing, an on-device OCR path runs entirely on your iPhone hardware. In both cases, the app presents the detected passage for verification before committing it to storage.',
        ],
      },
      {
        heading: 'Preserving margin thoughts alongside author words',
        paragraphs: [
          'A quote rarely tells the whole story on its own. Often the most valuable insight is the reaction you had while reading: a counterargument, a connection to another volume, or a question to explore.',
          'BookQuotes provides dedicated fields for your personal notes alongside the extracted author text. Keeping your commentary distinct from the quoted passage prevents accidental misattribution later when drafting articles, academic papers, or book reviews.',
        ],
      },
      {
        heading: 'Building a reading companion that respects your attention',
        paragraphs: [
          'The ideal quote reader app stays out of your way while you are in the flow of reading. Trying to digitise quotes line by line while reading breaks deep concentration.',
          'We recommend marking freely with pen or pencil while reading. When you finish a chapter or close the book for the evening, spend two minutes photographing the marked pages in batch. Review the text, confirm the passages, and return to your evening.',
        ],
      },
      {
        heading: 'Local storage and reader privacy',
        paragraphs: [
          'Reading choices reflect our deepest curiosities, private doubts, and personal interests. A quote reader should not broadcast your reading list to ad networks or require public sharing.',
          'BookQuotes stores your book library, quotes, collections, and custom tags locally on your device. There is no public social feed and no mandatory cloud synchronisation in the current version. You maintain full ownership of your reading data and can export it whenever you wish.',
        ],
      },
    ],
    faqs: [
      {
        question: 'What types of physical markings can BookQuotes read?',
        answer:
          'BookQuotes detects underlines, highlighter marks, vertical margin lines, and brackets on printed book pages. You can also transcribe or refine margin notes during the review step.',
      },
      {
        question: 'Do I have to scan pages while I am reading?',
        answer:
          'No. Most readers find it best to mark paper pages freely while reading, then scan the batch of marked pages once the reading session is finished.',
      },
      {
        question: 'Does the quote reader work with library books and secondhand copies?',
        answer:
          'Yes. If you use removable sticky tabs or light pencil marks in library books, you can photograph the page, verify the quote, and erase your pencil mark before returning the book.',
      },
      {
        question: 'Can I use BookQuotes on iPad as well as iPhone?',
        answer:
          'Yes. BookQuotes is designed for both iPhone and iPad, allowing you to capture pages with your phone camera or review your library on a larger iPad display.',
      },
    ],
  },
  {
    slug: 'how-to-search-quotes-from-paper-books',
    title: 'How to Search Quotes from Paper Books: A Step-by-Step System',
    query: 'how to search quotes from paper books',
    description:
      'Learn how to index your physical book highlights and margin notes so you can search them by keyword, author, or theme in seconds.',
    category: 'Search workflow',
    readingTime: '6 min read',
    updated: '13 September 2026',
    intro:
      'Physical books offer an irreplaceable reading experience, but their greatest weakness is search. When you need that striking metaphor on memory or that crisp definition of incentives, paper indexes and memory rarely suffice. Here is a practical system to make your paper library fully searchable on your phone.',
    relatedQueries: [
      'book quote search',
      'search quotes from paper books',
      'book quote finder',
      'quote reader',
      'digitise reading notes',
    ],
    sections: [
      {
        heading: 'The search problem of the physical library',
        paragraphs: [
          'Every avid reader knows the experience of staring at book spines, positive that an author explained an idea on a left-hand page roughly halfway through a 400-page volume. Half an hour later, you are still leafing through chapters with nothing to show for it.',
          'Traditional solutions fall short: sticky index tabs fall off or lack context; transcription into a spreadsheet takes too much time; and full-book search engines online only work if you remember the exact wording verbatim.',
        ],
      },
      {
        heading: 'Phase 1: Mark with searchability in mind',
        paragraphs: [
          'Making physical books searchable begins with how you mark the page. When you underline a sentence, glance at the paragraph to ensure the core idea is self-contained. If an author uses an ambiguous pronoun like “this tendency”, mark the preceding noun phrase or write the referent in the margin.',
          'A quote that makes sense on its own will be far easier to locate in search months later when the broader narrative has faded from your working memory.',
        ],
      },
      {
        heading: 'Phase 2: Digital capture without transcription friction',
        paragraphs: [
          'Manually typing book passages on a keyboard creates too much resistance. Most readers abandon typing routines within three weeks.',
          'Use BookQuotes to photograph the marked passage instead. The app isolates the underlined text, transcribes it through on-device OCR or optional remote AI, and pairs it with the book title, author, and page number in seconds. A swift verification on screen ensures typographical fidelity.',
        ],
      },
      {
        heading: 'Phase 3: Structuring metadata for effortless retrieval',
        paragraphs: [
          'Full-text search handles distinct vocabulary well, but conceptual searches benefit from light curation. When saving a passage, consider adding one or two topical tags such as “stoicism”, “habit-formation”, or “character-study”.',
          'Avoid over-tagging. Creating dozens of intricate categories produces maintenance fatigue. Let keyword search do the heavy lifting for specific words, and use collections only for major reading projects or active writing endeavours.',
        ],
      },
      {
        heading: 'Phase 4: Putting your searchable library to work',
        paragraphs: [
          'A searchable paper quote library becomes an indispensable asset for writers, researchers, students, and curious readers. When drafting an article or preparing notes for a meeting, open your search bar and enter any term.',
          'BookQuotes brings up matching quotes across your entire library in milliseconds, showing the verbatim text, book cover, author, and page number. If you need to cite the passage or read the full chapter, you know exactly which physical volume and page to pull from your shelf.',
        ],
      },
    ],
    faqs: [
      {
        question: 'Can I search my paper book quotes by concept rather than exact words?',
        answer:
          'Yes. By adding personal notes and short tags when saving a quote in BookQuotes, you can search for concepts and themes even if the author used different terminology in the text.',
      },
      {
        question: 'How fast is full-text search in BookQuotes?',
        answer:
          'Search runs locally on your iPhone or iPad, returning matching passages, titles, authors, and notes instantly as you type.',
      },
      {
        question: 'What if I remember a quote but not the book it came from?',
        answer:
          'BookQuotes searches across your entire personal library simultaneously. Entering a single memorable word or phrase surfaces all matching passages across all your recorded books.',
      },
      {
        question: 'Do I need to carry my physical books with me to search my notes?',
        answer:
          'No. Once captured, your quotes, page citations, and notes stay with you on your iPhone or iPad wherever you go, fully accessible without your paper library or an internet connection.',
      },
    ],
  },
  {
    slug: 'book-quotes-vs-kindle-highlights',
    title: 'Book Quotes vs Kindle Highlights: Bridging Paper and Digital Reading',
    query: 'book quotes vs kindle highlights',
    description:
      'Compare Kindle highlights with paper book quote capture. Discover how to give physical books the search advantages of digital reading without giving up print.',
    category: 'Reading comparison',
    readingTime: '6 min read',
    updated: '13 September 2026',
    intro:
      'Readers often feel forced to choose between the tactile pleasure of physical books and the convenience of Kindle highlights. E-readers make searching highlights effortless, yet paper offers superior spatial memory, comprehension, and freedom from screen fatigue. You do not have to compromise: you can read on paper and maintain a searchable digital quote library.',
    relatedQueries: [
      'kindle highlights physical books',
      'book quote finder',
      'quote reader app for physical books',
      'save book highlights',
      'export kindle highlights alternative',
    ],
    sections: [
      {
        heading: 'The great reading trade-off: tactile joy vs digital retrieval',
        paragraphs: [
          'Kindle highlights changed how people capture reading notes. Dragging a thumb across an e-ink screen saves a passage instantly, syncing it to an online dashboard. For researchers and non-fiction readers, this immediate retrieval is hard to give up.',
          'Yet many readers find digital reading flat. Studies and reader experience consistently show that physical books foster stronger spatial recall: you remember where an argument unfolded on the page and how thick the remaining pages felt in your hand. Paper also protects your reading hours from notification pings and digital eye strain.',
        ],
      },
      {
        heading: 'Where Kindle highlights fall short',
        paragraphs: [
          'Despite their convenience, Kindle highlights suffer from several quiet drawbacks. First is the export clipping limit: publisher DRM frequently truncates or blocks your highlights when exporting notes from heavily annotated books.',
          'Second is context decay. Kindle clipping files often strip away the reason you made the highlight in the first place. You end up with hundreds of disjointed snippets in a web dashboard that you rarely open.',
          'Finally, your highlights remain tethered to Amazon’s ecosystem. If an ebook license changes or you want your notes in an open markdown format, navigating proprietary cloud sync can prove frustrating.',
        ],
        bullets: [
          'Publisher clipping limits restrict how many highlights you can export.',
          'Ecosystem lock-in ties your annotations to proprietary accounts.',
          'Passive highlighting often produces note bloat without retention.',
        ],
      },
      {
        heading: 'Bringing Kindle-style search to your paper library',
        paragraphs: [
          'BookQuotes bridges this gap by giving physical paperbacks and hardcovers the primary advantage of e-readers: instant, keyword-searchable highlights.',
          'You read your paper book naturally, pencil in hand. When you finish a reading session, snap photos of your marked passages with your iPhone. BookQuotes extracts the text, lets you verify the wording, attaches the ISBN metadata, and files the quote into your personal library.',
        ],
      },
      {
        heading: 'Intentional capture creates better memory retention',
        paragraphs: [
          'Friction in note-taking is not always a flaw; sometimes it is a filter. The effortless ease of Kindle highlighting often encourages passive swiping: readers highlight whole pages without pausing to assimilate the ideas.',
          'Photographing a paper page and reviewing the extracted text takes roughly ten seconds, but that brief pause serves as an active retrieval checkpoint. You re-read the sentence, confirm why it earned your mark, and reinforce your memory of the author’s point.',
        ],
      },
      {
        heading: 'Unified export to open personal knowledge systems',
        paragraphs: [
          'Unlike closed e-reader ecosystems, BookQuotes is designed to feed your broader note-taking workflow. Your paper quotes can be exported directly to Markdown, plain text, JSON, Notion, or Obsidian.',
          'This means your physical reading notes can sit right alongside your Kindle imports, podcast notes, and web bookmarks in your preferred knowledge management vault.',
        ],
      },
    ],
    faqs: [
      {
        question: 'Can I import my existing Kindle highlights into BookQuotes?',
        answer:
          'BookQuotes is currently tailored for capturing, scanning, and organising quotes from physical books using camera capture and ISBN metadata. You can export your BookQuotes library to Markdown or Obsidian to merge with Kindle clippings in your vault.',
      },
      {
        question: 'Does BookQuotes impose export limits on my saved quotes?',
        answer:
          'No. Unlike e-reader DRM clipping limits, all quotes you capture in BookQuotes belong entirely to you. You can export your full library at any time without restriction.',
      },
      {
        question: 'Is text extraction from paper as accurate as digital highlights?',
        answer:
          'Digital highlights are direct text copies, whereas paper capture relies on optical extraction. However, because BookQuotes includes an immediate review screen where you verify the text against the photograph, your final saved quote is just as accurate.',
      },
      {
        question: 'Do I need special pens or highlighters for BookQuotes to recognise my marks?',
        answer:
          'No. BookQuotes recognises standard graphite pencil lines, ballpoint pen underlines, coloured highlighters, and margin brackets on standard book paper.',
      },
    ],
  },
  {
    slug: 'export-book-quotes-to-obsidian',
    title: 'How to Export Physical Book Quotes to Obsidian and Notion',
    query: 'export book quotes to obsidian',
    description:
      'A practical guide to exporting paper book quotes, page citations, and margin notes into Obsidian markdown vaults and Notion databases.',
    category: 'Export workflows',
    readingTime: '6 min read',
    updated: '13 September 2026',
    intro:
      'A personal quote library on your iPhone is invaluable for quick reference, but serious writing and synthesis happen in dedicated workspace tools like Obsidian and Notion. Here is how to move marked passages from your physical books into your desktop knowledge vault without manual retyping.',
    relatedQueries: [
      'export book quotes to obsidian',
      'book quotes to notion',
      'markdown book highlights',
      'digital commonplace book',
      'book quote finder',
    ],
    sections: [
      {
        heading: 'Why personal knowledge vaults need paper book quotes',
        paragraphs: [
          'Tools like Obsidian and Notion excel at linking thoughts across different domains. Many knowledge workers maintain rich databases of web articles, newsletters, and PDF highlights, yet their physical reading remains stranded on paper shelves.',
          'When physical book highlights remain trapped in paper bindings, your knowledge graph loses some of its richest source material. Integrating paper quotes into your daily vault turns isolated marginalia into interconnected notes that enrich your writing.',
        ],
      },
      {
        heading: 'Exporting from BookQuotes: clean Markdown and open formats',
        paragraphs: [
          'BookQuotes avoids proprietary silos. When you export your library, you can generate clean Markdown files structured for immediate compatibility with Obsidian, Logseq, and other plain-text systems, as well as JSON and Notion formats.',
          'Each exported quote preserves essential academic context: the verbatim passage, book title, author, publication page, date captured, tags, and your personal margin notes. This ensures your citations remain robust without requiring secondary formatting passes.',
        ],
      },
      {
        heading: 'Setting up an Obsidian literature note workflow',
        paragraphs: [
          'In Obsidian, best practice separates literature notes (what the author said) from permanent notes (what you think). When importing BookQuotes Markdown into your vault:',
          'Create a dedicated folder such as “Literature Notes” or “Reading”. Use the book title as the note title, and let individual quotes appear as blockquotes accompanied by page numbers and your tags. You can then use Obsidian’s internal linking syntax ([[Note Name]]) to link book quotes directly into your active project notes.',
        ],
        bullets: [
          'Store quotes in clean blockquotes with explicit page citations.',
          'Use tags to connect themes across different authors and genres.',
          'Link key concepts directly to your ongoing project canvases or atomic notes.',
        ],
      },
      {
        heading: 'Importing quotes into Notion databases',
        paragraphs: [
          'If you use Notion as your central dashboard, a database layout provides flexible filtering and gallery views. Export your BookQuotes collection in structured Markdown or CSV/JSON format.',
          'In Notion, set up properties for Title, Author, Page Number, and Category Tags. You can build filtered views for specific projects, group quotes by author, or create a randomised “Quote of the Day” widget on your personal homepage.',
        ],
      },
      {
        heading: 'Closing the loop: from physical page to finished writing',
        paragraphs: [
          'The goal of any note system is not passive hoarding; it is creative output. By establishing a frictionless pipeline—reading on paper, capturing with BookQuotes, and exporting to Obsidian or Notion—you build an effortless intellectual archive.',
          'When you sit down to write an article, report, or book, your favourite passages and citations are already waiting in your workspace, fully searchable and ready to inform your thinking.',
        ],
      },
    ],
    faqs: [
      {
        question: 'Does BookQuotes require an Obsidian plugin to export notes?',
        answer:
          'No. BookQuotes exports standard, portable Markdown files that you can drop directly into any Obsidian vault folder without requiring custom third-party community plugins.',
      },
      {
        question: 'Are page numbers and book metadata preserved during export?',
        answer:
          'Yes. Every exported quote includes the book title, author, exact page number, capture date, your personal notes, and any assigned tags.',
      },
      {
        question: 'Can I export a single book or do I have to export the entire library?',
        answer:
          'You can export individual books, curated collections, or your complete library depending on your immediate workflow need.',
      },
      {
        question: 'Does BookQuotes sync automatically to Notion via API?',
        answer:
          'BookQuotes focuses on local privacy and exports structured formats (Markdown, plain text, JSON) that you can import directly into Notion or your desktop tools. Cloud sync is not enabled in the current release.',
      },
    ],
  },
]

export function getGuide(slug: string) {
  return guides.find((guide) => guide.slug === slug)
}
