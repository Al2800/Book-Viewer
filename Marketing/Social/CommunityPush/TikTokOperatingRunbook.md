# BookQuotes TikTok Operating Runbook

Updated: 18 August 2026

## Purpose

Run TikTok as an evidence-led editorial channel for readers. Automation should increase the
quality and consistency of research, production and learning. It must not manufacture personal
experience, imitate creators, conceal uncertainty or publish weak material merely to fill a slot.

Read this file together with:

- `TikTokEditorialStrategy.md`
- `TikTokStyleCatalogue.md`
- `TikTokEvidenceLedger.md`
- `TikTokExperimentRegister.md`
- `TikTokResearchLog.md`
- `TikTokLaunchPack.md`

## Current Authority

The daily research, briefing, quality-control and learning stages may run automatically.

These stages are active in the `bookquotes-daily-social-check` automation at 09:00
Europe/London. After the native gate was cleared on 18 August, the automation may advance the
next eligible TikTok item for the 19:30 Europe/London establishment slot. Token health is
`uk.bookquotes.tiktok-reconnect` at 09:05 (`reconnect --if-expiring`). Facebook is a separate
Graph queue at 13:00.

The user has authorised routine automatic TikTok publishing once the native validation below
passes. The automation may record that activation without seeking another approval when every
validation item is evidenced.

Before 18 August, TikTok publishing was approval-only until all of the following had been verified:

1. `@bookquotes.app` has the required Business Suite or Advanced Access.
2. A private or low-risk test has been scheduled through TikTok's native scheduler.
3. The scheduled item appears in the native content calendar with the correct local time.
4. It publishes once, without duplication, with the intended cover, caption, audience and audio.
5. The post has an addressable analytics entry attributable to the correct content ID. The
   measurements may continue to mature through the 24-hour checkpoint.

The gate is now recorded as satisfied for routine organic publishing. The controlled marked-page
post is Public and appears once in the native content library, and the 17 August Commonplace Reel
has a native addressable content ID with 855 views, 2 likes and 0 comments. The Account Check URL
resolved to the signed-in Studio surface with no visible warning or restriction text; TikTok did
not expose a formal account-health report, so that limitation remains recorded. Paid promotion,
partnerships, rights-uncertain material and sensitive community responses remain approval-only.

### Validation Evidence, 17 August 2026

- Scheduled item: `bookquotes-marked-page.mp4`
- TikTok content ID: `7667570006032387350`
- Published: 28 July 2026 at 19:30 Europe/London, Public
- Zernio account `6a7e30f977555aae0187cea3` / `@bookquotes.app` is active, with
  `video.publish` and `hasAnalyticsAccess`
- Five older native videos still read 0 in Zernio. The 17 August Commonplace retry now
  has distribution: native content ID `7674952452055076118`, public permalink and a native
  read-back of 855 views, 2 likes and 0 comments. Deeper reach, watch, save, share, profile and
  follow fields remain unavailable in the Content view.
- The 14 August Zernio Commonplace attempt `6a7f031b2fc86999e9e30916` failed on TikTok
  daily quota and created no content ID. Do not reuse that job.
- Token expiry is `2026-08-18T11:55:56Z`. `uk.bookquotes.tiktok-reconnect` at 09:05
  opens OAuth only when fewer than 6 hours remain. Manual:
  `python3 /Users/skyhub/bookquotes-marketing-os/bin/meta_cli.py reconnect --channel tiktok`.
  Routine automatic publishing is active for the establishment phase: one primary post daily at
  19:30 Europe/London, with no second slot until seven comparable posts are available. Bank
  typography PNGs are not TikTok-ready.

### Routine activation: 18 August 2026, 09:01 Europe/London

- Native Recent posts lists the controlled ID `7667570006032387350` once as Public and lists the
  new Commonplace Reel `7674952452055076118` once as Public with an addressable URL and native
  metrics of 855 views, 2 likes and 0 comments.
- This satisfies the publication-once, no-duplication and attributable-analytics requirements for
  routine organic publishing. The account-health route did not expose a formal report, but the
  signed-in Studio surface showed no visible warning or restriction text.
- Establishment phase is active. Publish one strong reader-first post daily at 19:30, keep the
  60/20/15/5 mix, and do not test a second daily slot until seven comparable posts have data.
- The next eligible prepared item is Category Reel `cr-01` (Player of Games) on 19 August. No
  additional TikTok item is scheduled for 18 August by this audit.

## Editorial Principles

- Provide value to a reader before mentioning the app.
- State what is known, how it is known and where uncertainty remains.
- Use specific reader needs rather than generic praise.
- Include an honest reservation when it improves expectation-setting.
- Prefer original book photography, original commentary and BookQuotes-owned design.
- Learn from the structure of other creators' work without copying their language, visual identity
  or distinctive execution.
- Treat trends as possible packaging, not as the editorial strategy.

## Operating Cadence

### Daily

1. Check publishing status, TikTok token health, and account health.
2. Advance `CategoryReelPipeline.json` for today's category. The 13:00 bank still is a
   different post; do not treat the PNG as the TikTok Reel.
3. Collect current UK reader and BookTok signals only when they change a brief.
4. Review recent comments, searches and audience language.
5. Add only relevant signals to `TikTokResearchLog.md`.
6. Convert the strongest unused signal into the next empty rotation row, not a
   same-day second Reel.
7. Verify evidence and rights before production. Faceless Remotion or owned book
   objects only.
8. Maintain three to five `draft` or `ready` category briefs.
9. Measure posts at the next available 24-hour and 72-hour checkpoints.

## Publishing Ramp After Validation

### Establishment Phase

For the first seven successfully published posts:

- publish one primary post daily;
- use 19:30 Europe/London as the default baseline slot;
- introduce a midday slot only as a controlled timing experiment;
- keep the editorial mix close to 60% recommendations, 20% reader culture, 15% product proof and
  5% company updates over the rolling period;
- do not allow consecutive product-led posts.

### Expansion Phase

After at least seven posts have comparable data:

- retain one strong daily post as the baseline;
- test a second post on no more than two days in the following week;
- separate the second post by at least six hours and give it a distinct reader purpose;
- retain twice-daily publishing only when the second slot improves saves, meaningful comments,
  follows or profile activity without weakening the primary slot;
- return to one daily post when quality, rights clearance or topic distinctness deteriorates.

### Monday

Run a seven-day review:

- compare like-for-like formats and content territories;
- update rolling medians and experiment confidence;
- select what to repeat, modify and pause;
- check genre, author, demographic, hook and format concentration;
- approve the next week's 70/20/10 portfolio;
- record one to three decisions, rather than rewriting the strategy around every result.

### Monthly

Review the editorial mix, audience direction, series catalogue, production burden, rights process
and relationship between TikTok activity and App Store signals.

## Research Protocol

Use a balanced source set:

- TikTok Creative Center trends for the United Kingdom;
- TikTok Creative Hub where account access permits;
- relevant TikTok searches and BookTok conversations;
- approximately 15 to 20 useful posts across large, medium and smaller creator accounts;
- current publisher, author and reputable review sources for factual verification;
- BookQuotes comments, searches and product feedback.

For each external example, capture the pattern rather than the content:

- creator and link;
- observation date;
- audience need;
- first-frame promise;
- narrative structure;
- visual and audio treatment;
- interaction being invited;
- visible downstream response;
- transferable principle;
- elements that must not be copied.

Reject a trend when its audience relevance, BookQuotes interpretation, expected shelf life or
rights position is weak.

Treat creator revenue claims, screenshots and exceptional view counts as leads rather than proof.
Record the missing denominator, commercial incentive and selection bias. A proposed format still
has to succeed in controlled BookQuotes tests.

Never buy or operate warmed accounts, spoof location, conceal the account's operating region,
automate likes or comments, or create multiple accounts to manufacture distribution. These tactics
undermine account integrity and produce unreliable audience evidence.

## Brief Requirements

Every production brief must include:

- experiment ID;
- intended reader;
- reader need or tension;
- one-sentence hypothesis;
- content territory and named style ID;
- hook and narrative progression;
- evidence ledger IDs;
- rights status;
- primary and secondary measures;
- the single main variable being tested;
- planned review dates.

## Evidence And Rights Gate

A post cannot enter production until:

1. Titles, authors, editions, dates and material claims are verified.
2. The recommendation stance is marked as `Read`, `Researched` or `Community signal`.
3. The script uses language permitted by that stance.
4. Visual, cover, quotation and audio rights are recorded.
5. Unresolved facts are removed or clearly qualified.

Never imply firsthand reading from research alone. Never download retailer cover images for
marketing use. Keep quotations short, necessary and subordinate to commentary.

## Anti-Slop Gate

Reject or rewrite content when any answer is yes:

- Could the wording apply unchanged to dozens of other books?
- Does it rely on unsupported superlatives or phrases such as `must-read`, `hidden gem`,
  `you need this` or `will change your life`?
- Is the post mainly plot summary?
- Does it pretend to have read or felt something?
- Is the controversy manufactured?
- Is the app inserted without serving the reader's problem?
- Does it repeat a recent hook, sentence shape or list structure?
- Does animation decorate the screen without clarifying the idea?
- Would a serious reader have no reason to save, share or discuss it without the product?

## Quality Score

Score every finished item before approval:

| Dimension | Weight |
| --- | ---: |
| Reader usefulness and specificity | 25 |
| Evidence and trustworthiness | 20 |
| Original BookQuotes perspective | 15 |
| Opening clarity | 15 |
| Visual execution | 10 |
| Community-response potential | 10 |
| Product relevance | 5 |

The minimum score is 75. Evidence, rights and honest-framing failures are absolute blockers even
when the total exceeds 75.

## Production And Preflight

1. Render 1080 x 1920 without a platform watermark.
2. Keep essential text and faces inside TikTok-safe areas.
3. Make the reader proposition understandable in the first two seconds.
4. Check every slide and frame at phone size.
5. Verify that drawn marks point to real content and finish in the intended position.
6. Review with sound on and off.
7. Check cover crop, caption, hashtags, audience, comments, Duet, Stitch and AI label.
8. Use only audio cleared for the account and intended commercial context.
9. Search the prior 30 days for duplicate topics, books, hooks and structures.
10. Record the final quality score and approval status.

## Measurement

Record at approximately 24 hours, 72 hours and seven days:

- views and unique reach where available;
- average watch time and completion;
- two-second and six-second hold where available;
- saves and shares per 1,000 views;
- meaningful comments per 1,000 views;
- profile visits, follows and link taps;
- search terms and recurring reader language;
- App Store signals for product-led posts.

Use `Not available` when TikTok does not expose a measure. Do not convert missing data to zero.

## Decision Rules

- Compare a post with the rolling median for its own format and territory.
- Treat fewer than three comparable posts as directional evidence.
- Mark a result `Promising` when two valuable measures beat the appropriate baseline.
- Mark `Packaging failure` when the subject attracts useful response but opening or retention is
  weak.
- Mark `Topic failure` only when the proposition was clearly delivered and repeated evidence is
  weak.
- Mark `Winner` after the result repeats across at least two executions.
- Change experiment confidence one level at a time unless there is a rights, safety or publishing
  failure.

## Failure Handling

- Never retry a post when native status is uncertain.
- Confirm whether a content ID exists before uploading again.
- A failed factual, rights or quality gate returns the item to research or drafting.
- A scheduler failure may be retried once only after confirming that no duplicate exists.
- Record failures and corrective action in `TikTokResearchLog.md`.

## Authoritative Platform References

- TikTok Creative Center: https://ads.tiktok.com/help/article/creative-center
- TikTok Trends: https://ads.tiktok.com/help/article/how-to-use-trends
- TikTok Web Business Suite: https://ads.tiktok.com/help/article/navigate-web-business-suite
- TikTok account entitlements:
  https://ads.tiktok.com/help/article/about-tiktok-account-entitlements
- TikTok account integration:
  https://ads.tiktok.com/help/article/business-account-integration-with-business-center
- TikTok Organic Playbook: https://ads.tiktok.com/business/library/Organic_Playbook.pdf
