import { BookOpen, Twitter, Instagram, Github } from 'lucide-react'

const footerLinks = {
  product: [
    { label: 'Features', href: '#features' },
    { label: 'Pricing', href: '#pricing' },
    { label: 'Download', href: 'https://apps.apple.com/app/bookquotes' },
  ],
  company: [
    { label: 'About', href: '/about' },
    { label: 'Blog', href: '/blog' },
    { label: 'Contact', href: 'mailto:hello@bookquotes.app' },
  ],
  legal: [
    { label: 'Privacy Policy', href: '/privacy' },
    { label: 'Terms of Service', href: '/terms' },
  ],
}

const socialLinks = [
  { icon: Twitter, href: 'https://twitter.com/bookquotesapp', label: 'Twitter' },
  { icon: Instagram, href: 'https://instagram.com/bookquotesapp', label: 'Instagram' },
  { icon: Github, href: 'https://github.com/bookquotes', label: 'GitHub' },
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

          {/* Company Links */}
          <div>
            <h4 className="font-ui font-semibold text-ink-black mb-4">Company</h4>
            <ul className="space-y-3">
              {footerLinks.company.map((link) => (
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
