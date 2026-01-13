import { cn } from '@/lib/utils'

interface DeviceMockupProps {
  children: React.ReactNode
  className?: string
}

export function DeviceMockup({ children, className }: DeviceMockupProps) {
  return (
    <div className={cn('relative mx-auto', className)}>
      {/* iPhone frame */}
      <div className="relative bg-ink-black rounded-[3rem] p-3 shadow-medium">
        {/* Notch */}
        <div className="absolute top-0 left-1/2 -translate-x-1/2 w-1/3 h-7 bg-ink-black rounded-b-2xl z-10" />

        {/* Screen */}
        <div className="relative bg-paper-cream rounded-[2.5rem] overflow-hidden aspect-[9/19.5]">
          {children}
        </div>

        {/* Home indicator */}
        <div className="absolute bottom-2 left-1/2 -translate-x-1/2 w-1/3 h-1 bg-ink-medium rounded-full" />
      </div>
    </div>
  )
}
