'use client'

import { AnimatedSection, StaggeredContainer, StaggeredItem } from '@/components/ui/AnimatedSection'
import { Button } from '@/components/ui/Button'
import { Check, Shield } from 'lucide-react'

const plans = [
  {
    name: 'Included in v1',
    description: 'Everything needed for the launch build',
    price: '$0',
    period: 'for now',
    features: [
      'Sign in with Apple for secure access',
      'AI-powered cover and quote extraction',
      'Batch capture, search, tags, and collections',
      'Markdown, plain text, JSON, Notion, and Obsidian export',
    ],
    cta: 'View App Store Listing',
    variant: 'primary' as const,
    popular: true,
  },
  {
    name: 'Future plans',
    description: 'Optional pricing may be introduced later',
    price: 'TBD',
    period: '',
    features: [
      'No paid subscription is required in this release',
      'Any future pricing will appear first in App Store Connect',
      'Launch users should expect the core app experience to remain available',
      'Policy changes will be reflected in the app and legal pages',
    ],
    cta: 'Read Support Notes',
    variant: 'secondary' as const,
    popular: false,
  },
]

export function Pricing() {
  return (
    <section id="access" className="section-padding bg-paper-warm">
      <div className="container-standard">
        <AnimatedSection className="text-center mb-12">
          <h2 className="mb-4">Access in the Launch Build</h2>
          <p className="text-ink-medium text-lg max-w-prose mx-auto">
            BookQuotes v1 ships without paid in-app purchases while the first App Store release settles.
          </p>
        </AnimatedSection>

        <StaggeredContainer className="grid md:grid-cols-2 gap-8 max-w-4xl mx-auto">
          {plans.map((plan) => (
            <StaggeredItem key={plan.name}>
              <div
                className={`relative bg-paper-cream rounded-2xl p-8 h-full flex flex-col ${
                  plan.popular ? 'ring-2 ring-gold-primary shadow-medium' : 'border border-subtle'
                }`}
              >
                {/* Popular badge */}
                {plan.popular && (
                  <div className="absolute -top-3 left-1/2 -translate-x-1/2 bg-gold-primary text-paper-cream px-4 py-1 rounded-full font-ui text-xs font-medium">
                    Current Release
                  </div>
                )}

                {/* Header */}
                <div className="text-center mb-6">
                  <h3 className="text-2xl font-semibold mb-1">{plan.name}</h3>
                  <p className="text-ink-medium text-sm">{plan.description}</p>
                </div>

                {/* Price */}
                <div className="text-center mb-8">
                  <span className="font-display text-4xl font-bold text-ink-black">{plan.price}</span>
                  <span className="text-ink-medium font-ui">{plan.period}</span>
                </div>

                {/* Features */}
                <ul className="space-y-3 mb-8 flex-1">
                  {plan.features.map((feature) => (
                    <li key={feature} className="flex items-start gap-3">
                      <Check className="w-5 h-5 text-sage flex-shrink-0 mt-0.5" />
                      <span className="text-ink-dark font-ui text-sm">{feature}</span>
                    </li>
                  ))}
                </ul>

                {/* CTA */}
                <a
                  href={plan.name === 'Included in v1' ? 'https://apps.apple.com/app/id6758091579' : '/support'}
                  target={plan.name === 'Included in v1' ? '_blank' : undefined}
                  rel={plan.name === 'Included in v1' ? 'noopener noreferrer' : undefined}
                >
                  <Button variant={plan.variant} className="w-full">
                    {plan.cta}
                  </Button>
                </a>
              </div>
            </StaggeredItem>
          ))}
        </StaggeredContainer>

        {/* Trust badges */}
        <AnimatedSection delay={0.3} className="mt-12 text-center">
          <div className="inline-flex items-center gap-2 bg-paper-aged px-6 py-3 rounded-full">
            <Shield className="w-5 h-5 text-sage" />
            <span className="text-ink-medium font-ui text-sm">
              Privacy-first. Your library stays on your device in this release.
            </span>
          </div>
        </AnimatedSection>
      </div>
    </section>
  )
}
