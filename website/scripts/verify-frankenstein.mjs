import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const bookPath = path.join(root, 'content/sources/pg84.txt')
const quotesPath = path.join(root, 'content/quotes/frankenstein.json')

export function loadFrankenstein(bookPathOverride = bookPath) {
  const book = fs.readFileSync(bookPathOverride, 'utf8')
  const start = book.indexOf('*** START OF THE PROJECT GUTENBERG EBOOK')
  const end = book.indexOf('*** END OF THE PROJECT GUTENBERG EBOOK')
  if (start < 0 || end < 0) throw new Error('Gutenberg start or end marker missing from pg84.txt')
  const lines = book.slice(start, end).split('\n').slice(1)
  const letterOnes = []
  lines.forEach((line, index) => {
    if (line.trim() === 'Letter 1') letterOnes.push(index)
  })
  if (letterOnes.length < 2) throw new Error('Letter 1 heading not found twice in pg84.txt')
  const heading = /^(Letter|Chapter) (\d+)$/
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
  for (const line of lines.slice(letterOnes[1])) {
    const match = line.trim().match(heading)
    if (match) {
      flush()
      marks.push({ index: pos, kind: match[1], number: Number(match[2]) })
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
  const { norm, marks } = loadFrankenstein()
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
  const kinds = marks.map((mark) => `${mark.kind} ${mark.number}`)
  const expected = [
    ...[1, 2, 3, 4].map((n) => `Letter ${n}`),
    ...Array.from({ length: 24 }, (_, index) => `Chapter ${index + 1}`),
  ]
  if (kinds.join(',') !== expected.join(',')) failures.push(`unexpected section marks: ${kinds.join(', ')}`)

  for (const quote of data.quotes) {
    const cited = String(quote.citation ?? '').match(/^(Letter|Chapter) (\d+)$/)
    if (!cited) {
      failures.push(`${quote.id}: citation must be Letter N or Chapter N`)
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
    if (!place || place.kind !== cited[1] || place.number !== Number(cited[2])) {
      failures.push(
        `${quote.id}: ${quote.citation} but text sits in ${place ? `${place.kind} ${place.number}` : 'no section'}`,
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
