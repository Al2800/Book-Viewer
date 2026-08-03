'use client'

import { StaggeredContainer, StaggeredItem } from '@/components/ui/AnimatedSection'
import { Camera, Wand2, Library, ArrowRight } from 'lucide-react'

const steps = [
  {
    icon: Camera,
    number: '1',
    title: 'Capture',
    description: 'Photograph your marked book pages. Our quality check ensures clear images before processing.',
  },
  {
    icon: Wand2,
    number: '2',
    title: 'Extract',
    description: 'Use the available extraction route, then review and edit the passage before it enters your library.',
  },
  {
    icon: Library,
    number: '3',
    title: 'Organize',
    description: 'Build your searchable quote library. Tag, search, and export your reading insights anytime.',
  },
]

export function HowItWorks() {
  return (
    <section id="how-it-works" className="section-padding">
      <div className="container-wide">
        <div className="text-center mb-16">
          <h2 className="mb-4">How It Works</h2>
          <p className="text-ink-medium text-lg max-w-prose mx-auto">
            Three simple steps from physical page to digital library
          </p>
        </div>

        <StaggeredContainer className="grid md:grid-cols-3 gap-8 relative">
          {steps.map((step, index) => (
            <StaggeredItem key={step.number}>
              <div className="relative">
                {/* Connector line (hidden on mobile, last item) */}
                {index < steps.length - 1 && (
                  <div className="hidden md:block absolute top-12 left-[60%] w-[80%] h-px bg-gradient-to-r from-gold-muted to-transparent" />
                )}

                <div className="bg-paper-aged rounded-2xl p-8 text-center relative">
                  {/* Step number */}
                  <div className="absolute -top-4 left-1/2 -translate-x-1/2 w-8 h-8 bg-gold-primary text-paper-cream rounded-full flex items-center justify-center font-ui font-semibold text-sm">
                    {step.number}
                  </div>

                  {/* Icon */}
                  <div className="w-16 h-16 mx-auto mb-6 bg-paper-cream rounded-2xl flex items-center justify-center shadow-soft">
                    <step.icon className="w-8 h-8 text-gold-primary" />
                  </div>

                  {/* Content */}
                  <h3 className="text-xl font-semibold mb-3">{step.title}</h3>
                  <p className="text-ink-medium">{step.description}</p>
                </div>
              </div>
            </StaggeredItem>
          ))}
        </StaggeredContainer>

        {/* Bottom CTA */}
        <div className="text-center mt-12">
          <a
            href="#features"
            className="inline-flex items-center gap-2 text-gold-primary font-ui font-medium hover:gap-3 transition-all"
          >
            Explore all features
            <ArrowRight className="w-4 h-4" />
          </a>
        </div>
      </div>
    </section>
  )
}
