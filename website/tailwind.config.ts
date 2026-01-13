import type { Config } from 'tailwindcss'

const config: Config = {
  content: [
    './app/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        // Primary - Warm Paper Tones
        paper: {
          cream: '#FDFBF7',
          warm: '#F8F5EF',
          aged: '#EDE8DE',
        },
        // Text - Rich Book Ink
        ink: {
          black: '#1A1915',
          dark: '#3D3A33',
          medium: '#6B665A',
          light: '#9C9687',
        },
        // Accent - Library Gold
        gold: {
          primary: '#B8860B',
          light: '#D4A84B',
          muted: '#C9B896',
        },
        // Supporting
        sage: '#7A8B6F',
        rust: '#A65D57',
        navy: '#2C3E50',
      },
      fontFamily: {
        display: ['Playfair Display', 'Crimson Pro', 'Georgia', 'serif'],
        body: ['Source Serif Pro', 'Crimson Text', 'Georgia', 'serif'],
        ui: ['Inter', 'SF Pro Text', '-apple-system', 'sans-serif'],
        mono: ['JetBrains Mono', 'SF Mono', 'monospace'],
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
