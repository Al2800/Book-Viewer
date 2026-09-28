'use client'

import { useMemo, useState } from 'react'
import { staveLabels, type QuoteEntry } from '@/lib/quotes'

type QuoteBankProps = {
  quotes: QuoteEntry[]
  mode?: 'stave' | 'theme'
  themeOrder?: string[]
  themeHeadings?: Record<string, string>
}

function FilterRow({
  label,
  value,
  options,
  onChange,
}: {
  label: string
  value: string
  options: { value: string; label: string }[]
  onChange: (value: string) => void
}) {
  return (
    <div className="mb-4">
      <p className="font-ui text-xs uppercase tracking-[0.08em] text-ink-medium mb-2">{label}</p>
      <div className="flex flex-wrap gap-2">
        {options.map((option) => {
          const selected = option.value === value
          return (
            <button
              key={option.value || 'all'}
              type="button"
              aria-pressed={selected}
              onClick={() => onChange(option.value)}
              className={`font-ui text-sm px-3 py-1.5 border ${
                selected
                  ? 'border-ink-black bg-ink-black text-paper-cream'
                  : 'border-subtle bg-paper-cream text-ink-dark hover:border-ink-black'
              }`}
            >
              {option.label}
            </button>
          )
        })}
      </div>
    </div>
  )
}

function QuoteArticle({
  quote,
  onTheme,
  meta,
}: {
  quote: QuoteEntry
  onTheme: (theme: string) => void
  meta: string
}) {
  return (
    <article key={quote.id} id={quote.id} className="border-t border-subtle pt-6">
      <blockquote className="font-body text-xl md:text-2xl text-ink-black leading-snug mb-4 whitespace-pre-line">
        {quote.text}
      </blockquote>
      <p className="font-ui text-sm text-ink-medium mb-4">{meta}</p>
      {quote.sourceUrl && (
        <p className="font-ui text-sm text-ink-medium mb-4">
          <a href={quote.sourceUrl} className="underline underline-offset-4" rel="noopener noreferrer">
            {quote.sourceName ?? 'Source'}
          </a>
        </p>
      )}
      <p className="text-lg text-ink-dark mb-3">{quote.context}</p>
      <p className="text-lg text-ink-dark mb-4">{quote.analysis}</p>
      <ul className="flex flex-wrap gap-2">
        {quote.themes.map((item) => (
          <li key={item}>
            <button
              type="button"
              onClick={() => onTheme(item)}
              className="font-ui text-xs uppercase tracking-wide border border-subtle px-2 py-1 text-ink-medium hover:border-ink-black"
            >
              {item}
            </button>
          </li>
        ))}
      </ul>
    </article>
  )
}

export function QuoteBank({ quotes, mode = 'stave', themeOrder, themeHeadings }: QuoteBankProps) {
  const [stave, setStave] = useState('')
  const [speaker, setSpeaker] = useState('')
  const [theme, setTheme] = useState('')

  const speakers = useMemo(
    () => [...new Set(quotes.map((quote) => quote.speaker))].sort((a, b) => a.localeCompare(b, 'en-GB')),
    [quotes],
  )
  const themes = useMemo(
    () => [...new Set(quotes.flatMap((quote) => quote.themes))].sort((a, b) => a.localeCompare(b, 'en-GB')),
    [quotes],
  )

  const visible = quotes.filter((quote) => {
    if (mode === 'stave' && stave && String(quote.stave) !== stave) return false
    if (speaker && quote.speaker !== speaker) return false
    if (theme && !quote.themes.includes(theme)) return false
    return true
  })

  const staves = [1, 2, 3, 4, 5]
  const themeGroups = themeOrder ?? [...new Set(quotes.map((quote) => quote.themes[0]).filter(Boolean))]

  return (
    <div>
      {mode === 'stave' && (
        <FilterRow
          label="Stave"
          value={stave}
          onChange={setStave}
          options={[{ value: '', label: 'All staves' }, ...staves.map((number) => ({ value: String(number), label: `Stave ${number}` }))]}
        />
      )}
      <FilterRow
        label={mode === 'stave' ? 'Character' : 'Author'}
        value={speaker}
        onChange={setSpeaker}
        options={[
          { value: '', label: mode === 'stave' ? 'All characters' : 'All authors' },
          ...speakers.map((name) => ({ value: name, label: name })),
        ]}
      />
      <FilterRow
        label="Theme"
        value={theme}
        onChange={setTheme}
        options={[{ value: '', label: 'All themes' }, ...themes.map((name) => ({ value: name, label: name }))]}
      />
      <p className="font-ui text-sm text-ink-medium mb-8">
        Showing {visible.length} of {quotes.length}
      </p>

      {visible.length === 0 && (
        <p className="text-lg text-ink-dark">
          {mode === 'stave'
            ? 'No quote matches those three filters. Clear one of them.'
            : 'No quote matches those filters. Clear one of them.'}
        </p>
      )}

      {mode === 'stave' &&
        staves.map((number) => {
          const group = visible.filter((quote) => quote.stave === number)
          if (group.length === 0) return null
          return (
            <section key={number} id={`stave-${number}`} className="mb-14">
              <h2 className="mb-6">{staveLabels[number]}</h2>
              <div className="space-y-10">
                {group.map((quote) => (
                  <QuoteArticle
                    key={quote.id}
                    quote={quote}
                    onTheme={setTheme}
                    meta={`Stave ${quote.stave} · ${quote.speaker}`}
                  />
                ))}
              </div>
            </section>
          )
        })}

      {mode === 'theme' &&
        themeGroups.map((name) => {
          const group = visible.filter((quote) => quote.themes[0] === name)
          if (group.length === 0) return null
          return (
            <section key={name} id={`theme-${name.toLowerCase().replace(/\s+/g, '-')}`} className="mb-14">
              <h2 className="mb-6">{themeHeadings?.[name] ?? name}</h2>
              <div className="space-y-10">
                {group.map((quote) => (
                  <QuoteArticle
                    key={quote.id}
                    quote={quote}
                    onTheme={setTheme}
                    meta={quote.citation ?? quote.speaker}
                  />
                ))}
              </div>
            </section>
          )
        })}
    </div>
  )
}
