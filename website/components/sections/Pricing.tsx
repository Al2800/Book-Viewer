'use client'

import { AnimatedSection, StaggeredContainer, StaggeredItem } from '@/components/ui/AnimatedSection'
import { Button } from '@/components/ui/Button'
import { Check, Shield, Sparkles } from 'lucide-react'

const plans = [
  {
    name: 'Free',
    description: 'Perfect for getting started',
    price: '$0',
    period: 'forever',
    features: [
      '10 extractions per month',
      'Unlimited books',
      'Basic search',
      'Markdown export',
    ],
    cta: 'Get Started',
    variant: 'secondary' as const,
    popular: false,
  },
  {
    name: 'Premium',
    description: 'For serious readers',
    price: '$4.99',
    period: '/month',
    features: [
      'Unlimited extractions',
      'Batch capture mode',
      'Advanced search with filters',
      'Obsidian & Notion export',
      'Offline capture queue',
      'Priority processing',
    ],
    cta: 'Start Free Trial',
    variant: 'primary' as const,
    popular: true,
  },
]

export function Pricing() {
  return (
    <section id="pricing" className="section-padding bg-paper-warm">
      <div className="container-standard">
        <AnimatedSection className="text-center mb-12">
          <h2 className="mb-4">Start Capturing Your Insights</h2>
          <p className="text-ink-medium text-lg max-w-prose mx-auto">
            Choose the plan that fits your reading habits
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
                  <div className="absolute -top-3 left-1/2 -translate-x-1/2 bg-gold-primary text-paper-cream px-4 py-1 rounded-full font-ui text-xs font-medium flex items-center gap-1">
                    <Sparkles className="w-3 h-3" />
                    Most Popular
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
                  href="https://apps.apple.com/app/bookquotes"
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
              Privacy-first. Your data stays on your device.
            </span>
          </div>
        </AnimatedSection>
      </div>
    </section>
  )
}
