declare const __BOOKQUOTES_SOURCE_REVISION__: string

export const dynamic = 'force-static'

function sourceRevision(): string {
  if (typeof __BOOKQUOTES_SOURCE_REVISION__ !== 'undefined' && __BOOKQUOTES_SOURCE_REVISION__) {
    return __BOOKQUOTES_SOURCE_REVISION__.slice(0, 12)
  }

  const environmentRevision =
    process.env.GITHUB_SHA ?? process.env.CF_PAGES_COMMIT_SHA ?? process.env.SOURCE_REVISION
  return environmentRevision ? environmentRevision.slice(0, 12) : 'unknown'
}

export function GET() {
  return Response.json(
    {
      service: 'bookquotes-website',
      canonicalOrigin: 'https://bookquotes.uk',
      sourceRevision: sourceRevision(),
    },
    {
      headers: {
        'Cache-Control': 'public, max-age=60, must-revalidate',
      },
    },
  )
}
