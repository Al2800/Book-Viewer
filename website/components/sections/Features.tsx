const features = [
  {
    title: 'Multi-page session capture',
    description: 'Photograph multiple marked pages in a continuous reading session. Process immediately or keep them in an offline queue without breaking your reading flow.',
  },
  {
    title: 'Full-text library search',
    description: 'Search across every saved passage, margin note, author, and book title in your library. Find that half-remembered sentence instantly.',
  },
  {
    title: 'Custom annotation vocabulary',
    description: 'Define your own marking system. Single underlines, margin brackets, asterisks, and highlights—set custom definitions for how you read.',
  },
  {
    title: 'Review before saving',
    description: 'AI extraction provides an instant first draft. Inspect wording, refine page boundaries, and verify notes before text enters your permanent collection.',
  },
  {
    title: 'Private on-device library',
    description: 'Your reading history and saved quotes remain stored locally on your device in this release. No tracking, ads, or behavioral analytics.',
  },
  {
    title: 'Export to Obsidian and Notion',
    description: 'Take your quotes anywhere. Export your library to clean Markdown, Obsidian-formatted notes, Notion, plain text, or structured JSON.',
  },
]

export function Features() {
  return (
    <section id="features" className="bg-paper-warm">
      <div className="container-standard section-padding-loose">
        <h2 className="mb-3">What you can do</h2>
        <p className="text-lg text-ink-medium max-w-prose mb-12">
          Capture, correct, search, and export. A dedicated tool for readers who take paper notes seriously.
        </p>
        <dl>
          {features.map((feature) => (
            <div
              key={feature.title}
              className="grid md:grid-cols-[minmax(0,15rem)_1fr] gap-3 md:gap-10 py-6 border-t border-subtle last:border-b"
            >
              <dt className="font-display text-lg text-ink-black min-w-0">{feature.title}</dt>
              <dd className="text-ink-dark min-w-0 leading-relaxed">{feature.description}</dd>
            </div>
          ))}
        </dl>
      </div>
    </section>
  )
}
