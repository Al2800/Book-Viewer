const steps = [
  {
    stage: '1',
    title: 'Photograph marked pages',
    description: 'Snap photos of pages with underlines, highlights, or margin notes. On-device quality assessment checks for blur and lighting before processing.',
  },
  {
    stage: '2',
    title: 'Extract and review',
    description: 'AI isolates the exact passages you marked and matches page context. Review, edit wording, or add custom notes before saving.',
  },
  {
    stage: '3',
    title: 'Search, organize, and export',
    description: 'Build your personal quote library. Search across every book you own, filter by custom tags, and export directly to Obsidian, Notion, Markdown, or JSON.',
  },
]

export function HowItWorks() {
  return (
    <section id="method" className="section-padding-loose">
      <div className="container-standard">
        <h2 className="mb-3">How it works</h2>
        <p className="text-lg text-ink-medium max-w-prose mb-12">
          Three steps from a marked paper book to a quote you can find in seconds.
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
