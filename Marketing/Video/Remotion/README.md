# BookQuotes Social Video

Reusable Remotion source for BookQuotes launch content.

## Outputs

- `BookQuotesMarkedPage`: 1080 x 1920, 22 seconds, 30 fps
- `Capture-01` to `Capture-04`: 1080 x 1350 carousel
- `Library-01` to `Library-04`: 1080 x 1350 carousel
- `Choice-01` to `Choice-04`: 1080 x 1350 carousel
- `AppStore-iPhone-01` to `AppStore-iPhone-07`: 1320 x 2868 screenshots
- `AppStore-iPad-01` to `AppStore-iPad-07`: 2064 x 2752 screenshots

## Commands

```bash
npm install
npm run check
npm run render
npm run cover
npm run carousels
npm run appstore
```

Rendered files are written to `out/`. To add a commercial voiceover, place the audio
under `public/audio/` and set `voiceoverPath` in `src/Root.tsx`.

App Store compositions expect clean simulator captures under
`public/screens/appstore/iphone/` and `public/screens/appstore/ipad/`.
