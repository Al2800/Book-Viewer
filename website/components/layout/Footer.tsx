const afterword = [
  { label: 'Journal', href: '/journal' },
  { label: 'Guides', href: '/guides' },
  { label: 'Support', href: '/support' },
  { label: 'Privacy', href: '/privacy' },
  { label: 'Terms', href: '/terms' },
]

export function Footer() {
  return (
    <footer className="bg-paper-cream">
      <div className="container-narrow section-padding-loose">
        <p className="font-display text-2xl md:text-3xl text-ink-black leading-snug mb-3">
          Keep the lines.
        </p>
        <p className="font-body text-ink-dark mb-8">
          — BookQuotes, {new Date().getFullYear()}
        </p>
        <p className="font-ui text-sm text-ink-medium">
          P.S.{' '}
          {afterword.map((link, index) => (
            <span key={link.href}>
              <a
                href={link.href}
                className="underline-offset-4 hover:underline whitespace-nowrap"
              >
                {link.label}
              </a>
              {index < afterword.length - 1 ? ' · ' : ''}
            </span>
          ))}
        </p>
      </div>
    </footer>
  )
}
