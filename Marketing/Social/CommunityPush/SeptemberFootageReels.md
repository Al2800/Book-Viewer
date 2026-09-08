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
