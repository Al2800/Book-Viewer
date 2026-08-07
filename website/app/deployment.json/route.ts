declare const __BOOKQUOTES_SOURCE_REVISION__: string

export const dynamic = 'force-static'

export function GET() {
  return Response.json(
    {
      service: 'bookquotes-website',
      canonicalOrigin: 'https://bookquotes.uk',
      sourceRevision: __BOOKQUOTES_SOURCE_REVISION__,
    },
    {
      headers: {
        'Cache-Control': 'public, max-age=60, must-revalidate',
      },
    },
  )
}
