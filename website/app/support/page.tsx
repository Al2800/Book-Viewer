import { Header } from '@/components/layout/Header'
import { Footer } from '@/components/layout/Footer'
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'Support — BookQuotes',
  description: 'Help, contact information, and troubleshooting guidance for BookQuotes.',
}

const supportTopics = [
  {
    title: 'Sign in with Apple',
    body: 'If sign-in fails, make sure the device is online and that Apple ID sign-in is available. Closing and reopening the app will usually reset the authorization sheet cleanly.',
  },
  {
    title: 'AI extraction issues',
    body: 'Extraction quality depends on image clarity, lighting, and how clearly the page is marked. Retake the page with stronger contrast and less glare if the text looks incomplete.',
  },
  {
    title: 'Library and storage',
    body: 'In this v1 release, books and quotes are stored locally on your device. Use exports regularly if you want a manual backup outside the app.',
  },
  {
    title: 'Trials and billing',
    body: 'BookQuotes uses auto-renewable monthly and yearly subscriptions. Eligible new subscribers start with a 7-day free trial, and billing continues automatically unless cancelled in App Store settings before renewal.',
  },
]

export default function SupportPage() {
  return (
    <>
      <Header />
      <main className="pt-24 pb-16">
        <article className="container-narrow prose prose-ink max-w-none">
          <h1 className="font-display">Support</h1>
          <p className="text-ink-medium text-lg">Last updated: March 2026</p>

          <section className="mt-12">
            <h2>Contact</h2>
            <p>
              For help with BookQuotes, email{' '}
              <a href="mailto:acampbell193@googlemail.com" className="text-gold-primary">
                acampbell193@googlemail.com
              </a>.
            </p>
            <p>
              Include your device model, iOS version, the app version you are using, and a
              short description of what happened. That is enough to reproduce most issues.
            </p>
          </section>

          <section className="mt-8">
            <h2>Before You Email</h2>
            <ul>
              <li>Restart the app and retry the action once</li>
              <li>Check that the device has a stable internet connection for AI extraction</li>
              <li>Confirm you are running the latest TestFlight or App Store build</li>
              <li>Export your library if you want an immediate manual backup</li>
            </ul>
          </section>

          <section className="mt-8">
            <h2>Common Topics</h2>
            {supportTopics.map((topic) => (
              <div key={topic.title} className="mt-6">
                <h3>{topic.title}</h3>
                <p>{topic.body}</p>
              </div>
            ))}
          </section>

          <section className="mt-8">
            <h2>Policies</h2>
            <p>
              BookQuotes support is governed by our <a href="/privacy" className="text-gold-primary">Privacy Policy</a>{' '}
              and <a href="/terms" className="text-gold-primary">Terms of Service</a>.
            </p>
          </section>
        </article>
      </main>
      <Footer />
    </>
  )
}
