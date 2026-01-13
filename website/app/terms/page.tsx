import { Header } from '@/components/layout/Header'
import { Footer } from '@/components/layout/Footer'
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'Terms of Service — BookQuotes',
  description: 'Terms and conditions for using BookQuotes.',
}

export default function TermsPage() {
  return (
    <>
      <Header />
      <main className="pt-24 pb-16">
        <article className="container-narrow prose prose-ink max-w-none">
          <h1 className="font-display">Terms of Service</h1>
          <p className="text-ink-medium text-lg">Last updated: January 2025</p>

          <section className="mt-12">
            <h2>Agreement to Terms</h2>
            <p>
              By downloading or using BookQuotes, you agree to these Terms of Service.
              If you do not agree, please do not use the app.
            </p>
          </section>

          <section className="mt-8">
            <h2>Description of Service</h2>
            <p>
              BookQuotes is a mobile application that helps you capture and organize
              quotes from physical books using AI-powered text extraction. The service
              includes:
            </p>
            <ul>
              <li>Image capture and processing</li>
              <li>AI-powered text extraction</li>
              <li>Quote organization and search</li>
              <li>Export functionality</li>
            </ul>
          </section>

          <section className="mt-8">
            <h2>User Responsibilities</h2>
            <p>You agree to:</p>
            <ul>
              <li>Use the app only for personal, non-commercial purposes</li>
              <li>Not attempt to reverse engineer or modify the app</li>
              <li>Not use the app to violate copyright or other laws</li>
              <li>Maintain the security of your account credentials</li>
            </ul>
          </section>

          <section className="mt-8">
            <h2>Copyright and Fair Use</h2>
            <p>
              BookQuotes is designed for personal use in capturing your own annotations
              and highlights from books you own. Users are responsible for ensuring their
              use of extracted content complies with applicable copyright laws.
            </p>
            <p>
              The app is intended to support fair use activities such as personal study,
              research, and commentary. We do not encourage or support copying entire
              works or commercial redistribution of copyrighted content.
            </p>
          </section>

          <section className="mt-8">
            <h2>Subscriptions and Payments</h2>
            <p>
              BookQuotes offers both free and premium subscription tiers. Premium
              subscriptions are billed through the Apple App Store and are subject to
              Apple&apos;s payment terms.
            </p>
            <ul>
              <li>Subscriptions automatically renew unless cancelled</li>
              <li>You can cancel anytime through your App Store settings</li>
              <li>Refunds are handled according to Apple&apos;s refund policy</li>
            </ul>
          </section>

          <section className="mt-8">
            <h2>Service Availability</h2>
            <p>
              We strive to maintain consistent service availability, but cannot guarantee
              uninterrupted access. The AI extraction service requires an internet
              connection. We may modify or discontinue features with reasonable notice.
            </p>
          </section>

          <section className="mt-8">
            <h2>Limitation of Liability</h2>
            <p>
              BookQuotes is provided &ldquo;as is&rdquo; without warranties of any kind.
              We are not liable for any damages arising from your use of the app,
              including but not limited to data loss, service interruptions, or
              extraction errors.
            </p>
          </section>

          <section className="mt-8">
            <h2>Changes to Terms</h2>
            <p>
              We may update these terms from time to time. Continued use of the app
              after changes constitutes acceptance of the new terms.
            </p>
          </section>

          <section className="mt-8">
            <h2>Contact</h2>
            <p>
              Questions about these terms? Email us at{' '}
              <a href="mailto:legal@bookquotes.app" className="text-gold-primary">
                legal@bookquotes.app
              </a>
            </p>
          </section>
        </article>
      </main>
      <Footer />
    </>
  )
}
