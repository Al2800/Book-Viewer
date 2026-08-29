# BookQuotes Social Video

Reusable Remotion source for BookQuotes launch content.

## Outputs

- `BookQuotesMarkedPage`: 1080 x 1920, 22 seconds, 30 fps
- `BookQuotesIntro`: 1080 x 1920, 30 seconds, 30 fps — pinned Instagram product explainer
- `OneLinePerBook`: 1080 x 1920, 22 seconds, 30 fps
- `AnnotationDebate`: 1080 x 1920, 22 seconds, 30 fps
- `CommonplaceRitual`: 1080 x 1920, 22 seconds, 30 fps
- `FindTheLine`: 1080 x 1920, 22 seconds, 30 fps
- `PresidentialBooksReel`: 1080 x 1920, 29 seconds, 30 fps
- `HandwrittenBookReview`: 1080 x 1920, 15-second daily reading-note format
- `CategoryReel-01` to `CategoryReel-07`: 1080 x 1920, 10-second faceless category Reels (19–25 Aug)
- `Illustrated-01` to `Illustrated-07`: 1080 x 1920, 18-second stills-compiled Reels. Pictures come from `public/illustrated/cr-0N/`. Type is Remotion. Optional bed: drop a UK Commercial Music Library mp3 at `public/audio/category-reel-bed.mp3` and set `musicPath` — do not attach uncleared music. `npm run illustrated`
- `PresidentialBooks-01` to `PresidentialBooks-07`: 1080 x 1920 TikTok photo carousel
- `Capture-01` to `Capture-04`: 1080 x 1350 carousel
- `Library-01` to `Library-04`: 1080 x 1350 carousel
- `Choice-01` to `Choice-04`: 1080 x 1350 carousel
- `Remember-01` to `Remember-04`: 1080 x 1350 carousel
- `OneLine-01` to `OneLine-04`: 1080 x 1350 carousel
- `BookClub-01` to `BookClub-04`: 1080 x 1350 carousel
- `Annotation-01` to `Annotation-04`: 1080 x 1350 carousel
- `Commonplace-01` to `Commonplace-04`: 1080 x 1350 carousel
- `AppStore-iPhone-01` to `AppStore-iPhone-07`: 1320 x 2868 screenshots
- `AppStore-iPad-01` to `AppStore-iPad-07`: 2064 x 2752 screenshots

## Commands

```bash
npm install
npm run check
npm run render
npm run cover
npm run covers
npm run presidents
npm run review:handwritten
npm run category
npm run carousels
npm run community
npm run appstore
```

`npm run community` renders four Reels, their custom covers, and five four-slide carousel
sets under `out/community/`. Individual community assets can be rendered with the
`community:reel:*` and `community:carousel:*` commands in `package.json`.

Reel covers are dedicated `*-Cover` compositions in `src/FeedCover.tsx`, not frames
grabbed from the video. Product and book-overview tiles use the ShiftPro phone
layout: dark field, hook on the left, real device chrome on the right. The intro
uses the library screenshot. Book overviews reconstruct the book-detail screen
around a rights-cleared jacket and a reader note, never a passage from the book.
Presidential, handwritten, and jacketed sci-fi Reels open on that same phone
still, then cut to the existing paper body. Daily category Reels (`CategoryReel-*`)
open on the CommunityReel typography hook instead: type already on at frame 0,
who-for by 3s, no phone chrome, no brand in the open. Covers are separate
dark-field posters under `out/community/category-reels/`.
Other community tiles stay book-first objects. Brand only on the product posts.
Rebuild stills without re-encoding video with `npm run covers`.

## Cover review

Open the `*-Cover` compositions in Remotion Studio, or the PNGs under `out/`.
Video bodies are unchanged. Review questions:

1. Does the tile read at one-inch / grid size, or does it still look like stationery?
2. Is the first readable thing a book, a title, or a reader situation — not the app?
3. Are publisher jackets used only where we already have a rights-cleared asset?
4. Should any hook be shorter, or should any abstract page object become a real
   marked-page photograph later?

Brand appears only on `BookQuotesMarkedPage-Cover` and `SciFi-10-KeepTheLine-Cover`.

Rendered files are written to `out/`. To add a commercial voiceover, place the audio under
`public/audio/` and set `voiceoverPath` in `src/Root.tsx`.

App Store compositions expect clean simulator captures under
`public/screens/appstore/iphone/` and `public/screens/appstore/ipad/`.
