import { Button } from '@/components/ui/Button'

const plans = [
  {
    name: 'Monthly',
    description: 'Flexible month-to-month access for active readers',
    period: 'Set in App Store for your region',
    badge: 'Flexible',
    features: [
      '7-day free trial included',
      'AI-assisted quote extraction',
      'Batch capture, search, tags, and collections',
      'Full export to Obsidian, Notion, Markdown, and JSON',
      'Cancel anytime in Apple ID settings',
    ],
  },
  {
    name: 'Yearly',
    description: 'Save 33% compared to monthly billing',
    period: 'Billed annually · Best value for committed readers',
    badge: 'Save 33%',
    features: [
      '7-day free trial included',
      'Everything in Monthly',
      'Lowest effective monthly cost',
      'Continuous feature updates and export formats',
      'Cancel anytime in Apple ID settings',
    ],
  },
]

export function Pricing() {
  return (
    <section id="access" className="bg-paper-warm">
      <div className="container-standard section-padding-loose">
        <h2 className="mb-3">Access</h2>
        <p className="text-lg text-ink-medium max-w-prose mb-12">
          Start with a 7-day free trial on either plan. Subscriptions renew automatically
          and can be managed or cancelled at any time through your Apple ID account settings.
        </p>
        <div className="grid md:grid-cols-2 gap-12 md:gap-16">
          {plans.map((plan) => (
            <div key={plan.name} className="border-t border-subtle pt-6">
              <div className="flex items-center justify-between mb-2">
                <h3 className="text-2xl">{plan.name}</h3>
                <span className="font-ui text-xs text-ink-medium border border-subtle px-2 py-0.5 uppercase tracking-wider">
                  {plan.badge}
                </span>
              </div>
              <p className="text-ink-medium mb-2">{plan.description}</p>
              <p className="font-ui text-sm text-ink-dark font-medium mb-6">{plan.period}</p>
              <ul className="space-y-3 mb-8 text-ink-dark">
                {plan.features.map((feature) => (
                  <li key={feature} className="flex items-start gap-2 text-sm">
                    <span className="text-ink-medium select-none">&bull;</span>
                    <span>{feature}</span>
                  </li>
                ))}
              </ul>
              <a
                href="https://apps.apple.com/app/id6758091579"
                target="_blank"
                rel="noopener noreferrer"
              >
                <Button variant={plan.name === 'Yearly' ? 'primary' : 'secondary'}>
                  Start 7-day trial
                </Button>
              </a>
            </div>
          ))}
        </div>
        <p className="mt-12 font-ui text-sm text-ink-medium max-w-prose">
          Privacy-first architecture. Your library is stored locally on your device in this release.
        </p>
      </div>
    </section>
  )
}
