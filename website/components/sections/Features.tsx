'use client'

import { AnimatedSection } from '@/components/ui/AnimatedSection'
import { DeviceMockup } from '@/components/ui/DeviceMockup'
import {
  Layers,
  Search,
  Pencil,
  WifiOff,
  FileOutput,
  BarChart3,
} from 'lucide-react'

const features = [
  {
    icon: Layers,
    title: 'Capture a Reading Session',
    description: 'Photograph marked pages in a session and keep them together while you review the passages worth saving.',
    mockupContent: (
      <div className="w-full h-full bg-paper-cream p-3 flex flex-col pt-10">
        <div className="text-center mb-4">
          <span className="font-ui text-xs text-ink-medium">Batch Capture</span>
          <div className="font-display text-2xl font-bold text-ink-black">12</div>
          <span className="font-ui text-xs text-ink-light">pages captured</span>
        </div>
        <div className="grid grid-cols-3 gap-1.5 flex-1">
          {[...Array(12)].map((_, i) => (
            <div key={i} className="bg-paper-aged rounded aspect-[3/4] relative">
              {i < 8 && (
                <div className="absolute inset-0 flex items-center justify-center">
                  <div className="w-4 h-4 bg-sage rounded-full flex items-center justify-center">
                    <span className="text-paper-cream text-[8px]">-</span>
                  </div>
                </div>
              )}
            </div>
          ))}
        </div>
      </div>
    ),
  },
  {
    icon: Search,
    title: 'Search Your Book Notes',
    description: 'Search across the text you have saved so a passage can come back when you need it, not only when you remember the page.',
    mockupContent: (
      <div className="w-full h-full bg-paper-cream p-3 flex flex-col pt-10">
        <div className="bg-paper-aged rounded-lg px-3 py-2 mb-4 flex items-center gap-2">
          <Search className="w-3 h-3 text-ink-light" />
          <span className="font-ui text-xs text-ink-medium">atomic</span>
        </div>
        <div className="space-y-2 flex-1">
          {[1, 2, 3].map((i) => (
            <div key={i} className="bg-paper-aged rounded-lg p-2">
              <div className="h-1.5 bg-ink-light/20 rounded w-3/4 mb-1.5" />
              <div className="h-1 bg-gold-primary/30 rounded w-1/2" />
              <div className="h-1 bg-ink-light/10 rounded w-full mt-1" />
            </div>
          ))}
        </div>
      </div>
    ),
  },
  {
    icon: Pencil,
    title: 'Custom Marking Definitions',
    description: 'Define your own annotation vocabulary. Single underline, double underline, margin brackets - you decide what they mean.',
    mockupContent: (
      <div className="w-full h-full bg-paper-cream p-3 flex flex-col pt-10">
        <span className="font-ui text-xs text-ink-medium mb-3">Your Markings</span>
        <div className="space-y-2">
          {[
            { label: 'Single underline', color: 'bg-gold-primary' },
            { label: 'Double underline', color: 'bg-rust' },
            { label: 'Margin line', color: 'bg-sage' },
            { label: 'Highlight', color: 'bg-gold-light' },
          ].map((marking) => (
            <div key={marking.label} className="flex items-center gap-2 bg-paper-aged rounded-lg px-2 py-1.5">
              <div className={`w-3 h-3 ${marking.color} rounded`} />
              <span className="font-ui text-[10px] text-ink-dark">{marking.label}</span>
            </div>
          ))}
        </div>
      </div>
    ),
  },
  {
    icon: WifiOff,
    title: 'Capture Without Interrupting Reading',
    description: 'Keep capture separate from processing. Queue pages when a connection is unavailable and choose how to recover when you are back online.',
    mockupContent: (
      <div className="w-full h-full bg-paper-cream p-3 flex flex-col pt-10">
        <div className="flex items-center justify-center gap-2 mb-4">
          <WifiOff className="w-3 h-3 text-ink-light" />
          <span className="font-ui text-xs text-ink-medium">Offline Mode</span>
        </div>
        <div className="bg-paper-aged rounded-lg p-3 text-center">
          <div className="font-display text-xl font-bold text-ink-black">5</div>
          <span className="font-ui text-[10px] text-ink-light">pages queued</span>
        </div>
        <div className="mt-auto bg-gold-primary/10 rounded-lg p-2 text-center">
          <span className="font-ui text-[10px] text-gold-primary">Ready to process when online</span>
        </div>
      </div>
    ),
  },
  {
    icon: FileOutput,
    title: 'Export Your Library',
    description: 'Take your saved passages into Markdown, plain text, JSON, Notion, or Obsidian when you want to work with them elsewhere.',
    mockupContent: (
      <div className="w-full h-full bg-paper-cream p-3 flex flex-col pt-10">
        <span className="font-ui text-xs text-ink-medium mb-3">Export to</span>
        <div className="space-y-2">
          {['Markdown', 'Obsidian', 'Notion', 'Plain Text'].map((format) => (
            <div key={format} className="flex items-center justify-between bg-paper-aged rounded-lg px-3 py-2">
              <span className="font-ui text-xs text-ink-dark">{format}</span>
              <div className="w-4 h-4 border border-ink-light rounded" />
            </div>
          ))}
        </div>
      </div>
    ),
  },
  {
    icon: BarChart3,
    title: 'Review Before You Trust the Text',
    description: 'Extraction is a first pass. Check the wording, boundaries, page details, and notes before a passage becomes part of your library.',
    mockupContent: (
      <div className="w-full h-full bg-paper-cream p-3 flex flex-col pt-10">
        <span className="font-ui text-xs text-ink-medium mb-3">Extraction Review</span>
        <div className="space-y-2">
          {[
            { confidence: 98, text: 'The power of...' },
            { confidence: 85, text: 'Small changes...' },
            { confidence: 72, text: 'Habits are...' },
          ].map((item, i) => (
            <div key={i} className="bg-paper-aged rounded-lg p-2">
              <div className="flex items-center justify-between mb-1">
                <span className="font-ui text-[10px] text-ink-light">Quote {i + 1}</span>
                <span className={`font-ui text-[10px] ${item.confidence > 90 ? 'text-sage' : item.confidence > 80 ? 'text-gold-primary' : 'text-rust'}`}>
                  {item.confidence}%
                </span>
              </div>
              <div className="h-1 bg-ink-light/10 rounded w-full" />
            </div>
          ))}
        </div>
      </div>
    ),
  },
]

export function Features() {
  return (
    <section id="features" className="section-padding bg-paper-warm">
      <div className="container-wide">
        <div className="text-center mb-16">
          <h2 className="mb-4">Powerful Features for Serious Readers</h2>
          <p className="text-ink-medium text-lg max-w-prose mx-auto">
            Everything you need to capture, organize, and rediscover your reading insights
          </p>
        </div>

        <div className="space-y-24">
          {features.map((feature, index) => (
            <AnimatedSection key={feature.title} delay={index * 0.1}>
              <div className={`grid md:grid-cols-2 gap-12 items-center ${index % 2 === 1 ? 'md:flex-row-reverse' : ''}`}>
                {/* Content */}
                <div className={index % 2 === 1 ? 'md:order-2' : ''}>
                  <div className="flex items-center gap-3 mb-4">
                    <div className="p-3 bg-gold-primary/10 rounded-xl">
                      <feature.icon className="w-6 h-6 text-gold-primary" />
                    </div>
                    <h3 className="text-2xl font-semibold">{feature.title}</h3>
                  </div>
                  <p className="text-lg text-ink-dark leading-relaxed">
                    {feature.description}
                  </p>
                </div>

                {/* Device Mockup */}
                <div className={`flex justify-center ${index % 2 === 1 ? 'md:order-1' : ''}`}>
                  <DeviceMockup className="w-48 md:w-56">
                    {feature.mockupContent}
                  </DeviceMockup>
                </div>
              </div>
            </AnimatedSection>
          ))}
        </div>
      </div>
    </section>
  )
}
