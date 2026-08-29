export function Problem() {
  return (
    <section className="bg-paper-warm">
      <div className="container-standard section-padding">
        <h2 className="mb-5">The reading dilemma</h2>
        <p className="text-lg text-ink-dark max-w-prose mb-8">
          You underline sentences. You draw margin lines. You scribble notes.
          Then the book goes back on the shelf, and the line is trapped in the
          object you marked.
        </p>
        <div className="grid md:grid-cols-2 gap-12 md:gap-16">
          <div className="border-t border-subtle pt-6">
            <h3 className="text-lg font-display mb-4">What gets lost</h3>
            <ul className="space-y-3 text-ink-dark">
              <li className="flex items-start gap-2">
                <span className="text-ink-medium select-none">&mdash;</span>
                <span>Highlights stay trapped inside closed books</span>
              </li>
              <li className="flex items-start gap-2">
                <span className="text-ink-medium select-none">&mdash;</span>
                <span>Margin notes get forgotten over time</span>
              </li>
              <li className="flex items-start gap-2">
                <span className="text-ink-medium select-none">&mdash;</span>
                <span>You cannot search across your physical shelf</span>
              </li>
              <li className="flex items-start gap-2">
                <span className="text-ink-medium select-none">&mdash;</span>
                <span>Manual typing takes too long to keep up</span>
              </li>
            </ul>
          </div>
          <div className="border-t border-subtle pt-6">
            <h3 className="text-lg font-display mb-4">What BookQuotes does</h3>
            <ul className="space-y-3 text-ink-dark">
              <li className="flex items-start gap-2">
                <span className="text-ink-medium select-none">&mdash;</span>
                <span>Snap photos of any marked page in seconds</span>
              </li>
              <li className="flex items-start gap-2">
                <span className="text-ink-medium select-none">&mdash;</span>
                <span>Isolate marked lines and review before saving</span>
              </li>
              <li className="flex items-start gap-2">
                <span className="text-ink-medium select-none">&mdash;</span>
                <span>Search full text across your entire reading history</span>
              </li>
              <li className="flex items-start gap-2">
                <span className="text-ink-medium select-none">&mdash;</span>
                <span>Export clean notes to Obsidian, Notion, or Markdown</span>
              </li>
            </ul>
          </div>
        </div>
      </div>
    </section>
  )
}
