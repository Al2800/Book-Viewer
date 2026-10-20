import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const bookPath = path.join(root, 'content/sources/pg1342.txt')
const quotesPath = path.join(root, 'content/quotes/pride-and-prejudice.json')

const ROMAN = { I: 1, V: 5, X: 10, L: 50, C: 100, D: 500, M: 1000 }

function romanToInt(value) {
  let total = 0
  let prev = 0
  for (const char of [...value].reverse()) {
    const number = ROMAN[char]
    if (number < prev) total -= number
    else total += number
    prev = number
  }
  return total
}

export function loadPrideAndPrejudice(bookPathOverride = bookPath) {
  const book = fs.readFileSync(bookPathOverride, 'utf8')
  const start = book.indexOf('*** START OF THE PROJECT GUTENBERG EBOOK')
  const end = book.indexOf('*** END OF THE PROJECT GUTENBERG EBOOK')
  if (start < 0 || end < 0) throw new Error('Gutenberg start or end marker missing from pg1342.txt')
  const lines = book.slice(start, end).split('\n').slice(1)
  const novelStart = lines.findIndex((line) => line.trim() === 'Chapter I.]')
  if (novelStart < 0) throw new Error('Chapter I.] not found in pg1342.txt')
  const heading = /^(?:CHAPTER|Chapter)\s+([IVXLCDM]+)\.?\]?$/
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
  for (const line of lines.slice(novelStart)) {
    const trimmed = line.trim()
    const match = trimmed.match(heading)
    if (match) {
      flush()
      marks.push({ index: pos, chapter: romanToInt(match[1]) })
      continue
    }
    const raw = line.replaceAll('_', '').replace(/\s+/g, ' ').trim()
    if (raw) buf.push(raw)
  }
  flush()
  return { norm: parts.join(''), marks }
}

function chapterAt(marks, index) {
  let current = 0
  for (const mark of marks) {
    if (index >= mark.index) current = mark.chapter
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

function run() {
  const { norm, marks } = loadPrideAndPrejudice()
  const data = JSON.parse(fs.readFileSync(quotesPath, 'utf8'))
  let matched = 0
  const failures = []
  const raw = JSON.stringify(data)
  if (raw.includes('\u2014')) failures.push('em dash in quote JSON')
  const lower = raw.toLowerCase()
  for (const word of BANNED) {
    if (lower.includes(word)) failures.push(`banned phrase: ${word}`)
  }
  if ((data.metaDescription ?? '').length > 155) {
    failures.push(`meta description is ${data.metaDescription.length} characters`)
  }
  if (data.quotes.length < 35 || data.quotes.length > 40) {
    failures.push(`expected 35 to 40 quotes, found ${data.quotes.length}`)
  }
  const expected = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61]
  const foundChapters = marks.map((mark) => mark.chapter)
  if (foundChapters.join(',') !== expected.join(',')) {
    failures.push(`chapter marks ${foundChapters.length}, expected 61 continuous chapters`)
  }
  for (const quote of data.quotes) {
    const index = norm.indexOf(quote.text)
    if (index < 0) {
      failures.push(`${quote.id}: wording not found`)
      continue
    }
    if (norm.indexOf(quote.text, index + 1) >= 0) {
      failures.push(`${quote.id}: wording is not unique`)
      continue
    }
    const chapter = chapterAt(marks, index)
    if (chapter !== quote.chapter) {
      failures.push(`${quote.id}: chapter ${quote.chapter} but text sits in chapter ${chapter}`)
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
