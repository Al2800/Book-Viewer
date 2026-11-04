# BookQuotes Automated Social Publishing Runbook

Updated: 4 November 2026, 09:05 Europe/London

## Current Operational Note — 4 November 2026, 09:05 Europe/London

The 3 November Facebook post `122121333891415831` published once at Graph
`created_time=2026-11-03T13:00:31+0000`, at
`https://www.facebook.com/122107379391415831/posts/122121333891415831`. It repeated the
7 October reading-note topic identified in the previous audit. The local edit policy remains
`writes_enabled=false`; no safe correction or cancellation was possible before publication. Today's
4 November post `122121333921415831` remains scheduled for 13:00 GMT. The read-only
`scheduled_posts` edge now confirms seven Page-authored daily rows for 4-10 November, all with
`privacy.value=EVERYONE` (Public). A new original text-only prompt, `122122166019415831`, was
scheduled once for 10 November at 12:30 Europe/London and read back as Public. The 9 November
approved `bq14-13` photo card remains the only app-led/visual item in the seven-day window (14.3%);
the 4-8 November sequence is five consecutive text prompts and still fails the format-variety guard.
The write lock prevents rearranging existing scheduled rows. The new text post has no media or link;
no boost, tag, location or cross-post field was supplied. The schedule API does not expose native
AI-label controls. Facebook metrics remain null: post/comments reads return HTTP 400 (`#12`) and
insights return `#100` invalid metric. The scorecard generator validated the evidence file but
rendered all-null aggregate metrics as zero and labeled unavailable post rows as insufficient
distribution; the generated view was corrected to Not available. The underlying observations remain
null. Preserve this correction until the generator's null handling is fixed.

TikTok account `@bookquotes.app` is active, with 20 returned API records, 5 followers and analytics
access. Token expiry is `2026-11-04T21:10:06.573Z`; reconnect flags are false. Controlled ID
`7667570006032387350` remains absent from the connected inventory and has no attributable analytics,
so the later publishing-integrity, duplicate, native-metadata, evidence and second-slot holds remain
active. No TikTok mutation or reply was made. The newest connected public row remains the 12
September `Gladwell` post (3 views, reach 3, 1 save, 0 shares/comments), outside the review window.
Native Account Check and comment/message text remain unavailable; failed Creator Inbox request
`6aa4f018662ee2d345bceb39` is unresolved.

The TikTok preparation queue remains below three viable items: `cr-03` and `cr-04` frame sampling
still fails with AVFoundation `Cannot Decode`, and no third validated brief is ready. The official GB
Creative Center is login-gated. Three linked creator profiles (approximately 2.3k, 12.6k and 18.2k
followers) failed to return readable posts, so a representative 15-20-post sample remains
unavailable. TikTok's 26 October September-bestsellers report and an October seasonal BookTok report
were logged as context only; no style, evidence-led content brief or confidence change is justified.

### Previous operational note — 3 November 2026, 09:00 Europe/London

The 2 November Facebook item `122121072519415831` is confirmed published once by the BookQuotes
Page at Graph `created_time=2026-11-02T13:00:03+0000`; its permalink is
`https://www.facebook.com/122107379391415831/posts/122121072519415831`. The read-only
`scheduled_posts` reconciliation at approximately 08:55 confirms seven one-per-day Page-authored
items for 3-9 November. Today's `122121333891415831` remains scheduled for 13:00 GMT, but its
reading-note topic overlaps 7 October. The local edit policy still has `writes_enabled=false`; do
not bypass it or create a competing replacement. The row requires manual correction or cancellation
in Meta Planner before publication. The scheduled edge does not expose per-post audience visibility,
so Public status cannot be independently confirmed from this API read. Facebook insights fail with
HTTP 400 (`#100`, invalid metric), post `get` fails with `#12` (deprecated singular statuses API),
and the comments permission/read remains unavailable (`#10`); metrics remain null. The count is seven,
but the 3-8 November rows are six consecutive text-only prompts, with only the approved `bq14-13`
photo card on 9 November (one app-led item in seven, 14.3%). The current queue therefore fails the
consecutive-format variety guard as well as today's duplicate-topic gate; no automated correction
can run while the local write policy is disabled.

TikTok account `@bookquotes.app` is active with 20 returned API records, 5 followers and analytics
access; the token is healthy through `2026-11-03T19:47:26.637Z` and does not require reconnection.
The controlled ID `7667570006032387350` is absent from the current connected inventory. Earlier
native Studio evidence recorded it once as Public, but no attributable analytics entry is available,
so that read does not clear later publishing-integrity holds. The latest connected public row is the
12 September `Gladwell` post (3 views, reach 3, 1 save, 0 shares/comments). Native Account Check and
comment/message text remain unavailable; failed request `6aa4f018662ee2d345bceb39` remains unresolved.
No TikTok publishing, editing, deletion or automatic reply was made.

The TikTok preparation queue remains below three viable items. Frame sampling of the existing
`cr-03` and `cr-04` MP4s failed at every sampled point with AVFoundation `Cannot Decode`; their cover
PNGs can be viewed, but the required muted, frame-level and phone-size checks cannot be completed.
The separate rejected Remotion placeholder cuts remain ineligible. The official UK Creative Center
shows a login shell and its hashtag-list route returns 501; direct creator pages remain inaccessible.
No representative 15-20-post creator sample, style change, new brief or confidence change is
justified. One contextual UK BookTok signal and one seasonal-media signal are logged in
`TikTokResearchLog.md`; neither clears a production or publishing gate.

### Previous operational note — 2 November 2026, 09:49 Europe/London

The 1 November Facebook prompt `122120952153415831` remains confirmed published once at Graph
`created_time=2026-11-01T13:00:10+0000`. Today's `122121072519415831` is still scheduled for
13:00 GMT and is not yet due at this audit. A direct read-only `scheduled_posts` reconciliation
returns exactly eight one-per-day Page-authored rows for 2-9 November, with the BookQuotes identity
confirmed; the API still does not expose an explicit per-post audience field. The 8 November text
prompt and the approved `bq14-13` card on 9 November remain read back once. `bq14-13`'s approved
1080x1920 asset hash still matches `d6d9368f8587894fa875f3ebb1f6258f34178baa011fe1d6faa5e7aae267b99c`.
The 3 November reading-note prompt still overlaps the 7 October topic and requires manual correction
or cancellation because the safe edit/delete path is unavailable. No Facebook mutation was made.
Facebook comments still return `#10` and insights return an invalid-query error; metrics remain null.
The latest Instagram media comments read returns an empty list.

TikTok remains active as `@bookquotes.app` with 20 API post records, 5 followers and analytics access.
Token health is `ok`, reconnect flags are false, and expiry is `2026-11-02T18:32:49.325Z` (about
8.7 hours remaining at the read). No new public row appeared; the latest public row remains the
12 September item with 3 views, 3 reach and 1 save, retained as an integrity observation only. Native
Account Check and comment/message text remain unavailable, the failed Creator Inbox request
`6aa4f018662ee2d345bceb39` remains unresolved, and all publishing-integrity, duplicate, native
metadata, evidence and second-slot holds remain active. The preparation queue remains below three
viable items: `cr-03` and `cr-04` still need full frame-level and phone-size preflight, with no third
validated item. The UK Creative Center page remains login-gated in the available read, so no current
15-20-post sample or new style evidence was added. No TikTok mutation or automatic reply was made.

## Current Operational Note — 2 November 2026, 05:39 Europe/London

The 1 November Facebook prompt `122120952153415831` is confirmed published once at Graph
`created_time=2026-11-01T13:00:10+0000`; its permalink is
`https://www.facebook.com/122107379391415831/posts/122120952153415831`. Today's 2 November prompt
`122121072519415831` remains scheduled for 13:00 GMT and is not yet due at this audit time. The direct
scheduled edge now contains eight one-per-day rows for 2-9 November. The new 8 November text prompt
`122121855219415831` was scheduled for 12:30 GMT and read back. The approved `bq14-13` reader-practice
card was scheduled once for 9 November at 12:30 GMT as a low-risk product-led item to bring the
upcoming mix near 15%; the publish CLI returned no read-back, but the read-only scheduled edge confirms
exactly one Page-authored row `122121867855415831`, `is_published=false`. No duplicate retry was made.
The 3 November reading-note prompt `122121333891415831` still duplicates the 7 October topic and
requires manual correction or cancellation because the safe edit/delete path is unavailable. The
scheduled edge confirms the BookQuotes Page identity but does not return an explicit audience field.
Facebook post insights are unavailable (`#100`, invalid metric); the post `get` edge returns `#12`,
and the comments edge returns `#10` because `pages_read_user_content` or Page Public Content Access
is not granted. Instagram remains at 19 media rows, latest 30 August; latest media comments are empty.

TikTok remains active as `@bookquotes.app` / `6a7e30f977555aae0187cea3`, with 20 API post records,
5 followers and analytics access. Token health is `ok`, both reconnect flags are false, and expiry is
`2026-11-02T18:32:49.325Z` (about 12.9 hours remaining). No new public post appeared in 26 October-1
November. The latest public row remains the 12 September item with 3 views, 3 reach and 1 save; it is
retained as a publishing-integrity observation, not a current creative result. TikTok comments/messages
and native Account Check are not readable through the available API. The failed Creator Inbox request
`6aa4f018662ee2d345bceb39` remains unresolved. Publishing-integrity, duplicate, native metadata,
evidence and second-slot holds remain active; no TikTok mutation or automatic reply was made. The
preparation queue is below three viable items: `cr-03` and `cr-04` are still marked
`needs_illustrated_cut` despite MP4/cover files existing, and require full frame-level and phone-size
preflight; no third validated item is ready. The UK Creative Center route returned a 501 for its
hashtag-list request; direct TikTok creator pages were blocked, so no representative 15-20-post sample
or new style claim was available. No hypothesis confidence changed.

## Current Operational Note — 31 October 2026, 09:07 Europe/London

The 30 October Facebook prompt `122120616441415831` and today's 31 October prompt
`122120791377415831` are confirmed published once. Graph read-back shows `created_time=2026-10-31T12:00:01+0000`
for today's item at `https://www.facebook.com/122107379391415831/posts/122120791377415831`. The rolling
Facebook queue now contains exactly seven future Public, text-only rows for 1-7 November:
`122120952153415831` (1 November), `122121072519415831` (2 November), `122121333891415831`
(3 November), `122121333921415831` (4 November), `122121462009415831` (5 November),
`122121633429415831` (6 November) and `122121633693415831` (7 November). The 6 November and
7 November prompts were each preflighted, approved, scheduled and read back for 13:00 Europe/London.
The 3 November hook still overlaps the 7 October reading-note prompt and requires manual correction or
cancellation before publication; the configured update path remains disabled. Meta identity and
permissions remain verified for Page `1246405755221229` and connected Instagram `bookquotes.app`
(`17841434821362428`). Instagram remains at 19 media rows with latest publication 30 August; no
Instagram write or reply was made. Facebook post insights and latest-post comments remain unavailable
because both Graph reads return HTTP 400 (`#12`, singular statuses API deprecated).

TikTok is active as `@bookquotes.app` with 20 post records returned, 5 followers and analytics access.
Token health reports `status=ok`, `reconnect_required=false`, `needs_reconnection=false`, and expiry
`2026-10-31T17:25:17.352Z` (about 8.3 hours remaining). No new public row or attributable analytics
entry appeared; the latest public row remains the 12 September Gladwell item (3 views, 3 reach, 1 save),
retained as an integrity observation. The failed Creator Inbox request `6aa4f018662ee2d345bceb39`
remains failed. Publishing-integrity, duplicate, native metadata, evidence and second-slot mutation
holds remain active; no TikTok mutation or automatic reply was made. The preparation queue remains below
the required three viable items because `cr-03` and `cr-04` still need illustrated cuts. The official
Creative Centre route remains login-gated and no representative current UK sample was available. No
weak replacement was manufactured.

## Current Operational Note — 30 October 2026, 08:58 Europe/London

The 29 October Facebook prompt `122120437803415831` is confirmed published once; Graph read-back
shows `created_time=2026-10-29T12:00:30+0000` at
`https://www.facebook.com/122107379391415831/posts/122120437803415831`. The rolling Facebook queue
has been extended and read back with exactly seven Public, text-only rows for 30 October-5 November:
`122120616441415831` (30 October), `122120791377415831` (31 October), `122120952153415831`
(1 November), `122121072519415831` (2 November), `122121333891415831` (3 November),
`122121333921415831` (4 November) and `122121462009415831` (5 November). The new 5 November row
was preflighted, approved, scheduled and read back for 13:00 Europe/London. The pre-existing 30-31
October rows are scheduled at 12:00 UTC, which is 12:00 GMT and 30 minutes earlier than the normal
12:30 text slot; no reschedule mutation was attempted because the CLI has no safe edit/delete path.
The 3 November hook overlaps the 7 October reading-note prompt and requires manual correction or
cancellation before publication; the configured update path remains disabled. Meta identity and
permissions remain verified for Page `1246405755221229` and connected Instagram `bookquotes.app`
(`17841434821362428`). Instagram remains at 19 media rows with latest publication 30 August; the
latest media comments read returned an empty list and no Instagram write was made. Facebook post
insights and latest-post comments reads remain unavailable because both Graph reads return HTTP 400
(`#12`, singular statuses API deprecated).

TikTok is active as `@bookquotes.app` with 20 post records returned, 5 followers and analytics
access. Token health now reports `status=ok`, `reconnect_required=false`, `needs_reconnection=false`,
and expiry `2026-10-30T17:26:12.583Z` (about 8.4 hours remaining). No new public row or attributable
analytics entry appeared; the latest public row remains the 12 September Gladwell item (3 views, 3
reach, 1 save), retained as an integrity observation. The failed Creator Inbox request
`6aa4f018662ee2d345bceb39` remains failed. Publishing-integrity, duplicate, native metadata, evidence
and second-slot mutation holds remain active; no TikTok mutation or automatic reply was made. The
TikTok preparation queue remains below the required three viable items: `cr-03` and `cr-04` still
need illustrated cuts, while `cr-01`, `cr-02` and `cr-05`-`cr-07` are already live or held. The
official Creative Centre trends route is login-gated, and public creator-profile pages yielded no
readable posts; no representative 15-20-post sample or new UK style evidence was available. No weak
replacement was manufactured.

## Current Operational Note — 29 October 2026, 09:01 Europe/London

The 28 October Facebook prompt `122120300115415831` is confirmed published once; Graph
read-back shows `created_time=2026-10-28T12:00:02+0000` at
`https://www.facebook.com/122107379391415831/posts/122120300115415831`. The rolling Facebook queue
has been extended and read back with exactly seven Public, text-only rows for 29 October-4 November:
`122120437803415831` (29 October), `122120616441415831` (30 October), `122120791377415831`
(31 October), `122120952153415831` (1 November), `122121072519415831` (2 November),
`122121333891415831` (3 November) and `122121333921415831` (4 November). The two new rows were
approved, scheduled and read back at 13:00 Europe/London. A post-schedule audit found that the 3
November hook overlaps the 7 October reading-note prompt; the configured update path is disabled, so
that row requires manual correction or cancellation before publication. The pre-existing 29-31 October
rows are returned by Graph at 12:00 UTC after the UK clock change; no reschedule mutation was attempted
because the CLI has no safe edit/delete path and duplicate creation would be unsafe. Meta
identity and permissions remain verified for Page `1246405755221229` and connected Instagram
`bookquotes.app` (`17841434821362428`). Instagram remains at 19 media rows with latest publication
30 August; its latest media comments read returned an empty list and no Instagram write was made.
Facebook post insights and latest-post comments reads remain unavailable because both Graph reads return
HTTP 400 (`#12`, singular statuses API deprecated).

TikTok is active as `@bookquotes.app` with 24 public rows, 5 followers and analytics access. The
account read reports token `expires_at=2026-10-29T14:33:41.900Z`, `reconnect_required=true`,
`needs_reconnection=false`, `status=expiring_soon` and approximately 5.5 hours remaining. An OAuth
reconnect flow was opened in Brave, but authorization is not complete and requires the user to finish
the TikTok authorization in that browser tab. No new public row or attributable analytics entry
appeared. Keep publishing-integrity, duplicate, native metadata, evidence, reconnect and second-slot
mutation holds active; no TikTok mutation or automatic reply was made. The TikTok preparation queue
remains below the required three viable items: `cr-03` and `cr-04` still need illustrated cuts, while
`cr-01`, `cr-02` and `cr-05`-`cr-07` are already live or held and must not be re-uploaded. The
official Creative Centre trends route is login-gated and exposed no usable current UK sample, so no
new style or evidence change was warranted. No weak replacement was manufactured.

## Current Operational Note — 27 October 2026, 09:15 Europe/London

The 26 October Facebook prompt `122119976613415831` is confirmed published once; Graph read-back
shows `created_time=2026-10-26T12:00:06+0000` at
`https://www.facebook.com/122107379391415831/posts/122119976613415831`. The rolling Facebook queue
has been extended and read back for 27 October-2 November; the scheduled edge contains exactly seven
Public, text-only rows with no duplicate copy. The new 2 November row is
`122121072519415831`, read back at
`https://www.facebook.com/122107379391415831/posts/122121072519415831`, scheduled for 13:00
Europe/London. The pre-existing 27-31 October rows are returned by Graph at 12:00 UTC after the UK
clock change; no reschedule mutation was attempted because the CLI has no safe edit/delete path and
duplicate creation would be unsafe. Meta identity and permissions remain verified for Page
`1246405755221229` and connected Instagram `bookquotes.app` (`17841434821362428`). Instagram remains
at 19 media rows with latest publication 30 August; its latest media comments read returned an empty
list. TikTok is active as `@bookquotes.app` with 24 public rows, 5 followers and analytics access; the
account read reports token `expires_at=2026-10-27T11:14:06.569Z`, `reconnect_required=true`,
`needs_reconnection=false`, `status=expiring_soon` and approximately 1.46 hours remaining. No new
public row or attributable analytics entry appeared. TikTok mutation holds remain active because
publishing-integrity, duplicate, native metadata, evidence and reconnect controls are unresolved.
Facebook post-insights and latest-post comments reads return HTTP 400 (`#12`, singular statuses API
deprecated), so those measures remain unavailable. The current Creative Centre trends route is
login-gated and exposed no usable current UK sample, so no new external creative sample was added.
No TikTok mutation or automatic reply was attempted. The TikTok preparation queue remains below the
required three viable items: there is no release-ready future brief; `cr-03` and `cr-04` need
illustrated cuts, and already-live or held rows must not be re-uploaded. No weak replacement was
manufactured.

## Current Operational Note — 26 October 2026, 09:03 Europe/London


The 25 October Facebook prompt `122119828977415831` is confirmed published once; Graph read-back
shows `created_time=2026-10-25T12:00:18+0000` at
`https://www.facebook.com/122107379391415831/posts/122119828977415831`. The rolling Facebook queue
has been extended and read back for 26 October-1 November; the scheduled edge contains exactly seven
Public, text-only rows with no duplicate copy. The new 1 November row is
`122120952153415831`, read back at
`https://www.facebook.com/122107379391415831/posts/122120952153415831`, scheduled for 13:00
Europe/London. The pre-existing 26-31 October rows are returned by Graph at 12:00 UTC after the UK
clock change; no reschedule mutation was attempted because the CLI has no safe edit/delete path and
duplicate creation would be unsafe. Meta identity and permissions remain verified for Page
`1246405755221229` and connected Instagram `bookquotes.app` (`17841434821362428`). Instagram remains
at 19 media rows with latest publication 30 August; its latest media comments read returned an empty
list. TikTok is active as `@bookquotes.app` with 24 public rows and 5 followers; the account read
reports token `expires_at=2026-10-25T10:11:23.478Z`, `reconnect_required=true` and
`status=expiring_soon`, with no new public row or attributable analytics entry. TikTok mutation holds
remain active because publishing-integrity, duplicate, native metadata, evidence and reconnect
controls are unresolved. Facebook post-insights and latest-post comments reads return HTTP 400 (`#12`,
singular statuses API deprecated), so those measures remain unavailable. The current Creative Centre
trends route redirects to a logged-in Creative Centre page, so no new external creative sample was
added. No TikTok mutation or automatic reply was attempted. The TikTok preparation queue remains
below the required three viable items: there is no release-ready future brief; `cr-03` and `cr-04`
need illustrated cuts, and already-live or held rows must not be re-uploaded. No weak replacement was
manufactured.

## Purpose

This runbook defines how BookQuotes maintains a regular organic publishing flow without requiring
approval for every routine Facebook post. The system should behave like a careful editor, not a
blind autoposter.

Facebook is the first automatic channel. Approved bank cards are scheduled on Graph at 13:00
Europe/London. Instagram publishes the same approved bank through a separate 13:00 due agent;
Graph cannot schedule. TikTok activation was recorded for the measured establishment phase on 18
August, but later publishing-integrity holds currently pause TikTok mutations; its cadence and
quality gates live in `TikTokOperatingRunbook.md`.

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

TikTok routine authority is limited to one reader-first post per day at 19:30 Europe/London during
the establishment phase. The first seven comparable posts use the 60/20/15/5 editorial mix. A
second daily slot remains a later controlled experiment, not a default cadence. That authority is
currently superseded by the active single-writer, duplicate, metadata and evidence holds recorded
in `TikTokOperatingRunbook.md`; research and production planning may continue, but no TikTok
upload, schedule, edit, delete or re-upload may occur automatically until those holds clear.

The 19 August audit found a same-caption Player of Games duplicate in the native TikTok library.
Until the single-writer path and duplicate guard are reconciled, TikTok uploads are held. Keep the
existing 19:30 baseline and do not delete or re-upload the duplicate automatically.

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

- Use 13:00 Europe/London for the approved content-bank cards and the current text prompts.
- Use 18:30-19:00 Europe/London only for a distinct visual/Reel slot, not as a second copy of
  the same bank card.
- Do not publish more than one primary post in a day unless account evidence supports it and the
  second item is materially different.
- Keep app-led content near 15% of output. The Page should remain useful to readers who never
  download the app.
- Avoid repeating the same topic, opening hook or format on consecutive days.

## Daily Automation

At 09:00 Europe/London:

1. Read the **Current operating loop** block in `PublishingStatus.md` first. Do not treat older
   dated notes as live queue state. Also read `PerformanceLearningLog.md`, this runbook and
   `ContentBankRunbook.md`.
2. Confirm the previous scheduled Facebook item moved to Published and record its live URL, actual
   time, format and initial metrics.
3. Read Graph `scheduled_posts` for Page `1246405755221229`. Treat the native read-back and the
   current operating-loop block in `PublishingStatus.md` as authoritative; do not infer the live
   queue from an older bank snapshot or describe an unverified queue as full.
4. Check today's Facebook item for correct account, public visibility, date, time, caption, cover,
   media, links and absence of accidental paid promotion.
5. If today's Facebook item is missing and the slot is still more than ten minutes away, select or
   create a replacement that passes the content and rights gates below, then schedule it. Do not
   duplicate an approved bank card already on Graph.
6. Maintain at least seven future Facebook days. Use the approved bank before creating new assets.
   Instagram is not published by this 09:00 job. Name the separate path:
   `uk.bookquotes.instagram-due` at 13:00, with `pre-publish-awake` at 12:50. TikTok reconnect is
   `uk.bookquotes.tiktok-reconnect` at 09:05.
   Once the active TikTok integrity holds are cleared and the native validation gate is recorded as
   clear, the next eligible category Reel may publish at 19:30 under `TikTokOperatingRunbook.md`;
   do not add a same-day second Reel.
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

As of 2 October 2026, 08:32 Europe/London, Meta identity and the Page scheduled edge are readable.
The `BookQuotes` Page (`1246405755221229`) is the active identity and the 27 September reader
prompt is published once at 13:00 BST. The previously empty queue was rebuilt with seven future
Facebook rows for 2-8 October at 13:00 Europe/London; each new row was preflighted, approved,
scheduled and read back once. No duplicate was created.

The last verified Facebook post-level insights still return HTTP 400, so metrics remain Not
available rather than zero. The Facebook comments request still lacks the required page-comment
permission. Instagram remains connected as `bookquotes.app`; the current read exposes 19 rows with
latest 30 August, so no fresh Instagram publication is claimed and no Instagram write was made.

The TikTok read succeeded: `@bookquotes.app` remains active with 24 public rows, 7 followers and
analytics access; the current inventory has no analytics sync timestamp. Gladwell reads 3 views /
3 reach / 1 save, business non-fiction reads 3 views / 2 reach / 1 save, and Freak! reads 252 views
/ 225 reach. Token health is `expiring_soon` with `reconnect_required=true` and expiry
`2026-10-02T13:24:12.214Z`; keep the reconnect path active. The single-writer, duplicate,
metadata, evidence and second-slot holds still block TikTok mutations. No TikTok upload, schedule,
edit, delete or re-upload was made.
