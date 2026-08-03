'use client'

import { AnimatedSection } from '@/components/ui/AnimatedSection'
import { BookX, Sparkles, ArrowRight } from 'lucide-react'

export function Problem() {
  return (
    <section className="section-padding bg-paper-warm">
      <div className="container-standard">
        <AnimatedSection>
          <div className="text-center mb-12">
            <h2 className="mb-4">The Reading Dilemma</h2>
            <p className="text-ink-medium text-lg max-w-prose mx-auto">
              You underline sentences. You draw margin lines. You scribble notes.
              But what happens to those insights?
            </p>
          </div>
        </AnimatedSection>

        <div className="grid md:grid-cols-2 gap-8 items-stretch">
          {/* Problem */}
          <AnimatedSection delay={0.1}>
            <div className="bg-paper-cream rounded-2xl p-8 h-full border border-subtle">
              <div className="flex items-center gap-3 mb-6">
                <div className="p-3 bg-rust/10 rounded-xl">
                  <BookX className="w-6 h-6 text-rust" />
                </div>
                <h3 className="text-xl font-semibold">The Problem</h3>
              </div>
              <ul className="space-y-4 text-ink-dark">
                <li className="flex items-start gap-3">
                  <span className="text-rust mt-1">-</span>
                  <span>Your highlights are trapped in physical books</span>
                </li>
                <li className="flex items-start gap-3">
                  <span className="text-rust mt-1">-</span>
                  <span>Margin notes fade and become illegible</span>
                </li>
                <li className="flex items-start gap-3">
                  <span className="text-rust mt-1">-</span>
                  <span>Can&apos;t search across your reading history</span>
                </li>
                <li className="flex items-start gap-3">
                  <span className="text-rust mt-1">-</span>
                  <span>Manual transcription takes forever</span>
                </li>
              </ul>
            </div>
          </AnimatedSection>

          {/* Solution */}
          <AnimatedSection delay={0.2}>
            <div className="bg-paper-cream rounded-2xl p-8 h-full border border-gold-muted">
              <div className="flex items-center gap-3 mb-6">
                <div className="p-3 bg-gold-primary/10 rounded-xl">
                  <Sparkles className="w-6 h-6 text-gold-primary" />
                </div>
                <h3 className="text-xl font-semibold">The Solution</h3>
              </div>
              <ul className="space-y-4 text-ink-dark">
                <li className="flex items-start gap-3">
                  <span className="text-gold-primary mt-1">+</span>
                  <span>Snap a photo of your marked page</span>
                </li>
                <li className="flex items-start gap-3">
                  <span className="text-gold-primary mt-1">+</span>
                  <span>Extract the marked passage, then review it before saving</span>
                </li>
                <li className="flex items-start gap-3">
                  <span className="text-gold-primary mt-1">+</span>
                  <span>Full-text search across your entire library</span>
                </li>
                <li className="flex items-start gap-3">
                  <span className="text-gold-primary mt-1">+</span>
                  <span>Export to Obsidian, Notion, or Markdown</span>
                </li>
              </ul>
            </div>
          </AnimatedSection>
        </div>

        {/* Transition arrow */}
        <AnimatedSection delay={0.3} className="flex justify-center mt-8">
          <div className="flex items-center gap-2 text-ink-medium">
            <span className="font-ui text-sm">From trapped to liberated</span>
            <ArrowRight className="w-4 h-4" />
          </div>
        </AnimatedSection>
      </div>
    </section>
  )
}
