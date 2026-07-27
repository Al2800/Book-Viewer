# App Store Screenshot Refresh

## Deliverables

- iPhone 6.9-inch: `Marketing/Video/Remotion/out/appstore/iphone/`
- iPad 13-inch: `Marketing/Video/Remotion/out/appstore/ipad/`
- iPhone dimensions: 1320 x 2868 PNG, opaque
- iPad dimensions: 2064 x 2752 PNG, opaque

## Recommended Order

1. Keep the lines you underlined.
2. Scan the ISBN. Get the book.
3. Photograph the passage you marked.
4. AI finds the marked words.
5. Review every word.
6. Keep every passage with its book.
7. Find the line when it matters.

The first four images explain the primary acquisition, capture, extraction, and
review journey. The remaining images show editing, organisation, and retrieval.

## Media Content

App Store media mode uses fictional books, original passages, and generated cover
art. It does not use commercial book covers or published quotations. The media
dataset is available only during UI tests launched with `--app-store-media`; it
does not change production user data or camera behaviour.

## Reproduction

Run the App Store media screenshot test for the target iPhone and iPad simulators,
copy the exported seven screenshots into the matching Remotion `public/screens`
directory, then run:

```bash
cd Marketing/Video/Remotion
npm run check
npm run appstore
```

## App Store Connect

The approved 1.0 screenshot set is locked. Upload this set to a new App Store
version, such as 1.0.1, and associate that version with a new uploaded build before
submitting the metadata update for review.
