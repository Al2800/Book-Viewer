import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const bookPath = path.join(root, 'content/sources/pg1260.txt')
const quotesPath = path.join(root, 'content/quotes/jane-eyre.json')

const ROMAN = {
  I: 1,
  II: 2,
  III: 3,
  IV: 4,
  V: 5,
  VI: 6,
  VII: 7,
  VIII: 8,
  IX: 9,
  X: 10,
  XI: 11,
  XII: 12,
  XIII: 13,
  XIV: 14,
  XV: 15,
  XVI: 16,
  XVII: 17,
  XVIII: 18,
  XIX: 19,
  XX: 20,
  XXI: 21,
  XXII: 22,
  XXIII: 23,
  XXIV: 24,
  XXV: 25,
  XXVI: 26,
  XXVII: 27,
  XXVIII: 28,
  XXIX: 29,
  XXX: 30,
  XXXI: 31,
  XXXII: 32,
  XXXIII: 33,
  XXXIV: 34,
  XXXV: 35,
  XXXVI: 36,
  XXXVII: 37,
  XXXVIII: 38,
}

export function loadJaneEyre(bookPathOverride = bookPath) {
  const book = fs.readFileSync(bookPathOverride, 'utf8')
  const start = book.indexOf('*** START OF THE PROJECT GUTENBERG EBOOK')
  const end = book.indexOf('*** END OF THE PROJECT GUTENBERG EBOOK')
  if (start < 0 || end < 0) throw new Error('Gutenberg start or end marker missing from pg1260.txt')
  const lines = book.slice(start, end).split('\n').slice(1)
  const heading = /^CHAPTER ([IVX]+)/
  const parts = []
  const marks = []
  let pos = 0
  let buf = []
  function flush() {
    if (!buf.length) return
    const piece = buf.join(' ')
    buf = []
    if (parts.length) {
      parts.push(' ')
      pos += 1
    }
    parts.push(piece)
    pos += piece.length
  }
  for (const line of lines) {
    const match = line.trim().match(heading)
    if (match) {
      flush()
      const number = ROMAN[match[1]]
      if (!number) throw new Error(`Unknown chapter heading: ${line.trim()}`)
      marks.push({ index: pos, number })
      continue
    }
    const raw = line.replaceAll('_', '').replace(/\s+/g, ' ').trim()
    if (raw) buf.push(raw)
  }
  flush()
  return { norm: parts.join(''), marks }
}

function placeAt(marks, index) {
  let current = null
  for (const mark of marks) {
    if (index >= mark.index) current = mark
    else break
  }
  return current
}

const BANNED = [
  'delve',
  'landscape',
  'robust',
  'seamless',
  'leverage',
  'unlock',
  'elevate',
  'empower',
  'fast-paced',
  'in this guide',
  'game-changer',
  'whether you',
]

function proseOf(data) {
  const bits = [
    data.description,
    data.metaDescription,
    data.lead,
    data.arrangement,
    data.sourceNote,
    data.appNote,
    data.eyebrow,
    data.indexLabel,
    ...(data.faqs ?? []).flatMap((faq) => [faq.question, faq.answer]),
    ...data.quotes.flatMap((quote) => [quote.context, quote.analysis, quote.speaker, ...(quote.themes ?? [])]),
  ]
  return bits.filter(Boolean).join('\n')
}

function run() {
  const { norm, marks } = loadJaneEyre()
  const data = JSON.parse(fs.readFileSync(quotesPath, 'utf8'))
  let matched = 0
  const failures = []
  const raw = JSON.stringify(data)
  if (raw.includes('\u2014')) failures.push('em dash in quote JSON')
  const prose = proseOf(data).toLowerCase()
  for (const word of BANNED) {
    if (prose.includes(word)) failures.push(`banned phrase: ${word}`)
  }
  if ((data.metaDescription ?? '').length > 155) {
    failures.push(`meta description is ${data.metaDescription.length} characters`)
  }
  if (data.quotes.length < 35 || data.quotes.length > 40) {
    failures.push(`expected 35 to 40 quotes, found ${data.quotes.length}`)
  }
  const numbers = marks.map((mark) => mark.number)
  const expected = Array.from({ length: 38 }, (_, index) => index + 1)
  if (numbers.join(',') !== expected.join(',')) failures.push(`unexpected chapter marks: ${numbers.join(', ')}`)

  for (const quote of data.quotes) {
    if (typeof quote.chapter !== 'number') {
      failures.push(`${quote.id}: chapter missing`)
      continue
    }
    const index = norm.indexOf(quote.text)
    if (index < 0) {
      failures.push(`${quote.id}: wording not found`)
      continue
    }
    if (norm.indexOf(quote.text, index + 1) >= 0) {
      failures.push(`${quote.id}: wording is not unique`)
      continue
    }
    if (quote.text.includes('\u2014')) {
      failures.push(`${quote.id}: em dash inside quotation`)
      continue
    }
    const place = placeAt(marks, index)
    if (!place || place.number !== quote.chapter) {
      failures.push(
        `${quote.id}: chapter ${quote.chapter} but text sits in ${place ? `chapter ${place.number}` : 'no chapter'}`,
      )
      continue
    }
    matched += 1
  }
  console.log(`${matched} of ${data.quotes.length} matched`)
  if (failures.length) {
    for (const failure of failures) console.error(failure)
    process.exit(1)
  }
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) run()
