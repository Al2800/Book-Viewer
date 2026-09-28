import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const bookPath = path.join(root, 'content/sources/pg43.txt')
const quotesPath = path.join(root, 'content/quotes/jekyll-and-hyde.json')

const book = fs.readFileSync(bookPath, 'utf8')
const start = book.indexOf('*** START OF THE PROJECT GUTENBERG EBOOK')
const end = book.indexOf('*** END OF THE PROJECT GUTENBERG EBOOK')
if (start < 0 || end < 0) {
  console.error('Gutenberg start or end marker missing from pg43.txt')
  process.exit(1)
}

const body = book.slice(start, end).split('\n').slice(1).join('\n')
const norm = body.replace(/\s+/g, ' ').trim()
const data = JSON.parse(fs.readFileSync(quotesPath, 'utf8'))

const chapterMarks = [
  { number: 1, mark: 'STORY OF THE DOOR Mr. Utterson' },
  { number: 2, mark: 'SEARCH FOR MR. HYDE That evening' },
  { number: 3, mark: 'DR. JEKYLL WAS QUITE AT EASE A fortnight' },
  { number: 4, mark: 'THE CAREW MURDER CASE Nearly a year' },
  { number: 5, mark: 'INCIDENT OF THE LETTER It was late' },
  { number: 6, mark: 'INCIDENT OF DR. LANYON Time ran' },
  { number: 7, mark: 'INCIDENT AT THE WINDOW It chanced' },
  { number: 8, mark: 'THE LAST NIGHT Mr. Utterson was sitting' },
  { number: 9, mark: 'DR. LANYON’S NARRATIVE On the ninth' },
  { number: 10, mark: 'HENRY JEKYLL’S FULL STATEMENT OF THE CASE I was born' },
].map((chapter) => ({ ...chapter, index: norm.indexOf(chapter.mark) }))

function chapterAt(index) {
  let current = 0
  for (const mark of chapterMarks) {
    if (mark.index >= 0 && index >= mark.index) current = mark.number
  }
  return current
}

let matched = 0
const failures = []

if (JSON.stringify(data).includes('\u2014')) failures.push('em dash in quote JSON')

for (const mark of chapterMarks) {
  if (mark.index < 0) failures.push(`chapter mark missing: ${mark.mark}`)
}

for (const quote of data.quotes) {
  const index = norm.indexOf(quote.text)
  if (index < 0) {
    failures.push(`${quote.id}: wording not found`)
    continue
  }
  const chapter = chapterAt(index)
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
