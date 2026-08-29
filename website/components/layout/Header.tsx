const navLinks = [
  { href: '/journal', label: 'Journal' },
  { href: '/guides', label: 'Guides' },
]

export function Header() {
  return (
    <header className="bg-paper-cream">
      <div className="container-wide py-6 md:py-8 text-center">
        <p className="font-ui text-xs tracking-[0.08em] uppercase text-ink-medium mb-3">
          For readers who mark the page
        </p>
        <a
          href="/"
          className="font-display text-ink-black block text-[clamp(2rem,6vw,3.25rem)] leading-none tracking-tight mb-5"
        >
          BookQuotes
        </a>
        <nav aria-label="Primary">
          <ul className="flex flex-wrap items-center justify-center gap-x-8 gap-y-3">
            {navLinks.map((link) => (
              <li key={link.href}>
                <a
                  href={link.href}
                  className="font-ui text-sm text-ink-dark whitespace-nowrap underline-offset-4 hover:underline"
                >
                  {link.label}
                </a>
              </li>
            ))}
            <li>
              <a
                href="https://apps.apple.com/app/id6758091579"
                target="_blank"
                rel="noopener noreferrer"
                className="font-ui text-sm text-ink-black whitespace-nowrap border-b border-ink-black pb-0.5"
              >
                Get the app
              </a>
            </li>
          </ul>
        </nav>
        <hr className="rule-double mt-6 md:mt-8" aria-hidden="true" />
      </div>
    </header>
  )
}
