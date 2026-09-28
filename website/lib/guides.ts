export type GuideSection = {
  heading: string
  paragraphs: string[]
  bullets?: string[]
}

export type GuideFaq = {
  question: string
  answer: string
}

export type RelatedLink = {
  href: string
  label: string
}

export type Guide = {
  slug: string
  title: string
  query: string
  description: string
  category: string
  readingTime: string
  updated: string
  publishedISO: string
  updatedISO: string
  intro: string
  relatedQueries: string[]
  related: RelatedLink[]
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
    updated: '28 September 2026',
    publishedISO: '2026-08-03',
    updatedISO: '2026-09-28',
    related: [
      { href: '/guides/scan-underlined-book-pages', label: 'How to scan underlined book pages' },
      { href: '/guides/how-to-digitise-book-notes', label: 'Digitise book notes without losing context' },
      { href: '/guides/digital-commonplace-book', label: 'What is a digital commonplace book?' },
    ],
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
          'Use even light, keep the phone parallel to the page, and leave a little space around the marked area. Glare, curved pages, tight crops, and faint pencil marks make extraction harder. A clear photograph is still the most important part of the workflow. The [scan guide](/guides/scan-underlined-book-pages) covers framing in more detail.',
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
          'BookQuotes keeps the library searchable on the device in the current release and provides export options when you want a copy in another tool. If the notes are heading for a desktop vault, see [how to export book quotes to Obsidian and Notion](/guides/export-book-quotes-to-obsidian).',
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
        answer: 'The app saves passages from your own reading. It is not a database of other people’s books. This website also has a quotes section, at /quotes, with lines checked against public-domain texts and the work named. Those pages are separate from the library on your phone.',
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
    updated: '28 September 2026',
    publishedISO: '2026-08-03',
    updatedISO: '2026-09-28',
    related: [
      { href: '/guides/book-annotation-key', label: 'How to make a book annotation key' },
      { href: '/guides/how-to-save-quotes-from-physical-books', label: 'How to save quotes from physical books' },
      { href: '/guides/how-to-digitise-book-notes', label: 'Digitise book notes without losing context' },
      { href: '/journal/ai-extraction-and-reader-control', label: 'How AI extraction and reader review work' },
    ],
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
          'Remote processing is not a guarantee of perfect selection. It can be useful for marked-page analysis, but the image and result still need a reader review. When a network request fails, use the recovery choice or continue with the on-device route when appropriate. The [note on AI extraction](/journal/ai-extraction-and-reader-control) explains what leaves the device.',
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
    slug: 'book-annotation-key',
    title: 'How to Make a Book Annotation Key',
    query: 'annotating books key',
    description:
      'A short legend of symbols, colours and tab colours for fiction, study and non-fiction, written down so the marks still mean something next month.',
    category: 'Annotation',
    readingTime: '8 min read',
    updated: '28 September 2026',
    publishedISO: '2026-09-28',
    updatedISO: '2026-09-28',
    related: [
      { href: '/guides/how-to-annotate-a-book-without-writing-in-it', label: 'How to annotate a book without writing in it' },
      { href: '/guides/scan-underlined-book-pages', label: 'How to scan underlined book pages' },
      { href: '/quotes', label: 'Quotes checked against the original text' },
      { href: '/quotes/a-christmas-carol', label: 'A Christmas Carol quotes' },
    ],
    intro:
      'An annotation key is a legend. This mark means this. This colour means that. Without the legend, a blue underline from March is just a blue line. Write the key down before you invent a twelfth symbol you will not remember.',
    relatedQueries: [
      'annotating books key',
      'how to annotate a book',
      'annotation key ideas',
      'how to annotate books with tabs',
    ],
    sections: [
      {
        heading: 'Keep the key shorter than you want',
        paragraphs: [
          'Six to eight marks is enough for a year of reading. A key of twenty symbols needs its own key, and you will not stop mid-chapter to consult it. If you cannot say the list aloud from memory, cut it.',
          'Write it on a card and keep the card in the front of the book, or on the first page of the notebook that travels with that book. A legend that lives in a notes app you never open during reading is not a legend. The [page on annotating without writing in the book](/guides/how-to-annotate-a-book-without-writing-in-it) is the version for library copies and anything you must return clean.',
        ],
      },
      {
        heading: 'Symbols that earn a place',
        paragraphs: [
          'Start from jobs, not from stationery. A mark should answer a question you will actually ask later: where is the sentence I might quote, where did I get lost, where do I disagree.',
          'A workable set looks like this. You do not have to adopt all of it.',
        ],
        bullets: [
          'Single underline: a sentence you might want again.',
          'Double underline: a sentence you would copy out.',
          'Vertical line in the margin: the whole paragraph, not one clause inside it.',
          'Circle: a word to look up, or a name you will otherwise forget.',
          'Asterisk: come back. A question for later, or a thing to try.',
          'Question mark: you do not understand it yet. Leave the muddle visible.',
          'A wavy line or a square bracket: you disagree. Add two or three words on why, or the mark is only a mood.',
        ],
      },
      {
        heading: 'Give each colour a job',
        paragraphs: [
          'Colour is optional. If you use it, give each colour one job and write that job on the card. A single colour that means “I liked this” will cover half the page by chapter four.',
          'One scheme that stays readable: yellow for the move of the plot or the step in the argument, pink for a line worth copying, blue for an image or a word that keeps returning, green for something to check before you repeat it. Swap the colours if you already own a different set of pens. The point is that yellow means the same thing on Tuesday and in November.',
          'Highlighter soaks through thin paper. Draw one short line on a blank page at the back of the book before you mark a chapter. If the next leaf shows the colour, switch to a pencil underline or to a tab on the edge.',
        ],
      },
      {
        heading: 'Tab colours belong to the same legend',
        paragraphs: [
          'A sticky tab sits on the edge of the page. It does not replace the mark next to the sentence, and a blank tab is only a bookmark with a colour. Write two or three words on it: “mother lies”, “definition”, “the salary”.',
          'Use the same colours as the pens, so yellow on the edge and yellow on the page are one idea. Place the tab so you can see it when the book is shut, and so it does not cover the line you meant to find. When the book is not yours, tabs and notes do the whole job. That method is written out in the [guide to annotating without writing in the book](/guides/how-to-annotate-a-book-without-writing-in-it).',
        ],
      },
      {
        heading: 'An example key for fiction',
        paragraphs: [
          'Fiction wants marks for pattern and for the moment your mind changes, not for “themes” you will invent at the end.',
        ],
        bullets: [
          'Underline: a sentence whose shape you want to remember.',
          'Margin line: a turn in the scene.',
          'Circle: a repeated image. The window, the meal, the hands.',
          'Asterisk: a line you might quote when you talk about the book.',
          'Question mark: a motive you do not believe yet.',
          'Pink tab on the edge: the page where you changed your mind about a character.',
        ],
      },
      {
        heading: 'An example key for study',
        paragraphs: [
          'A set text or a textbook chapter has a smaller list of jobs. Mark those, and leave the rest of the page clean. “Beautiful sentence” is a weak exam mark unless the question is about style.',
        ],
        bullets: [
          'Underline: a definition you must be able to say in your own words.',
          'Double underline: a line you might use in an essay.',
          'Margin line: an example that makes the definition concrete.',
          'Bracket: evidence, kept separate from the claim it supports.',
          'Asterisk: a comparison with another chapter or another book.',
          'Question mark: a point to ask someone who has read it more than once.',
        ],
      },
      {
        heading: 'An example key for non-fiction',
        paragraphs: [
          'Read for the claim, the support, and the thing you might do differently on Monday. A memoir and a practical book can share this key. A novel should not.',
        ],
        bullets: [
          'Underline: the claim, in the author’s words.',
          'Margin line: the evidence, or the story told in support of the claim.',
          'Circle: a method you could copy.',
          'Asterisk: a thing to try this week. If you will not try it, do not asterisk it.',
          'Bracket: you disagree. Write the objection in the margin in a few words.',
          'Green, pen or tab: a fact to check before you repeat it to anyone else.',
        ],
      },
      {
        heading: 'Use the same words in the app',
        paragraphs: [
          'BookQuotes keeps a custom marking vocabulary. It starts with a short list you can rename: underline, double underline, margin line, highlight, bracket, margin note, circle, asterisk, and question mark. Change the name, describe what the mark looks like on the page, and write what you mean by it. The card in the front of the book and the list in the app should use the same words. If the card says a wavy line means “I disagree”, the app should say that too.',
          'On capture the app can detect the page number. You still check it. Collections and tags come after the key, when the same idea shows up in more than one book. They are not a second legend of forty labels. The [scan guide](/guides/scan-underlined-book-pages) covers how to photograph the page so the words can be checked. BookQuotes does not import Kindle highlights.',
        ],
      },
    ],
    faqs: [
      {
        question: 'How many symbols should an annotation key have?',
        answer:
          'Six to eight. If you cannot remember the list without looking, it is too long. A short key you use on every page beats a clever one you abandon in chapter two.',
      },
      {
        question: 'Should I use the same key for every book?',
        answer:
          'Use one key for fiction and a different short key for study or for non-fiction. Do not invent a new legend for every title. The examples above are starting points you can copy onto a card and then amend.',
      },
      {
        question: 'What if last year’s colours already mean nothing?',
        answer:
          'Stop adding new colours. Pick four jobs, assign the pens you actually own, and write the new card. Leave the old marks as they are. You will not re-colour a finished book, and you do not need to.',
      },
      {
        question: 'Where should I keep the key?',
        answer:
          'On a card in the front of the book, or on the first page of the notebook that belongs with it. If you also keep the marks in BookQuotes, rename the markings so the names match the card.',
      },
      {
        question: 'Can the app store what each mark means?',
        answer:
          'Yes. You name each marking and write what it means. That vocabulary is yours. On capture the app can detect the page number. Collections and tags group lines across books. It does not import Kindle highlights.',
      },
    ],
  },
  {
    slug: 'how-to-annotate-a-book-without-writing-in-it',
    title: 'How to Annotate a Book Without Writing in It',
    query: 'how to annotate a book without writing in it',
    description:
      'Sticky notes, coloured tabs, a bookmark, pencil if you are allowed, a notebook, and a photo of the page before a borrowed book goes back.',
    category: 'Annotation',
    readingTime: '8 min read',
    updated: '28 September 2026',
    publishedISO: '2026-09-28',
    updatedISO: '2026-09-28',
    related: [
      { href: '/guides/book-annotation-key', label: 'How to make a book annotation key' },
      { href: '/guides/scan-underlined-book-pages', label: 'How to scan underlined book pages' },
      { href: '/quotes', label: 'Quotes checked against the original text' },
      { href: '/quotes/a-christmas-carol', label: 'A Christmas Carol quotes' },
    ],
    intro:
      'Library books, loans, gifts, and any copy you might sell later still need marks. The marks just cannot live in the paper. Sticky notes, tabs, a bookmark, a pencil only if the owner agrees, a notebook, and a photograph of the page will cover it.',
    relatedQueries: [
      'how to annotate a book without writing in it',
      'annotate a book with sticky notes',
      'how to annotate books with tabs',
      'annotate a book without ruining it',
    ],
    sections: [
      {
        heading: 'Decide what the owner will tolerate',
        paragraphs: [
          'If the book is not yours, assume that ink and highlighter are out. Pencil is a separate question. Ask. A light graphite line often lifts with a soft rubber, but some owners still refuse, and coated paper smears. If you have not asked, do not try it on page 12.',
          'Sticky notes and tabs come off. They are the default for a book you will return. For a copy you do own and are happy to mark, a written legend is more useful than a forest of flags. That legend is the [annotation key](/guides/book-annotation-key).',
        ],
      },
      {
        heading: 'Sticky notes: one idea, and not on the words',
        paragraphs: [
          'Write the note before you stick it down. A biro pressed through a flag will dent the type underneath. One idea per note. A paragraph on a small flag falls off and becomes litter in the bag.',
          'Park the note in the margin, or just below the line, with the sticky strip on blank paper when you can. Do not cover the sentence you will want to reread. When you finish, pull the notes out in order and deal with them the same day. A novel returned to the library still full of flags looks unfinished, and the notes get thrown away with the return.',
        ],
      },
      {
        heading: 'Tabs need a colour and two words',
        paragraphs: [
          'Colour is the category. The words on the tab are the reason. Use the same colours as your annotation key if you have one, so a yellow tab and a yellow pen are one idea. A tab that only says “good” will mean nothing in a month. Write “Ch3 claim”, “her hands”, or “for the essay”.',
          'Stick the tab on the outer edge so a closed book shows the row of colours. A tab buried in the gutter will not be found. Take every tab out before you return the book. Adhesive left for months goes yellow, and a tab in a library copy becomes the next reader’s problem.',
        ],
      },
      {
        heading: 'A bookmark for place, a card for pages',
        paragraphs: [
          'A ribbon means “I am here”. Do not also make it mean “this page mattered”. Those are two jobs, and one ribbon will do the wrong one. If you must not stick anything at all, keep a card in the book and write a short list on it: 42 the house, 87 the argument, 110 come back. The page number goes down at the moment you notice the page, not at the end of the chapter.',
          'Pencil, if you have permission: use a hard pencil, a light line, and a soft rubber afterwards. Do not press. On thin paper the groove shows on the next leaf even after the graphite has gone. When you are unsure, skip the pencil and use the notebook.',
        ],
      },
      {
        heading: 'Keep a notebook that is not the book',
        paragraphs: [
          'This is the method for a rare book, a loan, and any book you refuse to mark even when you could. Write the page number first, then a short run of the author’s words, then your own note underneath or on the facing page. If you copy the sentence and forget the page, you have made a search you will not enjoy.',
          'Put the book’s title and the date at the top of the page once. Separate the quotation from your comment with a blank line, so that in six months you can tell the author’s sentence from yours. A published list of lines, such as the [quotes index](/quotes), is someone else’s choice of what mattered. The notebook is yours.',
        ],
      },
      {
        heading: 'Photograph the page before the book goes back',
        paragraphs: [
          'Notes and tabs leave with you, or they go in the bin. The page does not. Take the photo while the book is still in the house, in even light, with the phone parallel to the page. Include the line you care about and a little of the paragraph around it. Framing is covered in the [scan guide](/guides/scan-underlined-book-pages).',
          'BookQuotes is for that photograph. On capture it can detect the page number, so you are not trusting a memory of “about 214”. You still check the number and the words against the print. On a library book the page is clean, so the note you typed on the tab goes in with the quotation. Custom markings are for a copy you do write in: you name each mark and what it means. Collections and tags are how you find the line later, next to lines from other books. The app does not import Kindle highlights.',
        ],
      },
    ],
    faqs: [
      {
        question: 'Will sticky notes damage the page?',
        answer:
          'They can, if you leave them on for years, or if you rip them off coated paper in a hurry. For a loan of a few weeks they are the ordinary tool. Take them off before you return the book. If the paper is fragile, skip the adhesive and use the notebook.',
      },
      {
        question: 'Is pencil always safe in a book?',
        answer:
          'No. Ask the owner first. Even with a yes, a soft pencil and a heavy hand will show. Use a hard pencil, a light line, and a soft rubber when you are finished. If the paper is thin, the dent remains after the mark has gone.',
      },
      {
        question: 'How do I clear a library book without losing the notes?',
        answer:
          'Photograph the page, or copy the page number and the note into the notebook, before you pull anything off. Do not do it from memory in the library queue. Then remove every tab and every flag.',
      },
      {
        question: 'What can I write on a tab that is too small for a sentence?',
        answer:
          'A label, not the quotation. “Ch3 claim” or “her hands” is enough. The author’s words go in the notebook or into the photograph, with the page number.',
      },
      {
        question: 'Can I keep a searchable copy without writing in the book?',
        answer:
          'Yes. Photograph the page, check the words, and keep your note with the line. BookQuotes can detect the page number on capture. Collections and tags group it with other books. You name your own markings for copies you do write in. It does not import Kindle highlights.',
      },
    ],
  },
  {
    slug: 'how-to-digitise-book-notes',
    title: 'Digitise Book Notes Without Losing Context',
    query: 'how to digitise book notes',
    description:
      'A simple system for preserving the passage, book, page and personal note when moving from paper to a searchable library.',
    category: 'Reading workflow',
    readingTime: '6 min read',
    updated: '28 September 2026',
    publishedISO: '2026-08-03',
    updatedISO: '2026-09-28',
    related: [
      { href: '/guides/how-to-save-quotes-from-physical-books', label: 'How to save quotes from physical books' },
      { href: '/guides/scan-underlined-book-pages', label: 'How to scan underlined book pages' },
      { href: '/guides/export-book-quotes-to-obsidian', label: 'Export book quotes to Obsidian and Notion' },
    ],
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
          'Photograph the marked page, wait for the available extraction route to finish, and read the result against the photograph. Correct the text before adding tags or moving on. A small correction now prevents a frustrating search later. The [save-quotes guide](/guides/how-to-save-quotes-from-physical-books) walks through that capture in order.',
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
      'What a commonplace book is, how it differs from a reading journal, and a simple way to keep passages from paper books.',
    category: 'Reading practice',
    readingTime: '8 min read',
    updated: '28 September 2026',
    publishedISO: '2026-08-03',
    updatedISO: '2026-09-28',
    intro:
      'A commonplace book is a personal collection of passages, observations, questions and ideas you expect to return to. A digital version does not need to imitate a social feed or become a productivity dashboard. Its job is to keep the lines you chose, with enough context that they still make sense later.',
    relatedQueries: ['commonplace book app', 'digital reading journal', 'personal quote library', 'commonplace book examples'],
    related: [
      { href: '/guides/how-to-save-quotes-from-physical-books', label: 'How to save quotes from physical books' },
      { href: '/journal/what-to-do-with-book-highlights', label: 'What to do with highlights after a book' },
      { href: '/guides/organise-book-quotes-on-iphone', label: 'Organise book quotes on iPhone' },
      { href: '/guides/export-book-quotes-to-obsidian', label: 'Export book quotes to Obsidian and Notion' },
    ],
    sections: [
      {
        heading: 'A commonplace book is selective',
        paragraphs: [
          'The practice works because it involves judgment. You do not need to save every interesting sentence. Keep the lines that clarify a question, change how you see something, or give you language you expect to use again.',
          'When a sentence earns an underline, pause long enough to ask why. It may explain an idea clearly, challenge an assumption, or give language to something you already felt. That short reason is often more useful than a complicated tagging system.',
          'That selectiveness also protects the collection from becoming a second inbox. A smaller library that you revisit is more valuable than an archive you never open.',
        ],
      },
      {
        heading: 'A few kinds of entry that earn their place',
        paragraphs: [
          'A commonplace is not a reading journal. A journal records that you read: the date, the plot, how the book felt. A commonplace keeps the bit you want to use again. The two can sit side by side. They answer different questions.',
          'Entries that tend to repay the effort include a definition you will want in your own words later, a sentence that names a feeling more cleanly than you can, a passage you disagree with and want to answer, and a line you expect to quote in something you are writing. A plot summary rarely belongs. You already have the book for that.',
        ],
      },
      {
        heading: 'Use one capture ritual',
        paragraphs: [
          'Finish the page before you reach for the phone. Then photograph the marked passage, review the extracted text, and correct anything the camera missed. Keep the book title and page number with the quote. [How to save quotes from physical books](/guides/how-to-save-quotes-from-physical-books) sets that order out, and the [scan guide](/guides/scan-underlined-book-pages) covers light and framing.',
          'The review matters. A searchable transcription is useful only when it still says what the author wrote. Treat extraction as a first draft and let your own eyes make the final decision.',
        ],
      },
      {
        heading: 'Paper and digital can work together',
        paragraphs: [
          'The physical book remains the place where you read, mark, and make the first connection. The digital library handles retrieval. This division means you can keep the feel of paper while still searching the ideas when you are away from the shelf.',
          'BookQuotes is built around that handoff: add the book by ISBN or by hand, capture a marked page, review the text, and return to the passage through search, a tag or a collection.',
        ],
      },
      {
        heading: 'Return to the collection',
        paragraphs: [
          'A commonplace book becomes valuable through reuse. Search it while you are writing, look back at a few saved passages at the end of the week, or choose one idea to discuss with somebody else. [What to do with highlights after you finish a book](/journal/what-to-do-with-book-highlights) is a longer version of that review.',
          'Choose a question you are already carrying, such as “What am I learning about attention?” or “Which passages change how I approach this project?” Save only the passages that help answer it. At the end of the week, write one short connection in your own words.',
          'When a project needs the notes on a larger screen, [export the quotes to Obsidian or Notion](/guides/export-book-quotes-to-obsidian) and leave the books on the shelf.',
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
    updated: '28 September 2026',
    publishedISO: '2026-08-03',
    updatedISO: '2026-09-28',
    related: [
      { href: '/guides/digital-commonplace-book', label: 'What is a digital commonplace book?' },
      { href: '/guides/how-to-search-quotes-from-paper-books', label: 'How to search quotes from paper books' },
      { href: '/guides/export-book-quotes-to-obsidian', label: 'Export book quotes to Obsidian and Notion' },
    ],
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
          'Export when you need to work in another tool. Keeping an independent copy is especially sensible for a local-first library. [Searching quotes from paper books](/guides/how-to-search-quotes-from-paper-books) is the other half of the same habit.',
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
    updated: '28 September 2026',
    publishedISO: '2026-08-03',
    updatedISO: '2026-09-28',
    related: [
      { href: '/journal/ai-extraction-and-reader-control', label: 'How AI extraction and reader review work' },
      { href: '/privacy', label: 'Privacy policy' },
      { href: '/guides/how-to-save-quotes-from-physical-books', label: 'How to save quotes from physical books' },
    ],
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
          'Remote processing is optional in the product flow. Read the current [privacy policy](/privacy) before enabling it, especially if the page contains material you do not want to send to a third-party provider. The [note on AI extraction](/journal/ai-extraction-and-reader-control) says what is sent and what stays on the phone.',
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
    title: 'Find Quotes in Your Paper Books',
    query: 'book quote finder',
    description:
      'Turn marked passages from your own paper books into a library you can search by wording, book and page.',
    category: 'Book quote search',
    readingTime: '6 min read',
    updated: '28 September 2026',
    publishedISO: '2026-09-13',
    updatedISO: '2026-09-28',
    related: [
      { href: '/guides/how-to-search-quotes-from-paper-books', label: 'How to search quotes from paper books' },
      { href: '/guides/scan-underlined-book-pages', label: 'How to scan underlined book pages' },
      { href: '/guides/quote-reader-app-for-physical-books', label: 'Capture and search paper book quotes' },
    ],
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
        heading: 'Step 4: Search the lines you saved',
        paragraphs: [
          'Search looks through the passage, the margin note, the book title and the author. It does not look through tag names or collection names. You can still filter the book list by a tag or a collection when you want that group on screen. A single remembered word is often enough, and the result shows the page number when the quote has one. [How to search quotes from paper books](/guides/how-to-search-quotes-from-paper-books) is the longer version of that habit.',
          'The library stays on the device in the current release. Search works on a train with no connection.',
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
    title: 'Capture and Search Paper Book Quotes',
    query: 'quote reader app for physical books',
    description:
      'Photograph underlines, brackets and margin notes, then keep an accurate, searchable library of those passages on iPhone and iPad.',
    category: 'Quote capture',
    readingTime: '6 min read',
    updated: '28 September 2026',
    publishedISO: '2026-09-13',
    updatedISO: '2026-09-28',
    related: [
      { href: '/guides/how-to-save-quotes-from-physical-books', label: 'How to save quotes from physical books' },
      { href: '/guides/scan-underlined-book-pages', label: 'How to scan underlined book pages' },
      { href: '/guides/book-quote-finder-iphone', label: 'Find quotes in your paper books' },
    ],
    intro:
      'A quote reader for paper books keeps the sentences you underline, and the notes in the margin, somewhere you can search later. The mark helps while the book is open. Months later the line is still on a shelf. Photograph the page, check the words the app read, and save the passage with the book and your own comment.',
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
          'Mark freely with pen or pencil while you read. When you finish a chapter or close the book for the evening, spend a couple of minutes photographing the marked pages. Review the text, confirm the passages, and stop. [How to save quotes from physical books](/guides/how-to-save-quotes-from-physical-books) is the same routine written as steps.',
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
    title: 'How to Search Quotes from Paper Books',
    query: 'how to search quotes from paper books',
    description:
      'A practical way to index physical book highlights and margin notes so you can search them by keyword, author or theme.',
    category: 'Search workflow',
    readingTime: '6 min read',
    updated: '28 September 2026',
    publishedISO: '2026-09-13',
    updatedISO: '2026-09-28',
    related: [
      { href: '/guides/book-quote-finder-iphone', label: 'Find quotes in your paper books' },
      { href: '/guides/organise-book-quotes-on-iphone', label: 'Organise book quotes on iPhone' },
      { href: '/guides/export-book-quotes-to-obsidian', label: 'Export book quotes to Obsidian and Notion' },
    ],
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
          'Use BookQuotes to photograph the marked passage instead. The app isolates the underlined text, transcribes it through on-device OCR or optional remote AI, and pairs it with the book title, author, and page number. Check the words on screen before you save them. [How to scan an underlined page](/guides/scan-underlined-book-pages) is worth reading if the photos keep coming back muddy.',
        ],
      },
      {
        heading: 'Phase 3: Add a little structure',
        paragraphs: [
          'Full-text search handles distinct vocabulary well, but conceptual searches benefit from light curation. When saving a passage, consider adding one or two topical tags such as “stoicism”, “habit-formation”, or “character-study”.',
          'Avoid over-tagging. Creating dozens of intricate categories produces maintenance fatigue. Let keyword search do the heavy lifting for specific words, and use collections only for major reading projects or active writing endeavours.',
        ],
      },
      {
        heading: 'Phase 4: Putting your searchable library to work',
        paragraphs: [
          'The useful day is the one when you need a line and can only remember a scrap of it. You are writing a paragraph, or notes for a meeting, and the book is in another room.',
          'Type a word you do remember. Search checks the passages, margin notes, titles and authors you saved, and lists the matches as you type. The page number is there when the quote has one, so you know which volume to take off the shelf.',
        ],
      },
    ],
    faqs: [
      {
        question: 'Can I search my paper book quotes by concept rather than exact words?',
        answer:
          'A short note in your own words is included in search, so you can find a passage when the author used different terms. Tags are labels for grouping. The text search does not look at tag names. Open the tag in the library if you want that group.',
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
    title: 'Book Quotes vs Kindle Highlights',
    query: 'book quotes vs kindle highlights',
    description:
      'How paper-book capture compares with Kindle highlights, and what BookQuotes does and does not take from an e-reader.',
    category: 'Reading comparison',
    readingTime: '6 min read',
    updated: '28 September 2026',
    publishedISO: '2026-09-13',
    updatedISO: '2026-09-28',
    related: [
      { href: '/guides/how-to-save-quotes-from-physical-books', label: 'How to save quotes from physical books' },
      { href: '/guides/export-book-quotes-to-obsidian', label: 'Export book quotes to Obsidian and Notion' },
      { href: '/guides/quote-reader-app-for-physical-books', label: 'Capture and search paper book quotes' },
    ],
    intro:
      'Readers often feel forced to choose between the tactile pleasure of physical books and the convenience of Kindle highlights. An e-reader makes highlights easy to search. Many people prefer paper for long reading and like keeping the screen out of the hour. You can read on paper and still keep a searchable library of the lines you mark.',
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
          'Yet many readers find digital reading flat. A paper book makes it easier to remember where an argument sat on the page, and it keeps notifications out of the hour. That is a preference, not a measured law.',
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
          'BookQuotes is for the paper copy. It does not import Kindle highlights. You read the printed book with a pencil, then photograph the pages you marked. The app extracts the text, you check the wording, and the passage is filed with the book. [How to save quotes from physical books](/guides/how-to-save-quotes-from-physical-books) is the capture routine.',
        ],
      },
      {
        heading: 'Intentional capture creates better memory retention',
        paragraphs: [
          'A Kindle highlight is one drag of the thumb. It is easy to mark a whole page and keep going, then later find a clipping file full of lines you barely chose.',
          'Photographing a paper page and checking the words takes longer. You read the sentence again before it is saved. That second look is the useful part.',
        ],
      },
      {
        heading: 'Unified export to open personal knowledge systems',
        paragraphs: [
          'BookQuotes can export paper quotes to Markdown, plain text, JSON, Notion or Obsidian. There is no Kindle import in the app. If you already keep Kindle clippings in a vault, you can place an export beside them yourself. [Exporting to Obsidian and Notion](/guides/export-book-quotes-to-obsidian) covers the file formats.',
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
    title: 'Export Book Quotes to Obsidian and Notion',
    query: 'export book quotes to obsidian',
    description:
      'What the Markdown, plain text, JSON, Notion and Obsidian exports actually contain, and how to move those files into a vault.',
    category: 'Export workflows',
    readingTime: '6 min read',
    updated: '28 September 2026',
    publishedISO: '2026-09-13',
    updatedISO: '2026-09-28',
    related: [
      { href: '/guides/digital-commonplace-book', label: 'What is a digital commonplace book?' },
      { href: '/guides/organise-book-quotes-on-iphone', label: 'Organise book quotes on iPhone' },
      { href: '/guides/how-to-digitise-book-notes', label: 'Digitise book notes without losing context' },
    ],
    intro:
      'The phone is a good place to catch a line while the book is still in your hand. Longer writing usually happens at a desk. This page is how to move the passages you saved, with the book and the page, without typing them out again.',
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
          'Obsidian and Notion are where a lot of people already keep articles, newsletters and notes from PDFs. The paper books often stay out of that pile.',
          'If a line never leaves the book, it is not in the notes you write from. Export is the handoff: a file with the passage, the book and, when you saved one, the page.',
        ],
      },
      {
        heading: 'What each export file contains',
        paragraphs: [
          'The export screen offers five formats: Markdown, plain text, JSON, Notion and Obsidian. There is no CSV file. Notion is a Markdown file you import yourself, not a connection to a Notion account. Obsidian is one Markdown note per book. Nothing is sent off the phone by the export, and cloud sync is off in this release.',
          'Page numbers and margin notes are included when the quote has them and those options are left on. The four switches on the export screen can turn metadata, book grouping, page numbers or margin notes off. With the switches left on, the files differ like this:',
        ],
        bullets: [
          'Markdown: one file. Quotes sit under the book title and author. Each passage is a blockquote, then the page number and the marking name, then your margin note. No capture date, and none of the tags you assigned.',
          'Plain text: the same grouping, as ordinary lines. The line under a quote can include the page, the marking, and the book title and author, then the margin note. No capture date and no tags.',
          'JSON: a backup. Each book can include its title, author and ISBN. Each quote can include the text, page number, margin note, marking name, extraction confidence, capture date, and the book title and author. Tags are not in the file.',
          'Notion: one Markdown file. A heading for the book, a table with the author, reading status and quote count, then each passage with its page and marking, and your note. No capture date and no tags.',
          'Obsidian: one Markdown note for each book that has quotes. The header has the title, author, ISBN if the book has one, the number of quotes, and the date you exported. It also adds two tags of its own, book-quotes and reading. Passages are ordered by page and can include the page, the marking and the margin note. Your own tags, and the date you captured the quote, are not written into this file.',
        ],
      },
      {
        heading: 'Setting up an Obsidian literature note workflow',
        paragraphs: [
          'Keep what the author wrote separate from what you think about it. The Obsidian export is already one note per book, named from the title. Drop that file into a folder such as Literature Notes.',
          'Each passage is a blockquote. Under it you get the page, when the quote has one, and the marking name, then your margin note. The tags you set in the app are not in the file. Add them in Obsidian if you still want them, and link the passage into the note you are writing with [[Note Name]].',
        ],
        bullets: [
          'The page number is included only when the quote has one.',
          'Add your own tags in the vault. The export does not copy them from the app.',
          'Link a passage into the note you are actually writing.',
        ],
      },
      {
        heading: 'Importing quotes into Notion databases',
        paragraphs: [
          'Export the Notion format and import that Markdown file yourself. It is not a CSV, and the app does not create a Notion database for you. If you would rather start from structured data, use the JSON export. The ordinary Markdown export is the other option.',
          'Once the file is in Notion, you can add properties for title, author, page and tags, and filter them however you like. Those properties are yours to set up. They are not columns in the export.',
        ],
      },
      {
        heading: 'Closing the loop: from physical page to finished writing',
        paragraphs: [
          'The point of the notes is the work you do with them. Read on paper, capture the lines you want to keep, and export them when you are ready to write. A [digital commonplace book](/guides/digital-commonplace-book) is one way to decide which lines are worth that trip.',
          'When you write, the passages are in that file, with the book named. You search them there, instead of hunting through the closed paperback.',
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
          'It depends on the format. With the usual options left on, Markdown, plain text, Notion and Obsidian include the book title and author, the marking, and your margin note. They include the page number only when the quote has one. Only JSON includes the capture date. None of these exports include the tags you assigned in the app. The Obsidian note adds its own book-quotes and reading tags, plus the ISBN when the book has one, and the date of the export rather than the capture date.',
      },
      {
        question: 'Can I export a single book or do I have to export the entire library?',
        answer:
          'From a book you can export that book’s passages. From Settings you can export every passage in the library. A collection is not its own export.',
      },
      {
        question: 'Does BookQuotes sync automatically to Notion via API?',
        answer:
          'No. Export writes a file on the phone: Markdown, plain text, JSON, a Notion Markdown file, or an Obsidian note. You import that file yourself. Cloud sync is not enabled in the current release.',
      },
    ],
  },
]

export function getGuide(slug: string) {
  return guides.find((guide) => guide.slug === slug)
}
