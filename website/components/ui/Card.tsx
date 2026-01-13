import { cn } from '@/lib/utils'

interface CardProps {
  children: React.ReactNode
  className?: string
}

export function Card({ children, className }: CardProps) {
  return (
    <div className={cn('bg-paper-aged rounded-xl p-6 shadow-soft', className)}>
      {children}
    </div>
  )
}
