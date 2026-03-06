'use client'

import { AnimatedSection, StaggeredContainer, StaggeredItem } from '@/components/ui/AnimatedSection'
import { Button } from '@/components/ui/Button'
import { Check, Shield } from 'lucide-react'

const plans = [
  {
    name: 'Monthly',
    description: 'Flexible access for regular readers',
    price: '$4.99',
    period: '/month',
    features: [
      '7-day free trial for eligible new subscribers',
      'AI-powered cover and quote extraction',
      'Batch capture, search, tags, and collections',
      'Markdown, plain text, JSON, Notion, and Obsidian export',
    ],
    cta: 'Start 7-Day Trial',
    variant: 'secondary' as const,
    popular: false,
  },
  {
    name: 'Yearly',
    description: 'Best value for committed readers',
    price: '$39.99',
    period: '/year',
    features: [
      '7-day free trial for eligible new subscribers',
      'Everything in Monthly',
      'Lower effective monthly cost',
      'Save 33% compared with monthly billing',
    ],
    cta: 'Start 7-Day Trial',
    variant: 'primary' as const,
    popular: true,
  },
]

export function Pricing() {
  return (
    <section id="access" className="section-padding bg-paper-warm">
      <div className="container-standard">
        <AnimatedSection className="text-center mb-12">
          <h2 className="mb-4">Choose Your Plan</h2>
          <p className="text-ink-medium text-lg max-w-prose mx-auto">
            Start with a 7-day trial, then continue on a monthly or yearly auto-renewable plan.
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
                    Best Value
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
                  href="https://apps.apple.com/app/id6758091579"
                  target="_blank"
                  rel="noopener noreferrer"
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
