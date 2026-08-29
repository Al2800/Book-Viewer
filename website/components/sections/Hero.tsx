import Image from 'next/image'

export function Hero() {
  return (
    <section className="section-padding">
      <div className="container-wide grid lg:grid-cols-[7fr_5fr] gap-12 lg:gap-16 items-start">
        <div>
          <h1 className="text-balance mb-6">
            Save the lines you underlined
          </h1>
          <p className="text-lg md:text-xl text-ink-dark max-w-prose mb-8">
            Transform marked pages from physical books into a private, searchable
            digital commonplace book. Capture your underlines, margin notes, and
            highlights, review extracted passages, and keep the lines you want to find again.
          </p>
          <div className="flex flex-col sm:flex-row sm:flex-wrap gap-4 sm:items-center">
            <div>
              <a
                href="https://apps.apple.com/app/id6758091579"
                target="_blank"
                rel="noopener noreferrer"
                className="btn-primary"
              >
                Get the app
              </a>
              <p className="font-ui text-xs text-ink-medium mt-1.5">
                7-day free trial · Designed for iPhone
              </p>
            </div>
            <a
              href="#method"
              className="font-ui text-sm text-ink-black underline underline-offset-4 whitespace-nowrap self-start sm:self-auto pt-1 pb-4 sm:pb-0"
            >
              Read the method
            </a>
          </div>
        </div>

        <figure className="min-w-0">
          <div className="space-y-4">
            <Image
              src="/screenshots/library.png"
              alt="BookQuotes library showing saved books and quotes"
              width={603}
              height={1311}
              priority
              sizes="(max-width: 1024px) 100vw, 360px"
              className="w-full max-w-sm border border-subtle bg-paper-aged"
            />
            <div className="max-w-sm p-4 bg-paper-warm border border-subtle">
              <div className="flex items-center justify-between text-xs font-ui text-ink-medium mb-1.5">
                <span>Four Thousand Weeks · p. 34</span>
                <span className="uppercase tracking-wider text-[10px] border border-subtle px-1.5 py-0.5">Underline</span>
              </div>
              <blockquote className="font-body text-ink-black text-sm italic leading-snug mb-2">
                &ldquo;The world is already filled to the brim with things that are worthwhile and interesting... you&rsquo;ll never get around to experiencing more than a microscopic fraction of them.&rdquo;
              </blockquote>
              <p className="font-ui text-xs text-ink-medium">
                Saved to personal library · <span className="text-ink-dark">#philosophy #habits</span>
              </p>
            </div>
          </div>
          <figcaption className="mt-3 font-ui text-sm text-ink-medium max-w-sm">
            A first-party library screen and saved quote specimen. The page, not a drawn phone.
          </figcaption>
        </figure>
      </div>
    </section>
  )
}
