# BookQuotes TikTok Operating Runbook

Updated: 11 September 2026

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
- Category Reel `cr-01` went out early on 18 August as a silent illustrated extra
  (`7675397855864604694`). Owner chose no voiceover and no baked music. That post
  sits beside the calendar: keep the 19:30 establishment slot and the 19–25 August
  week on their dated rows. Do not re-upload the live cr-01 file. Do not post a
  second TikTok on 18 August. The rejected Remotion placeholder set stays unpublished.

### Publishing integrity hold: 19 August 2026, 09:08 Europe/London

- Native Recent posts and the latest Zernio sync show the Player of Games caption twice on 18
  August: `7675397759196957954` and `7675398121542929667`. The second row is a duplicate upload,
  not a second creative treatment.
- Team of Rivals `7675422232285433110` was an owner-requested extra format test and is not the
  dated 20 August slot. Its native and Zernio view counts differ slightly; preserve both reads.
- Routine TikTok publishing is temporarily held after this audit. Do not upload `cr-01` again,
  do not delete either duplicate automatically, and do not advance `cr-03` until the single-writer
  path, duplicate guard and native/Zernio reconciliation are verified.
- The 19:30 establishment slot and the 60/20/15/5 mix remain the intended operating baseline once
  the hold clears. The second daily slot remains disabled until seven comparable non-duplicated
  posts have data.

### Metadata reconciliation hold: 25 August 2026, 09:02 Europe/London

- The direct Stoner submit failed on TikTok capacity. The Creator Inbox fallback became Public as
  content ID `7677590432297127200`, but its caption reads `#Zernio` rather than the intended Stoner
  recommendation. The intended Inbox ID `7677574869307672598` is not present in the synced
  analytics inventory.
- This is a publishing-integrity and attribution failure. Do not treat the 247 views / 1 like as a
  Stoner creative result. Do not delete, edit, re-upload or schedule a second copy automatically.
- Keep the single-writer, duplicate and second-slot holds active. Further TikTok publishing may
  resume only after one controlled path produces the intended caption, cover, audience and a single
  attributable public content ID with analytics read-back.

### Metadata reconciliation hold: 26 August 2026, 09:01 Europe/London

- The 25 August two-front-doors pairing did not appear under its intended Inbox
  ID `7677955167269996566`. The live inventory instead contains
  `7678034754557529376` with caption `#Zernio`, 231 views, 0 likes and 0
  comments.
- Treat this as a continuation of the publishing-integrity failure, not as a
  creative result. The *Tinker Tailor* Inbox draft
  `7677958495261493270` has no live analytics row.
- Keep the single-writer, duplicate and second-slot holds active. Do not
  delete, edit, re-upload, schedule or publish another TikTok copy
  automatically. Manual recovery of public rows remains user-approved work.

### Metadata reconciliation audit: 7 September 2026, 19:26 Europe/London

- The account is active as `@bookquotes.app` with 16 public rows, 3 followers and analytics access.
  The latest analytics sync is `2026-09-07T18:37:56Z`; token health is currently `ok` through
  `2026-09-08T10:12:40Z` (11:12 Europe/London). Reconnect is expected to become due before the
  next morning audit.
- The latest public rows are 2 September `7680815050273197334` at 202 views / 1 like / 0 comments,
  31 August `7680189027781299478` at 203 / 1 / 0, and 27 August `7678826123786063137` at
  226 / 1 / 0. The first two read back as `#Zernio`; the 27 August row has an empty caption.
  These are metadata and attribution observations, not clean creative treatments.
- The 27 August shelf post also has a failed job record (`6a9089ac6947ad1a8cdfc652`) with the
  intended reader caption. Do not retry it while native and Zernio state remain unresolved.
- Keep the single-writer, duplicate, metadata and second-slot holds active. Do not upload, schedule,
  edit, delete or re-upload another TikTok copy automatically. The general routine authority above
  is superseded by this active hold.

### Metadata reconciliation audit: 9 September 2026, 08:01 Europe/London

- The account is active as `@bookquotes.app` with analytics access, 18 public rows, 4 followers and
  a latest analytics sync at `2026-09-09T07:28:24.190Z`. The failed-post list is empty, but the
  token expires at `2026-09-09T09:09:02.813Z`; the reconnect path remains due.
- Two new public rows from 8 September are now visible: `7683146385834708246` at 697 views / 6
  likes / 0 comments with caption `The incredible Carlo Rovelli books`, and
  `7683196200740244758` at 237 / 1 / 0 with caption `Those that are Outliers`.
- The Outliers row has a corresponding local September physical-book footage brief, but native
  cover, audio and audience metadata were not read back. Carlo Rovelli has no matching current
  project source or Evidence Ledger entry, so its recommendation and rights basis are not verified.
  The rows are publishing-integrity observations only and must not be scored as clean creative
  executions.
- The ordinary captions are a healthier signal than `#Zernio` or an empty caption, but they do not
  clear the single-writer, duplicate or metadata hold. Do not upload, schedule, edit, delete or
  re-upload another TikTok copy automatically. The second daily slot remains disabled.

### Metadata reconciliation audit: 11 September 2026, 08:00 Europe/London

- The account is active as `@bookquotes.app` with 22 public rows, 7 followers and analytics access.
  The latest sync is `2026-09-11T07:54:17.284Z`; the failed-post list is empty. The token expires at
  `2026-09-11T08:56:09.515Z`; `reconnect --if-expiring` opened the OAuth flow and returned
  `expiring_soon`, but completion is not yet verified.
- A new public row `7683942886928436502` was published on 10 September at 16:22:55Z with caption
  `Freak!`, 250 views, 0 likes and 0 comments. It has no matching current brief, source or Evidence
  Ledger entry. Treat it as a publishing-integrity observation, not a creative result.
- TikTok's [Creative Centre guidance](https://ads.tiktok.com/resources/help/article/creative-center?lang=en-GB)
  confirms the public Trends and Inspiration surfaces, but the live GB Top Ads view returned no
  public results without a signed-in session. Direct creator-profile sampling was blocked by robots.
  The official UK [BookTok Bestsellers update](https://newsroom.tiktok.com/tiktok-reveals-july-2026s-booktok-bestsellers-uk?lang=en-GB)
  is recorded as platform context only; `EXT-013` captures the transferable reader-fit/list-context
  pattern without claiming BookQuotes performance.
- The single-writer, duplicate, metadata and second-slot holds remain active. Do not upload, edit,
  delete, re-upload or schedule another TikTok copy automatically until the intended caption, cover,
  audio, audience, rights basis and attributable content ID are reconciled. No confidence or result
  label changed.

### Metadata reconciliation audit: 10 September 2026, 08:05 Europe/London

- The account is active as `@bookquotes.app` with 21 public rows, 6 followers and analytics access.
  The latest sync is `2026-09-10T08:56:10.286Z`; token health is `ok` through
  `2026-09-11T08:56:09.515Z`; the failed-post list is empty.
- Three additional public rows from 9 September are visible: `7683456621573328150` (`BAD BLOOD`)
  at 246 views / 1 like / 0 comments, `7683457013363281174` with an empty caption at 677 / 4 / 2,
  and `7683552415836163350` (`SPACE`) at 234 / 2 / 0. The 8 September rows have reached their
  24-hour read: Carlo Rovelli `7683146385834708246` at 697 / 6 / 0 and Outliers
  `7683196200740244758` at 237 / 1 / 0.
- `BAD BLOOD` matches a local physical-footage label, but native metadata and evidence are not
  reconciled. `SPACE` has no matching current evidence record. Carlo Rovelli has no current source
  or Evidence Ledger entry. The empty-caption row has two comments, but their text is not exposed.
- Official [TikTok Next 2026](https://ads.tiktok.com/business/en-GB/next?level=0&redirected=1&tt4b_lang_redirect=1)
  research supports a hypothesis around grounded reader situations, curiosity/search detours and
  substantive comment follow-ups. It is a platform forecast, not BookQuotes account evidence;
  `EXT-012` records it in the style catalogue without a performance claim.
- The single-writer, duplicate, metadata and second-slot holds remain active. Do not upload, edit,
  delete, re-upload or schedule another TikTok copy automatically until the intended caption, cover,
  audio, audience, rights basis and attributable content ID are reconciled. No confidence or result
  label changed.

### Audit: 20 August 2026, 09:04 Europe/London

- Zernio now reports active `@bookquotes.app`, analytics access true, latest sync at
  `2026-08-20T07:39:12Z`, and token health `ok` through `2026-08-21T06:07:17Z`.
- The hold is unchanged. Current later reads are Player of Games intended 687 views / 1 like,
  same-caption duplicate 239 / 1, Team of Rivals 683 / 0, and Commonplace Ritual 859 / 2; all
  comments are 0 and deeper retention or downstream measures are unavailable.
- No new TikTok post was uploaded. Do not advance `cr-03` or enable the second slot until the
  single-writer path, duplicate guard and native/Zernio reconciliation are evidenced.

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
