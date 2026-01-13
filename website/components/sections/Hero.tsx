'use client'

import { motion } from 'framer-motion'
import { ArrowDown } from 'lucide-react'
import { Button } from '@/components/ui/Button'
import { DeviceMockup } from '@/components/ui/DeviceMockup'

export function Hero() {
  return (
    <section className="relative min-h-screen flex items-center pt-20 pb-16 overflow-hidden paper-texture">
      <div className="container-wide">
        <div className="grid lg:grid-cols-2 gap-12 lg:gap-16 items-center">
          {/* Content */}
          <div className="text-center lg:text-left">
            <motion.h1
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6 }}
              className="text-balance mb-6"
            >
              Your Paper Highlights,{' '}
              <span className="text-gradient">Digitized Beautifully</span>
            </motion.h1>

            <motion.p
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, delay: 0.1 }}
              className="text-lg md:text-xl text-ink-dark max-w-prose mx-auto lg:mx-0 mb-8"
            >
              Transform underlined passages and margin notes from physical books
              into a searchable digital library. Powered by AI.
            </motion.p>

            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, delay: 0.2 }}
              className="flex flex-col sm:flex-row gap-4 justify-center lg:justify-start"
            >
              <a
                href="https://apps.apple.com/app/bookquotes"
                target="_blank"
                rel="noopener noreferrer"
              >
                <Button size="lg" className="w-full sm:w-auto">
                  <svg className="w-5 h-5 mr-2" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>
                  </svg>
                  Download on App Store
                </Button>
              </a>
              <a href="#how-it-works">
                <Button variant="secondary" size="lg" className="w-full sm:w-auto">
                  See How It Works
                  <ArrowDown className="w-4 h-4 ml-2" />
                </Button>
              </a>
            </motion.div>
          </div>

          {/* Device Mockup */}
          <motion.div
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ duration: 0.8, delay: 0.3 }}
            className="relative"
          >
            <DeviceMockup className="w-64 md:w-72 lg:w-80">
              {/* Placeholder app screen */}
              <div className="w-full h-full bg-paper-cream p-4 flex flex-col">
                {/* App header mockup */}
                <div className="flex items-center justify-between mb-4 pt-8">
                  <span className="font-display text-lg font-semibold text-ink-black">Library</span>
                  <div className="w-8 h-8 bg-gold-primary/10 rounded-full" />
                </div>

                {/* Book grid mockup */}
                <div className="grid grid-cols-2 gap-3 flex-1">
                  {[1, 2, 3, 4].map((i) => (
                    <div
                      key={i}
                      className="bg-paper-aged rounded-lg aspect-[2/3] flex items-end p-2"
                    >
                      <div className="w-full">
                        <div className="h-2 bg-ink-light/30 rounded mb-1" />
                        <div className="h-1.5 bg-ink-light/20 rounded w-2/3" />
                      </div>
                    </div>
                  ))}
                </div>

                {/* Tab bar mockup */}
                <div className="flex justify-around py-3 mt-4 border-t border-subtle">
                  {[1, 2, 3, 4].map((i) => (
                    <div
                      key={i}
                      className={`w-6 h-6 rounded-full ${i === 1 ? 'bg-gold-primary' : 'bg-ink-light/30'}`}
                    />
                  ))}
                </div>
              </div>
            </DeviceMockup>

            {/* Decorative elements */}
            <div className="absolute -z-10 top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-96 h-96 bg-gold-muted/20 rounded-full blur-3xl" />
          </motion.div>
        </div>
      </div>
    </section>
  )
}
