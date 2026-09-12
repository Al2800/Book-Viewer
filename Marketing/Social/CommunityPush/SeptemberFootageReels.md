# September physical-book reel collection

Prepared 8 September 2026. Refs: book-quote-wra8; discovered from bd-tkrc.

## Delivery

Local collection: `/Users/skyhub/Downloads/BookQuotes-Reel-Collection-2026-09-08/`

- `reels/`: 12 MP4 files, approximately 75.8 MB total.
- `covers/`: 12 optional full-resolution cover stills, separate from the videos.
- `POSTING-GUIDE.md`: ordered titles/authors and suggested captions.
- `collection.json`: source hashes, trim/stretch/hold decisions, output hashes, book order and durations.
- `render_collection.py`: explicit batch assembly recipe; uses FFmpeg no-overwrite mode.
- `review/`: original probes/contact sheets, normalized segments, final review sheets, and isolated imageio-ffmpeg tooling.

The media and local tooling are intentionally not added to Git. Preserve the delivery folder alongside the source MOVs. No original file was overwritten or deleted. At production handoff nothing had been uploaded, scheduled or published. The separately authorised Creator Inbox delivery is recorded below; no public publishing was requested.

## Reference and treatment

Reviewed the five earlier `bookquotes-*.mp4` exports in Downloads, including timeline frames from `bookquotes-chip-code-pairing.mp4`, plus its caption and the thinking-shelf caption. These are the user's previous TikTok references; publication was not independently reverified in this task.

Keep the existing physical-book style: straight cuts, full-frame handheld footage, no intro card, no burned-in captions or branding, no music or source audio. All outputs are 1080 × 1920, 30 fps, H.264/yuv420p, BT.709, with fast-start metadata.

Sources: the 22 `IMG_9421.MOV` through `IMG_9443.MOV` files in Downloads (9425 absent). All 22 are used somewhere in the collection. Corrected the sideways Helgoland (9423) and Sense of Style (9428) footage clockwise. Source rotation metadata is otherwise respected. No additional jacket crop was introduced; some original framing, especially The Everything Store, already cuts a jacket edge.

Each normal shot lasts 2.5 seconds; the mixed compilation uses 2 seconds. Trim initial 0.08 seconds, cap duration stretch at 1.5×, and hold the last frame where a very short source cannot fill the slot. This is a silent music-ready edit, not audio beat-synchronised footage.

## Slate

Names below are MP4 stems in `reels/`. Sources are IMG numbers, in playback order.

| File | Duration | Books / sources |
|---|---:|---|
| 01-pair-quantum-physics | 5s | Helgoland → Reality Is Not What It Seems / 9423, 9432 |
| 02-pair-talent-and-success | 5s | Outliers → The Sports Gene / 9440, 9439 |
| 03-pair-business-investigations | 5s | Bad Blood → The Fund / 9441, 9438 |
| 04-pair-freakonomics | 5s | Freakonomics → Think Like a Freak / 9431, 9434 |
| 05-pair-michael-lewis | 5s | The Premonition → The Fifth Risk / 9424, 9433 |
| 06-pair-words-and-speaking | 5s | The Sense of Style → TED Talks / 9428, 9443 |
| 07-pair-a-thinking-life | 5s | How to Think Like a Philosopher → Don't You Have Time to Think? / 9436, 9442 |
| 08-collection-money-risk-and-data | 10s | The Big Short → The Money Machine → Skin in the Game → The Art of Statistics / 9426, 9429, 9430, 9435 |
| 09-collection-the-physics-shelf | 10s | Our Mathematical Universe → Helgoland → Reality Is Not What It Seems → Don't You Have Time to Think? / 9422, 9423, 9432, 9442 |
| 10-collection-malcolm-gladwell | 7.5s | What the Dog Saw → The Bomber Mafia → Outliers / 9421, 9427, 9440 |
| 11-collection-behind-the-business | 10s | The Everything Store → Bad Blood → The Fund → The Big Short / 9437, 9441, 9438, 9426 |
| 12-compilation-eight-book-shelf | 16s | Baggini → Spiegelhalter → Tegmark → Freakonomics → The Sports Gene → The Everything Store → The Premonition → What the Dog Saw / 9436, 9435, 9422, 9431, 9439, 9437, 9424, 9421 |

## Checks and posting notes

All 12 outputs passed complete FFmpeg decode and FFprobe assertions for dimensions, 30 fps, yuv420p, expected duration, and exactly one video stream with no audio. Inspected final contact sheets for orientation, jacket readability, and sequence selection. The review used sampled frames, not real-time playback with music. Captions are discussion prompts rather than invented firsthand reading claims.

Footage provenance is the user's supplied physical-book recordings; jacket ownership/licensing is not independently established. No downloaded third-party cover art or quotations were added. Use commercially cleared music appropriate to the posting account, such as TikTok's Commercial Music Library for brand content.

Choose either a pairing or a broader themed collection for a given posting slot; these intentionally reuse books and should not all be posted back-to-back as unique footage. Add music and optionally native text in the platform editor, then preview the final result before posting.

Environment: cm and UBS were unavailable on PATH; Agent Mail was not exposed. Remotion's bundled FFmpeg lacks the necessary video timing filters, so a full imageio-ffmpeg 0.6.0 binary was installed only inside this delivery folder. Its first limited-build render attempt failed before any video output was written; the successful render used the full binary. Unrelated `feedback_downloads/` remains untouched.

## Authorised Creator Inbox delivery — 8 September 2026

User subsequently requested: “can you sned them to my account with zernio poeklase”. Interpreted in the music-ready context as Creator Inbox delivery, not public posting. Confirmed this scope in the conversation before writes.

Verified @bookquotes.app account ID `6a7e30f977555aae0187cea3`, active connection and healthy token. Read the complete account-filtered Zernio list (23 posts, one page) and found no matching collection captions or hashes. The policy gate allowed delivery. Zernio documents a five-pending-draft cap; only five were attempted, once each, sequentially.

| Reel | Zernio post ID | Read-back outcome |
|---|---|---|
| 01-pair-quantum-physics | 6a9fef020ddf6ed410e52862 | Creator Inbox accepted |
| 02-pair-talent-and-success | 6a9fef1e310280ffb33773fc | Creator Inbox accepted |
| 03-pair-business-investigations | 6a9fef3fa64c547b75986f92 | Creator Inbox accepted |
| 08-collection-money-risk-and-data | 6a9fef5ecef0cd41c36fb3d3 | Creator Inbox accepted |
| 09-collection-the-physics-shelf | 6a9fefa8fce09d36bb272b40 | Creator Inbox accepted |

Every write explicitly used root `tiktokSettings.draft: true` and the single bound TikTok target. Each GET read-back matched the caption and account, returned platform status `published` **with `platformSpecificData.isDraft: true` and no public URL**. Per Zernio's contract, that status means the inbox upload was accepted, NOT that a public video was published. Source/output hashes were checked before upload. No ambiguous requests were retried.

Receipts: `zernio-inbox-receipts/` inside the local collection folder. Batch recipe: `send_inbox_batch.py`; its exclusive receipt-directory creation prevents accidental reruns. These remain local, not in Git.

Remaining reels **04, 05, 06, 07, 10, 11, 12** have not been sent. Tracking: `book-quote-48u7`, blocked pending the user processing current inbox drafts. Do not automatically retry, delete drafts, or publish to clear slots. User should open TikTok as @bookquotes.app, look for the upload notifications in Inbox, add music and review caption/cover/privacy in the TikTok editor. Captions and covers on native inbox drafts may still require manual selection; Zernio read-back does not prove the final native editor retained them.

Reference checked: https://docs.zernio.com/platforms/tiktok.mdx and https://docs.zernio.com/guides/platform-settings.mdx. Local UBS remains unavailable; delivery validation is from hash checks, account/duplicate preflight and per-item API read-back.

## Batch 02 and Instagram handoff — evening 8 September 2026

User requested more edits from existing footage, with new filming planned tomorrow, then added Instagram as a destination. Production completed under `book-quote-fv6d`. Instagram delivery is tracked separately under `book-quote-7dh3`: clarify native/manual draft workflow versus scheduling/publication after music selection. Do not infer approval to publish silent videos.

Local batch: `/Users/skyhub/Downloads/BookQuotes-Reel-Collection-2026-09-08/batch-02/`. Contains eight MP4s in `reels/`, optional stills in `covers/`, a dual-platform `POSTING-GUIDE.md`, source/output hash manifest `collection.json`, `prepare_batch.py`, and visual review sheets. The recipe imports the original renderer rather than copying or modifying it.

| File stem | Duration | Sources / grouping |
|---|---:|---|
| 13-pair-health-and-business | 5s | 8904, 9441 / Empire of Pain + Bad Blood |
| 14-pair-chips-and-amazon | 5s | 8910, 9437 / Chip War + The Everything Store |
| 15-pair-maths-and-statistics | 5s | 8912, 9435 / How Not to Be Wrong + The Art of Statistics |
| 16-pair-risk-and-responsibility | 5s | 8909, 9430 / Against the Gods + Skin in the Game |
| 17-collection-thinking-in-numbers | 7.5s | 9435, 8911, 8912 / statistics, calculus, everyday maths |
| 18-pair-codes-and-calculus | 5s | 8913, 8911 / The Code Book + Infinite Powers |
| 19-collection-leadership-and-public-service | 7.5s | 8906, 9433, 9424 / Truman + The Fifth Risk + The Premonition |
| 20-collection-chance-and-consequences | 7.5s | 8914, 9430, 8909 / Randomness + Skin in the Game + Against the Gods |

Eight usable older MOVs were identified from a ten-file IMG_89xx batch. Excluded 8907 (0.27-second American Prometheus shot) and 8908 (motion-obscured jacket). No identical book sets against the first 12 reels or four earlier posted pairs; shared books and some shared pairs within larger collections are intentional, not new footage. Space related edits apart.

All eight outputs passed full decode, expected-duration, one-video/no-audio, 1080×1920, 30fps and yuv420p assertions. Every output shot was sampled in final visual review sheets. Verified source hashes unchanged. No extra overlays, watermark, music or additional crop. Original jacket-edge clipping remains visible where present in source footage.

Read-only Meta identity check confirmed Instagram @bookquotes.app, ID `17841434821362428`, linked to the bound Facebook Page with publishing permission. No Instagram or additional TikTok write was made. `INSTAGRAM-GUIDE.md` in the parent collection folder now supplies Instagram-specific captions and local paths for **all 20 reels**. A Zernio draft is not a native Instagram app draft; manual import into the Instagram editor remains the clear path for adding music and saving a native draft. API music capabilities require separate account/rights checks if later requested.

Tomorrow's filming guidance is in the batch posting guide: portrait, 6–8 seconds per book, whole jacket visible with margin, steady soft light, a still second at each end, two takes, and some shelf/two-book movement shots. Capture new genre groups rather than repeatedly expanding the same combinations. No source or existing output was deleted or overwritten. Local batch files remain outside Git; UBS and cm were unavailable.

## Phone delivery for manual Instagram editing — 8 September 2026, 23:32 BST

User chose Tailscale transfer to their phone so they can import the silent videos into Instagram and add music themselves. Verified the single iOS peer `iphone183` on the same Tailscale account. Taildrop reported successful transfer of `INSTAGRAM-GUIDE.md` and all 20 numbered MP4s (01–20); both commands exited 0, with a separate `sent` confirmation for every file. Cover stills and production scripts were not transferred.

Delivery task `book-quote-7dh3` is complete as a **phone handoff for manual Instagram editing**, not Instagram publication. The receiver's Photos import and in-app posting were not observed. No Instagram API write or further TikTok inbox upload was made. Source files remain untouched.

Suggested audio directions: soft piano/ambient for science and philosophy; instrumental lo-fi for shelf compilations; restrained jazz/percussion for business and history. These are style suggestions, not claims that particular tracks are commercially licensed. Use Meta Sound Collection or another track explicitly cleared for the intended brand use. The user can save the received MP4s to Photos, select them in Instagram Create Reel, add cleared audio, and review/save a draft before posting.

## Next TikTok Inbox delivery — 12 September 2026

User requested more clips. Read the complete bound-account Zernio listing (31 posts, one page) and reconciled filenames, captions and hashes. Reels 04, 05 and 12 had already been delivered by intervening work; they were not resent. The connection was active with approximately 2.5 hours of token validity remaining, so no reconnect/account mutation was needed for this short batch.

| Reel | Zernio post ID | Read-back result |
|---|---|---|
| 06-pair-words-and-speaking | 6aa4ef7fba36ae6f757e86af | Accepted inbox draft |
| 07-pair-a-thinking-life | 6aa4ef9dba36ae6f757e8e2e | Accepted inbox draft |
| 10-collection-malcolm-gladwell | 6aa4efb52bb4a6f7f741ae7d | Accepted inbox draft |
| 11-collection-behind-the-business | 6aa4efde9cabde85abdadc41 | Accepted inbox draft |
| 13-pair-health-and-business | 6aa4f018662ee2d345bceb39 | Failed: TikTok five-pending-drafts cap |

All five requests were single-account Creator Inbox requests with `draft: true`; source video hashes were verified before upload. Four independent GET read-backs matched the account and caption, `status: published`, `platformSpecificData.isDraft: true`, and no public URL. The fifth GET read-back confirmed a failed platform entry with the explicit pending-draft-cap error. Stopped immediately: no retry, deletion, public publishing, or additional upload attempt.

Receipts: `zernio-inbox-20260912T062147Z/` inside the local collection folder. The original 12-reel inbox delivery is now complete (`book-quote-48u7`). Follow-up `book-quote-59yp` tracks batch-two reels 13–20 after the user processes pending drafts. Reel 13 already has a failed Zernio object: reconcile it before any retry; do not blindly create another post. Reels 14–20 were not attempted. Zernio acceptance does not prove the user opened the draft or published it.
