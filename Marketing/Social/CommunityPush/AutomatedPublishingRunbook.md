# BookQuotes Automated Social Publishing Runbook

Updated: 28 July 2026

## Purpose

This runbook defines how BookQuotes maintains a regular organic publishing flow without requiring
approval for every routine Facebook post. The system should behave like a careful editor, not a
blind autoposter.

Facebook is the first automatic channel. TikTok and Instagram remain manual until their account
connections, native publishing controls and post-verification flows have been tested.

## Publishing Authority

The daily BookQuotes social automation may create, schedule and publish routine organic Facebook
posts that pass every gate in this document. This standing authority replaces the previous
per-post approval rule for this limited category.

Automatic authority covers:

- verified book recommendations and reading lists;
- reader discussion prompts;
- annotation, reading-journal and commonplace-book practices;
- book-club prompts;
- low-risk BookQuotes workflow demonstrations;
- carousels, photos, text posts and organic Reels;
- routine rescheduling after a clearly identified technical publishing failure.

Automatic authority does not cover:

- paid advertisements, boosts, budgets or targeting;
- competitions, giveaways, discounts or financial commitments;
- complaints, negative sentiment or customer-support claims;
- subscriptions, billing, refunds or purchase promises;
- privacy, account deletion, legal or regulatory matters;
- partnerships, sponsorships, endorsements or publisher relationships;
- unverified claims, unclear visual rights or substantial copyrighted extracts;
- deleting published content, except to contain a clear rights, privacy or safety problem.

Those cases must be logged and presented to the user with a recommended action.

## Cadence

Maintain a rolling seven-day Facebook queue with one strong primary post per day.

- Use 12:30 Europe/London for text posts, discussion prompts and carousels when no stronger
  account evidence exists.
- Use 18:30-19:00 Europe/London for Reels and more visual posts.
- Do not publish more than one primary post in a day unless account evidence supports it and the
  second item is materially different.
- Keep app-led content near 15% of output. The Page should remain useful to readers who never
  download the app.
- Avoid repeating the same topic, opening hook or format on consecutive days.

## Daily Automation

At 09:00 Europe/London:

1. Read `PublishingStatus.md`, `PerformanceLearningLog.md`, this runbook and the relevant content
   pack.
2. Confirm the previous scheduled item moved to Published and record its live URL, actual time,
   format and initial metrics.
3. Compare the Meta Planner with the Content Library. Treat Planner/Library disagreement as a
   publishing risk and resolve it before relying on the queue.
4. Check today's item for correct account, public visibility, date, time, caption, cover, media,
   links and absence of accidental paid promotion.
5. If today's item is missing, select or create a replacement that passes the content and rights
   gates below, then schedule it for the appropriate daily slot.
6. Maintain at least seven future days in the queue. Use existing verified assets before creating
   new ones.
7. Inspect comments and messages. Routine acknowledgements and verified factual answers may be
   posted automatically; sensitive or ambiguous replies must be drafted for review.
8. Append the actions and evidence to `PerformanceLearningLog.md`, update `PublishingStatus.md`,
   and write the native checkpoint values to `GrowthEvidence.json`. Preserve unavailable fields as
   `null`; never convert missing data to zero.
9. Run `python3 scripts/growth_scorecard.py Marketing/Social/CommunityPush/GrowthEvidence.json
   --output Marketing/Social/CommunityPush/GrowthScorecard.md` from the repository root. The daily
   marketing control plane ingests this versioned ledger read-only, and the Monday job includes it
   in the cross-product experiment inventory.
10. Report publishing failures, rights concerns, sensitive replies or a queue shorter than three
    days. Routine successful runs need only a concise status.

## Content Gate

Every automatically published item must:

1. Fit the editorial mix and a repeatable series in `TikTokEditorialStrategy.md` or
   `IntensiveCampaign.md`.
2. Identify a useful reader outcome, question or recommendation in the opening frame or sentence.
3. Verify title, author, edition, publication status and factual claims against credible sources.
4. State honestly whether a recommendation is based on direct reading, credible research or
   community interest.
5. Avoid implying sponsorship, publisher approval or personal reading that did not occur.
6. Use restrained hashtags and remain useful without them.
7. Pass a complete phone-sized visual review with no clipped text, blank frames or misplaced
   annotations.

## Rights Gate

Every visual must have a recorded basis for use:

- original BookQuotes artwork, screenshots or photographs;
- a BookQuotes-created Remotion or tldraw-derived composition;
- publisher publicity material used under stated terms or permission;
- a limited book-cover reproduction that is necessary and proportionate to genuine review or
  recommendation commentary;
- typography-led material that does not reproduce protected artwork.

Do not take marketing images from retailer listings. Keep quotations short, attributed and
necessary to commentary. If the source or permission basis is unclear, use a typography-led
replacement or stop for review.

## Preflight

Before scheduling or publishing, verify:

- the BookQuotes Page is the active identity;
- visibility is Public;
- the intended date and Europe/London time are correct;
- the asset opens and contains no platform watermark;
- the cover frame communicates the topic immediately;
- all text fits inside mobile safe areas;
- links open to the intended destination;
- no AI label, location, tag, paid boost or cross-post was enabled accidentally;
- the post is not a duplicate of anything published or queued in the previous 30 days.

## Failure Handling

- If a scheduled item does not publish, retry once after confirming the network, account and
  asset.
- If retrying would miss the intended moment by more than two hours, move it to the next suitable
  slot and use a verified evergreen replacement where available.
- Never publish the same item twice to compensate for uncertain status. Confirm Published first.
- Do not silently delete or hide a live post.
- Log the observed failure, attempted recovery and final state.

## Learning Loop

Measure downstream value rather than raw views:

- saves, shares and meaningful comments;
- non-follower reach;
- Reel watch time and completion;
- profile visits, follows and link clicks;
- recurring reader language;
- App Store signals on product-led posts.

Change one major variable at a time where practical. Require repeated evidence before materially
changing cadence or editorial mix.

## Current Operational Note

On 28 July 2026, the Facebook Planner displayed content on 28, 29 and 30 July and 1 August, while
the Content Library's Scheduled tab displayed no scheduled posts. The Planner entries contain real
post content, but the next automation run must reconcile this disagreement before treating the
future queue as guaranteed.
