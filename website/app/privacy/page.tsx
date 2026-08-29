import { Header } from '@/components/layout/Header'
import { Footer } from '@/components/layout/Footer'
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'Privacy Policy — BookQuotes',
  description: 'How BookQuotes handles your data with privacy-first principles.',
  alternates: { canonical: '/privacy' },
}

export default function PrivacyPage() {
  return (
    <>
      <Header />
      <main className="pt-8 md:pt-12 pb-16">
        <article className="container-narrow prose prose-ink max-w-none">
          <h1 className="font-display">Privacy Policy</h1>
          <p className="text-ink-medium text-lg">Last updated: July 2026</p>

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
              and (optionally) your email address. We use this to authenticate requests
              to the BookQuotes service and maintain your subscription access state.
            </p>

            <h3>Image Processing</h3>
            <p>
              Captured pages and downloaded catalogue cover images are stored locally on your
              device while you review, retry, or save them. When you save a quote, a compressed
              source-image copy may be kept with that quote for reference until you delete the
              quote. Draft and queued images remain on-device until they are processed or deleted.
            </p>
            <p>
              If you enable Remote AI Processing, the marked-page image, extraction instructions,
              and resulting text are sent through the BookQuotes service and the Hugging Face
              Inference Providers router to the pinned Featherless AI inference provider. The
              BookQuotes service does not write those image or prompt payloads to its application
              database; these providers handle request data under their own terms.
            </p>

            <h3>Book Metadata Lookup</h3>
            <p>
              When you scan a book, BookQuotes sends its ISBN directly to Google Books to find
              metadata and a canonical cover image. If the ISBN is not found there, it is sent to
              Open Library as a fallback. These catalogue requests do not include your BookQuotes
              account identifier or library.
            </p>

            <h3>Service Usage and Subscription Records</h3>
            <p>
              To authenticate requests and enforce subscription access, BookQuotes stores your
              Apple-provided account identifier, subscription access records, monthly extraction
              counts, and last-updated timestamps. Short-lived rate-limit counters may use your
              account and network information to protect the service. After account deletion, a
              session-revocation record may remain for up to eight days solely to prevent use of
              already-issued session tokens.
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
              <li>Advertising profiles or behavioral analytics</li>
            </ul>
          </section>

          <section className="mt-8">
            <h2>Third-Party Services</h2>
            <p>
              We use the following third-party services:
            </p>
            <ul>
              <li>
                <strong>Hugging Face Inference</strong> &mdash; For model-assisted quote extraction
                from marked quote pages when you enable Remote AI Processing. Provider handling
                is governed by its applicable terms.
              </li>
              <li>
                <strong>Featherless AI</strong> &mdash; The pinned inference provider that processes
                those consented requests.
              </li>
              <li>
                <strong>Apple Vision</strong> &mdash; For on-device OCR when Remote AI Processing is
                off or you explicitly choose the on-device option.
              </li>
              <li>
                <strong>Google Books</strong> &mdash; For requested ISBN metadata lookups and cover
                images. BookQuotes does not include your account identifier or library in these
                catalogue requests.
              </li>
              <li>
                <strong>Open Library</strong> &mdash; As an ISBN metadata fallback when Google Books
                has no match. BookQuotes does not include your account identifier or library in
                these catalogue requests.
              </li>
              <li>
                <strong>Apple Sign-In</strong> &mdash; For secure authentication without
                passwords.
              </li>
              <li>
                <strong>Apple StoreKit</strong> &mdash; For subscription billing, trial
                eligibility, renewal status, and purchase management.
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
              You can delete your BookQuotes account from Settings → Account → Delete Account.
              That removes subscription access records and usage data from BookQuotes servers;
              a session-revocation record remains for up to eight days to block existing tokens.
              Your on-device library remains unless you delete it yourself. App Store subscriptions
              are billed by Apple and must be cancelled in Apple subscription management. Removing
              the app from your device also deletes local library data.
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
