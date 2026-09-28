/** @type {import('next').NextConfig} */
const nextConfig = {
  images: {
    formats: ['image/avif', 'image/webp'],
  },
  async redirects() {
    return [
      {
        source: '/journal/build-a-digital-commonplace-book',
        destination: '/guides/digital-commonplace-book',
        statusCode: 301,
      },
    ]
  },
}

export default nextConfig
