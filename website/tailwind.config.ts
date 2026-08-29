import type { Config } from 'tailwindcss'

const config: Config = {
  content: [
    './app/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        paper: {
          cream: 'var(--color-paper)',
          warm: 'var(--color-paper-2)',
          aged: 'var(--color-paper-3)',
        },
        ink: {
          black: 'var(--color-ink)',
          dark: 'var(--color-ink-2)',
          medium: 'var(--color-ink-3)',
          light: 'var(--color-ink-4)',
        },
        gold: {
          primary: 'var(--color-accent)',
          light: 'var(--color-accent-2)',
          muted: 'var(--color-paper-3)',
        },
        sage: 'var(--color-sage)',
        rust: 'var(--color-rust)',
        navy: 'var(--color-navy)',
      },
      fontFamily: {
        display: ['var(--font-display)'],
        body: ['var(--font-body)'],
        ui: ['var(--font-ui)'],
        mono: ['var(--font-mono)'],
      },
      fontSize: {
        '5xl': ['3.5rem', { lineHeight: '1.2' }],
        '4xl': ['2.5rem', { lineHeight: '1.2' }],
      },
      spacing: {
        '18': '4.5rem',
        '22': '5.5rem',
      },
      maxWidth: {
        'prose': '65ch',
      },
      boxShadow: {
        'soft': '0 2px 8px rgba(26, 25, 21, 0.04)',
        'medium': '0 4px 16px rgba(26, 25, 21, 0.08)',
      },
      borderColor: {
        subtle: 'rgba(26, 25, 21, 0.08)',
      },
      animation: {
        'fade-up': 'fadeUp 0.6s ease-out forwards',
        'fade-in': 'fadeIn 0.5s ease-out forwards',
      },
      keyframes: {
        fadeUp: {
          '0%': { opacity: '0', transform: 'translateY(20px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
      },
    },
  },
  plugins: [],
}

export default config
