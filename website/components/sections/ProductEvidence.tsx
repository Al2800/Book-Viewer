import Image from 'next/image'

type ProductEvidenceProps = {
  alt: string
  caption?: string
}

export function ProductEvidence({alt, caption = 'BookQuotes product evidence from the current first-party build.'}: ProductEvidenceProps) {
  return (
    <figure className="container-standard pb-12 md:pb-16">
      <div className="mx-auto max-w-[19rem] overflow-hidden rounded-[2rem] border border-subtle bg-paper-aged p-2 shadow-sm">
        <Image
          src="/screenshots/library.png"
          alt={alt}
          width={603}
          height={1311}
          sizes="(max-width: 768px) 70vw, 304px"
          className="h-auto w-full rounded-[1.5rem]"
        />
      </div>
      <figcaption className="mx-auto mt-4 max-w-xl text-center font-ui text-sm text-ink-light">
        {caption}
      </figcaption>
    </figure>
  )
}