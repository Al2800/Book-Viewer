# BookQuotes Social Video

Reusable Remotion source for BookQuotes launch content.

## Outputs

- `BookQuotesMarkedPage`: 1080 x 1920, 22 seconds, 30 fps
- `OneLinePerBook`: 1080 x 1920, 22 seconds, 30 fps
- `AnnotationDebate`: 1080 x 1920, 22 seconds, 30 fps
- `CommonplaceRitual`: 1080 x 1920, 22 seconds, 30 fps
- `FindTheLine`: 1080 x 1920, 22 seconds, 30 fps
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
npm run carousels
npm run community
npm run appstore
```

`npm run community` renders four Reels, their custom covers, and five four-slide carousel
sets under `out/community/`. Individual community assets can be rendered with the
`community:reel:*` and `community:carousel:*` commands in `package.json`.

Rendered files are written to `out/`. To add a commercial voiceover, place the audio under
`public/audio/` and set `voiceoverPath` in `src/Root.tsx`.

App Store compositions expect clean simulator captures under
`public/screens/appstore/iphone/` and `public/screens/appstore/ipad/`.
