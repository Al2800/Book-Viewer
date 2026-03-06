import { Header } from '@/components/layout/Header'
import { Footer } from '@/components/layout/Footer'
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'Privacy Policy — BookQuotes',
  description: 'How BookQuotes handles your data with privacy-first principles.',
}

export default function PrivacyPage() {
  return (
    <>
      <Header />
      <main className="pt-24 pb-16">
        <article className="container-narrow prose prose-ink max-w-none">
          <h1 className="font-display">Privacy Policy</h1>
          <p className="text-ink-medium text-lg">Last updated: March 2026</p>

          <section className="mt-12">
            <h2>Our Commitment</h2>
            <p>
              BookQuotes is built with privacy as a core principle. We believe your reading
              insights are personal, and we have designed our app to keep them that way.
            </p>
          </section>

          <section className="mt-8">
            <h2>What We Collect</h2>

            <h3>Account Information</h3>
            <p>
              When you sign in with Apple, we receive only your Apple-provided identifier
              and (optionally) your email address. We use this solely to authenticate
              requests to the BookQuotes service.
            </p>

            <h3>Image Processing</h3>
            <p>
              When you capture a book page, the image is sent to our proxy server and then
              to Google Gemini for AI processing. <strong>Images are not stored</strong>{' '}
              after processing is complete. They exist only in memory during the extraction
              process.
            </p>

            <h3>Your Quotes and Books</h3>
            <p>
              Your extracted quotes, book metadata, and library organization are stored
              <strong> locally on your device</strong>. Cloud sync is not enabled in this
              v1 release.
            </p>
          </section>

          <section className="mt-8">
            <h2>What We Do NOT Collect</h2>
            <ul>
              <li>Analytics or tracking data</li>
              <li>Advertising identifiers</li>
              <li>Location information</li>
              <li>Contact lists or personal files</li>
              <li>Usage patterns or behavioral data</li>
            </ul>
          </section>

          <section className="mt-8">
            <h2>Third-Party Services</h2>
            <p>
              We use the following third-party services:
            </p>
            <ul>
              <li>
                <strong>Google Gemini API</strong> &mdash; For AI-powered text extraction
                from images. Images are processed according to Google&apos;s privacy policy
                and are not retained after processing.
              </li>
              <li>
                <strong>Apple Sign-In</strong> &mdash; For secure authentication without
                passwords.
              </li>
            </ul>
          </section>

          <section className="mt-8">
            <h2>Data Security</h2>
            <p>
              All network communications use TLS encryption. Your local data is protected
              by iOS device encryption. We do not have access to your device-stored data.
            </p>
          </section>

          <section className="mt-8">
            <h2>Your Rights</h2>
            <p>
              You can delete all your data at any time by removing the app from your device.
              Since we do not store your quotes or books on our servers, deletion is
              immediate and complete.
            </p>
          </section>

          <section className="mt-8">
            <h2>Contact</h2>
            <p>
              Questions about privacy? Email us at{' '}
              <a href="mailto:acampbell193@googlemail.com" className="text-gold-primary">
                acampbell193@googlemail.com
              </a>
            </p>
          </section>
        </article>
      </main>
      <Footer />
    </>
  )
}
