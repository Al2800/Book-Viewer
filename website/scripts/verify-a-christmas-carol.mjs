import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const bookPath = path.join(root, 'content/sources/pg46.txt')
const quotesPath = path.join(root, 'content/quotes/a-christmas-carol.json')

const book = fs.readFileSync(bookPath, 'utf8')
const start = book.indexOf('*** START OF THE PROJECT GUTENBERG EBOOK')
const end = book.indexOf('*** END OF THE PROJECT GUTENBERG EBOOK')
if (start < 0 || end < 0) {
  console.error('Gutenberg start or end marker missing from pg46.txt')
  process.exit(1)
}

const body = book.slice(start, end).split('\n').slice(1).join('\n')
const norm = body.replace(/\s+/g, ' ').trim()
const data = JSON.parse(fs.readFileSync(quotesPath, 'utf8'))

const staveMarks = [1, 2, 3, 4, 5].map((number) => ({
  number,
  index: norm.indexOf(`STAVE ${['I', 'II', 'III', 'IV', 'V'][number - 1]}:`),
}))

function staveAt(index) {
  let current = 0
  for (const mark of staveMarks) {
    if (mark.index >= 0 && index >= mark.index) current = mark.number
  }
  return current
}

let matched = 0
const failures = []

if (JSON.stringify(data).includes('\u2014')) failures.push('em dash in quote JSON')

for (const quote of data.quotes) {
  const index = norm.indexOf(quote.text)
  if (index < 0) {
    failures.push(`${quote.id}: wording not found`)
    continue
  }
  const stave = staveAt(index)
  if (stave !== quote.stave) {
    failures.push(`${quote.id}: stave ${quote.stave} but text sits in stave ${stave}`)
    continue
  }
  matched += 1
}

console.log(`${matched} of ${data.quotes.length} matched`)
if (failures.length) {
  for (const failure of failures) console.error(failure)
  process.exit(1)
}
