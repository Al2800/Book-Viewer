const steps = [
  {
    stage: '1',
    title: 'Photograph marked pages',
    description: 'Snap photos of pages with underlines, highlights, or margin notes. On-device quality assessment checks for blur and lighting before processing.',
  },
  {
    stage: '2',
    title: 'Extract and review',
    description: 'The app suggests the marked passage from the photo. Check the wording against the page, correct the page number if it is wrong, and add a note before you save.',
  },
  {
    stage: '3',
    title: 'Search, organize, and export',
    description: 'Search the passages, notes, titles and authors you saved. Filter the book list with tags and collections. Export one book or the whole library as Markdown, plain text, JSON, Notion or Obsidian.',
  },
]

export function HowItWorks() {
  return (
    <section id="method" className="section-padding-loose">
      <div className="container-standard">
        <h2 className="mb-3">How it works</h2>
        <p className="text-lg text-ink-medium max-w-prose mb-12">
          Three steps from a marked paper book to a quote you can search for later.
        </p>
        <ol className="space-y-10">
          {steps.map((step) => (
            <li key={step.stage} className="grid md:grid-cols-[4rem_1fr] gap-4 md:gap-8 items-start">
              <span className="font-ui text-sm font-medium text-ink-medium pt-2">{step.stage}</span>
              <div>
                <h3 className="text-2xl mb-2">{step.title}</h3>
                <p className="text-lg text-ink-dark max-w-prose">{step.description}</p>
              </div>
            </li>
          ))}
        </ol>
      </div>
    </section>
  )
}
