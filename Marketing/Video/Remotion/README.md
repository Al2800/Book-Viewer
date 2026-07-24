# BookQuotes Social Video

Reusable Remotion source for BookQuotes launch content.

## Outputs

- `BookQuotesMarkedPage`: 1080 x 1920, 22 seconds, 30 fps
- `Capture-01` to `Capture-04`: 1080 x 1350 carousel
- `Library-01` to `Library-04`: 1080 x 1350 carousel
- `Choice-01` to `Choice-04`: 1080 x 1350 carousel

## Commands

```bash
npm install
npm run check
npm run render
npm run cover
npm run carousels
```

Rendered files are written to `out/`. To add a commercial voiceover, place the audio
under `public/audio/` and set `voiceoverPath` in `src/Root.tsx`.
