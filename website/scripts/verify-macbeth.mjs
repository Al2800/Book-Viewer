import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const bookPath = path.join(root, 'content/sources/pg1533.txt')
const quotesPath = path.join(root, 'content/quotes/macbeth.json')

const ROMAN = { I: 1, II: 2, III: 3, IV: 4, V: 5, VI: 6, VII: 7, VIII: 8 }

export function loadMacbeth(bookPathOverride = bookPath) {
  const book = fs.readFileSync(bookPathOverride, 'utf8')
  const start = book.indexOf('*** START OF THE PROJECT GUTENBERG EBOOK')
  const end = book.indexOf('*** END OF THE PROJECT GUTENBERG EBOOK')
  if (start < 0 || end < 0) throw new Error('Gutenberg start or end marker missing from pg1533.txt')
  const body = book.slice(start, end).split('\n').slice(1)
  let actCount = 0
  let begin = 0
  for (let index = 0; index < body.length; index += 1) {
    if (body[index].trim() === 'ACT I') {
      actCount += 1
      if (actCount === 2) {
        begin = index
        break
      }
    }
  }
  const scenes = []
  let current = null
  for (const line of body.slice(begin)) {
    const trimmed = line.trim()
    const act = trimmed.match(/^ACT ([IVX]+)$/)
    const scene = trimmed.match(/^SCENE ([IVX]+)\./)
    if (act) {
      current = { act: ROMAN[act[1]], scene: null, lines: [], speaker: '' }
      continue
    }
    if (scene) {
      current = { act: current.act, scene: ROMAN[scene[1]], lines: [], speaker: '' }
      scenes.push(current)
      continue
    }
    if (!current?.scene || trimmed === '' || line.startsWith(' ')) continue
    if (
      trimmed.endsWith('.') &&
      trimmed.length <= 40 &&
      !trimmed.startsWith('SCENE') &&
      !trimmed.startsWith('ACT') &&
      /^[A-Z0-9 .'’,:\-]+$/.test(trimmed)
    ) {
      current.speaker = trimmed.replace(/\.$/, '')
      continue
    }
    current.lines.push({ n: current.lines.length + 1, speaker: current.speaker, text: trimmed })
  }
  const norm = body.join('\n').replace(/\s+/g, ' ').trim()
  return { scenes, norm }
}

export function locateQuote(play, text) {
  for (const scene of play.scenes) {
    let cursor = 0
    const spans = scene.lines.map((line) => {
      const start = cursor
      cursor += line.text.length + 1
      return { ...line, start, end: start + line.text.length }
    })
    const joined = scene.lines.map((line) => line.text).join(' ')
    const index = joined.indexOf(text)
    if (index < 0) continue
    const end = index + text.length
    const covered = spans.filter((span) => end > span.start && index < span.end)
    return {
      act: scene.act,
      scene: scene.scene,
      lineStart: covered[0].n,
      lineEnd: covered[covered.length - 1].n,
      speaker: covered[0].speaker,
    }
  }
  return null
}

function run() {
  const play = loadMacbeth()
  const data = JSON.parse(fs.readFileSync(quotesPath, 'utf8'))
  let matched = 0
  const failures = []
  if (JSON.stringify(data).includes('\u2014')) failures.push('em dash in quote JSON')
  for (const quote of data.quotes) {
    if (!play.norm.includes(quote.text)) {
      failures.push(`${quote.id}: wording not found in the play`)
      continue
    }
    const found = locateQuote(play, quote.text)
    if (!found) {
      failures.push(`${quote.id}: not found inside a scene`)
      continue
    }
    if (found.act !== quote.act || found.scene !== quote.scene) {
      failures.push(`${quote.id}: Act ${quote.act} Scene ${quote.scene} but text sits in Act ${found.act} Scene ${found.scene}`)
      continue
    }
    if (found.lineStart !== quote.lineStart || found.lineEnd !== quote.lineEnd) {
      failures.push(
        `${quote.id}: lines ${quote.lineStart}-${quote.lineEnd} but text sits on ${found.lineStart}-${found.lineEnd}`,
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
