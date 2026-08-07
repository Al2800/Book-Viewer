import type {NextRequest} from 'next/server'
import {NextResponse} from 'next/server'

const canonicalHost = 'bookquotes.uk'

export function middleware(request: NextRequest) {
  const forwardedProtocol = request.headers.get('x-forwarded-proto')?.split(',')[0]?.trim()
  const requestHost = request.headers.get('host')?.split(':')[0]?.toLowerCase()

  if (forwardedProtocol === 'http' || requestHost === `www.${canonicalHost}`) {
    const canonicalUrl = request.nextUrl.clone()
    canonicalUrl.protocol = 'https:'
    canonicalUrl.host = canonicalHost
    canonicalUrl.port = ''
    return NextResponse.redirect(canonicalUrl, 308)
  }

  return NextResponse.next()
}

export const config = {
  matcher: ['/:path*'],
}
