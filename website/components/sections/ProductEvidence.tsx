import Image from 'next/image'

type ProductEvidenceProps = {
  alt: string
  caption?: string
}

export function ProductEvidence({alt, caption = 'BookQuotes product evidence from the current first-party build.'}: ProductEvidenceProps) {
  return (
    <figure className="container-standard pb-12 md:pb-16">
      <Image
        src="/screenshots/library.png"
        alt={alt}
        width={603}
        height={1311}
        sizes="(max-width: 768px) 70vw, 304px"
        className="w-full max-w-[19rem] border border-subtle bg-paper-aged"
      />
      <figcaption className="mt-4 max-w-xl font-ui text-sm text-ink-medium">
        {caption}
      </figcaption>
    </figure>
  )
}
