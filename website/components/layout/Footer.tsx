import { BookOpen, Github, Mail } from 'lucide-react'

const footerLinks = {
  product: [
    { label: 'Features', href: '/#features' },
    { label: 'How It Works', href: '/#how-it-works' },
    { label: 'App Store', href: 'https://apps.apple.com/app/id6758091579' },
  ],
  resources: [
    { label: 'Journal', href: '/journal' },
    { label: 'Support', href: '/support' },
    { label: 'Contact', href: 'mailto:acampbell193@googlemail.com' },
    { label: 'GitHub', href: 'https://github.com/Al2800' },
  ],
  legal: [
    { label: 'Privacy Policy', href: '/privacy' },
    { label: 'Terms of Service', href: '/terms' },
  ],
}

const socialLinks = [
  { icon: Mail, href: 'mailto:acampbell193@googlemail.com', label: 'Email support' },
  { icon: Github, href: 'https://github.com/Al2800', label: 'GitHub' },
]

export function Footer() {
  return (
    <footer className="bg-paper-warm border-t border-subtle">
      <div className="container-wide section-padding">
        <div className="grid grid-cols-2 md:grid-cols-5 gap-8 md:gap-12">
          {/* Brand */}
          <div className="col-span-2">
            <a href="/" className="flex items-center gap-2 font-display text-xl font-semibold text-ink-black mb-4">
              <BookOpen className="w-6 h-6 text-gold-primary" />
              <span>BookQuotes</span>
            </a>
            <p className="text-ink-medium font-body max-w-xs">
              Transform your reading. Capture the passages that matter most.
            </p>
          </div>

          {/* Product Links */}
          <div>
            <h4 className="font-ui font-semibold text-ink-black mb-4">Product</h4>
            <ul className="space-y-3">
              {footerLinks.product.map((link) => (
                <li key={link.label}>
                  <a
                    href={link.href}
                    className="text-ink-medium hover:text-gold-primary transition-colors font-ui text-sm"
                  >
                    {link.label}
                  </a>
                </li>
              ))}
            </ul>
          </div>

          {/* Resource Links */}
          <div>
            <h4 className="font-ui font-semibold text-ink-black mb-4">Resources</h4>
            <ul className="space-y-3">
              {footerLinks.resources.map((link) => (
                <li key={link.label}>
                  <a
                    href={link.href}
                    className="text-ink-medium hover:text-gold-primary transition-colors font-ui text-sm"
                    target={link.href.startsWith('http') ? '_blank' : undefined}
                    rel={link.href.startsWith('http') ? 'noopener noreferrer' : undefined}
                  >
                    {link.label}
                  </a>
                </li>
              ))}
            </ul>
          </div>

          {/* Legal Links */}
          <div>
            <h4 className="font-ui font-semibold text-ink-black mb-4">Legal</h4>
            <ul className="space-y-3">
              {footerLinks.legal.map((link) => (
                <li key={link.label}>
                  <a
                    href={link.href}
                    className="text-ink-medium hover:text-gold-primary transition-colors font-ui text-sm"
                  >
                    {link.label}
                  </a>
                </li>
              ))}
            </ul>
          </div>
        </div>

        {/* Bottom Bar */}
        <div className="mt-12 pt-8 border-t border-subtle flex flex-col md:flex-row items-center justify-between gap-4">
          <p className="text-ink-light text-sm font-ui">
            &copy; {new Date().getFullYear()} BookQuotes. Made with care for book lovers.
          </p>
          <div className="flex items-center gap-4">
            {socialLinks.map((social) => (
              <a
                key={social.label}
                href={social.href}
                target="_blank"
                rel="noopener noreferrer"
                className="text-ink-light hover:text-gold-primary transition-colors"
                aria-label={social.label}
              >
                <social.icon className="w-5 h-5" />
              </a>
            ))}
          </div>
        </div>
      </div>
    </footer>
  )
}
