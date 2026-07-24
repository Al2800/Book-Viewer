import { Header } from '@/components/layout/Header'
import { Footer } from '@/components/layout/Footer'
import { Hero } from '@/components/sections/Hero'
import { Problem } from '@/components/sections/Problem'
import { HowItWorks } from '@/components/sections/HowItWorks'
import { Features } from '@/components/sections/Features'
import { JournalPreview } from '@/components/sections/JournalPreview'
import { Pricing } from '@/components/sections/Pricing'

export default function Home() {
  return (
    <>
      <Header />
      <main>
        <Hero />
        <Problem />
        <HowItWorks />
        <Features />
        <JournalPreview />
        <Pricing />
      </main>
      <Footer />
    </>
  )
}
