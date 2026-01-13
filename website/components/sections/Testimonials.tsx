'use client'

import { AnimatedSection, StaggeredContainer, StaggeredItem } from '@/components/ui/AnimatedSection'
import { Star, Quote } from 'lucide-react'

const testimonials = [
  {
    quote: "Finally, my margin notes have a home outside the book. This is exactly what I've been looking for.",
    author: "Sarah M.",
    role: "Literature Professor",
    rating: 5,
  },
  {
    quote: "I've tried manual transcription for years. BookQuotes does in seconds what used to take me hours.",
    author: "James K.",
    role: "Avid Reader",
    rating: 5,
  },
  {
    quote: "The batch capture mode is a game-changer. I processed an entire book's worth of highlights in one sitting.",
    author: "Emily R.",
    role: "Book Club Organizer",
    rating: 5,
  },
  {
    quote: "Clean, elegant, and it actually works. The AI extraction is surprisingly accurate.",
    author: "Michael T.",
    role: "Software Engineer",
    rating: 5,
  },
]

function StarRating({ rating }: { rating: number }) {
  return (
    <div className="flex gap-0.5">
      {[...Array(5)].map((_, i) => (
        <Star
          key={i}
          className={`w-4 h-4 ${i < rating ? 'fill-gold-primary text-gold-primary' : 'text-ink-light'}`}
        />
      ))}
    </div>
  )
}

export function Testimonials() {
  return (
    <section className="section-padding">
      <div className="container-wide">
        {/* Featured Quote */}
        <AnimatedSection className="text-center mb-16">
          <Quote className="w-12 h-12 text-gold-muted mx-auto mb-6 rotate-180" />
          <blockquote className="font-display text-2xl md:text-3xl text-ink-black italic max-w-3xl mx-auto mb-6">
            &ldquo;Finally, my margin notes have a home outside the book.&rdquo;
          </blockquote>
          <p className="text-ink-medium font-ui">A Happy Reader</p>
        </AnimatedSection>

        {/* Testimonial Grid */}
        <StaggeredContainer className="grid md:grid-cols-2 lg:grid-cols-4 gap-6">
          {testimonials.map((testimonial) => (
            <StaggeredItem key={testimonial.author}>
              <div className="bg-paper-aged rounded-xl p-6 h-full flex flex-col">
                <StarRating rating={testimonial.rating} />
                <p className="text-ink-dark mt-4 flex-1 text-sm leading-relaxed">
                  &ldquo;{testimonial.quote}&rdquo;
                </p>
                <div className="mt-4 pt-4 border-t border-subtle">
                  <p className="font-ui font-medium text-ink-black text-sm">{testimonial.author}</p>
                  <p className="font-ui text-ink-light text-xs">{testimonial.role}</p>
                </div>
              </div>
            </StaggeredItem>
          ))}
        </StaggeredContainer>
      </div>
    </section>
  )
}
