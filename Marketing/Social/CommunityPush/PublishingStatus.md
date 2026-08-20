# BookQuotes Community Push: Publishing Status

Updated: 20 August 2026, 07:10 Europe/London

### Audit: 20 August 2026, 09:04 Europe/London

- Identity remains verified: Facebook Page `1246405755221229`, Instagram
  `17841434821362428` / `bookquotes.app`, and TikTok `@bookquotes.app`.
- The Facebook Graph feed still shows `bq14-01` (`122108483445415831`) as the latest
  published BookQuotes card from 19 August at 13:00. The current CLI reads the published
  feed only; it does not prove the scheduled queue. A direct read of the logged website-hop
  object (`122108977917415831`) failed because the current Graph request uses a deprecated
  singular-status endpoint/field combination. The last native Scheduled read still showed no
  scheduled posts, so the claimed queue remains unresolved. No new Facebook mutation was made.
- Instagram's current media list still has no 19 August `bq14-01` card. The read-only due check
  selects `bq14-02` for today's 13:00 path, but it was not published during this audit.
- TikTok analytics synced at `2026-08-20T07:39:12Z`; the account is active, analytics-enabled,
  has 9 external posts and 0 followers. Current Zernio values are Team of Rivals 683 views / 0
  likes, Player of Games intended 687 / 1, the same-caption duplicate 239 / 1, and Commonplace
  Ritual 859 / 2. The token is healthy through `2026-08-21T06:07:17Z` and does not need
  reconnection.
- No new comment or message evidence was exposed by the current API read. No routine replies
  were made. App Store outcomes remain unavailable.
- Keep the TikTok single-writer hold. Do not upload `cr-03`, delete either Player duplicate, or
  retry the Facebook website-hop schedule until native/control-plane state is reconciled.

### Scheduled: 20 August 2026, 13:00 Europe/London — first website hop

Owner asked for a measurable Facebook-to-site post. Page
`1246405755221229` only. Graph ID `122108977917415831`. Unpublished until 13:00.

- Landing: `https://bookquotes.uk/journal/build-a-digital-commonplace-book`
- UTMs: `utm_source=facebook&utm_medium=organic_social&utm_campaign=bq-web-001-2026_08&utm_content=web-001-commonplace`
- No App Store URL in the post. The page carries the store button.
- Facebook bank card `bq14-02` was moved to 2 September 13:00 so this slot is not a
  double post. Instagram due still publishes `bq14-02` tomorrow at 13:00.

### Manual publish: 18 August 2026, 18:18 Europe/London

Owner asked for a second illustrated Reel to test the *Player of Games* format
(151 and 80 views on the two live PoG posts after ~2 hours). Same compiler,
deliberate quiet, different book.

- Asset: `Marketing/Video/illustrated-category-reels/02-team-of-rivals.mp4` plus cover.
- TikTok Zernio `6a84939c6dbb0dd4614c7c8b`, content ID `7675422054036424726`,
  `https://www.tiktok.com/@bookquotes.app/video/7675422054036424726`.
- Instagram `18060518723770036` at `https://www.instagram.com/reel/DcMIcjmCTZy/`.
- Extra format test. Keep the 19–25 August dated week. Do not re-upload this MP4
  on 20 August.

### Manual publish: 18 August 2026, 16:45 Europe/London

Owner reviewed the illustrated *Player of Games* cut muted, chose deliberate quiet (no
voiceover, no baked music), and asked to post that silent file.

- Asset: `Marketing/Video/illustrated-category-reels/01-player-of-games.mp4` plus
  `01-player-of-games-cover.png`. Not the rejected Remotion `category-reels/` set.
- Audio: silent AAC track only. No VO. No Commercial Music Library bed.
- TikTok `--now --approve` to `@bookquotes.app`. Zernio `6a847da810c540993aa32423`
  reached `published`. Native content ID `7675397855864604694` at
  `https://www.tiktok.com/@bookquotes.app/video/7675397855864604694`.
- Instagram `--now --approve` to `17841434821362428`. Media `18022991393885494` at
  `https://www.instagram.com/reel/DcL9vV5D5GY/`.
- Facebook was not used. The 13:00 bank still stays a different asset.
- This is an extra early post, sitting beside the calendar. It does not replace
  the 19–25 August week. Do not post a second TikTok tonight. Do not upload this
  same MP4 again. Keep 13:00 bank stills and 19:30 category Reels on their dated
  slots. cr-02–cr-07 still need muted-phone review before `--approve`.

## Automation

Routine organic Facebook publishing is now authorised to run automatically under
`AutomatedPublishingRunbook.md`. The daily automation maintains a seven-day queue, verifies
publication, performs preflight and rights checks, and logs every action.

TikTok research, briefing, quality control and learning may run automatically under
`TikTokOperatingRunbook.md`. Native validation is now recorded as complete, so TikTok routine
publishing is active for the one-post-per-day establishment phase at 19:30 Europe/London.
Instagram can publish immediately through Graph (`--now`) but cannot be scheduled; the daily
automation does not post Instagram unless someone runs that command.

The daily `bookquotes-daily-social-check` automation now coordinates research, Facebook preflight
and the validated TikTok establishment phase at 09:00 Europe/London. It does not publish Instagram.
Instagram bank cards publish from `uk.bookquotes.instagram-due` at 13:00. TikTok reconnect is
`uk.bookquotes.tiktok-reconnect` at 09:05. TikTok routine posts use the 19:30 slot; paid,
sensitive and rights-uncertain material remains approval-gated.

### Current operating loop: 20 August 2026, 07:10 Europe/London

Use this block as the live audit. Older dated notes below are history.

- Identity is verified. Page `1246405755221229`, Instagram `17841434821362428`, TikTok
  `@bookquotes.app`.
- Facebook 19 August 13:00 published `bq14-01` (`122108483445415831`): three-adjectives
  card. Graph comments/insights still unread with this token.
- Facebook Scheduled still has a full 13:00 queue through 2 September. Today's 13:00
  item is the website hop `122108977917415831` (unpublished). `bq14-02` sits at
  2 September 13:00 on Facebook only.
- Instagram due dry-run selected `bq14-02` for 13:00. Yesterday's `bq14-01` card is
  not in the Instagram media list: the 13:00 due job likely missed (Mac asleep).
  Keep this Mac awake at 12:50 today. Do not `--approve` the due item now.
- Instagram illustrated Reels unchanged and undistributed: PoG 4/4 / 100% skip;
  ToR 2/2 / 100% skip; presidential 34/28; Commonplace 44/41. Comments empty.
- TikTok views have plateaued overnight. ToR 683 / 0 likes; PoG 687 / 1 and
  duplicate 239 / 1; Commonplace 859 / 2. Followers 0. No comments. Older rows 0.
- TikTok token expires `2026-08-20T08:04:18Z` (~09:04 Europe/London). Status
  `expiring_soon`. Reconnect OAuth was opened. Complete it before 09:04.
- Do not re-upload cr-01 or cr-02 at 19:30. Next unused illustrated cut is
  `cr-03` *Foster* on 21 August after muted-phone review.
- No comments or DMs to answer. App Store downloads remain unavailable.

### Current operating loop: 19 August 2026, 09:05 Europe/London

Use this block as the live audit. Older dated notes below are history.

- Identity is verified. Page `1246405755221229`, Instagram `17841434821362428`, TikTok
  `@bookquotes.app` / Zernio `6a7e30f977555aae0187cea3`.
- Facebook 18 August 13:00 published twice as intended: unfinished-book prompt
  `122108736033415831` at 13:00 and reader-first recommendation `122108480283415831`
  at 13:00. Graph comment and insights edges are not readable with the current token
  (`pages_read_user_content` missing; insights metric names rejected).
- Facebook Scheduled is healthy: 14 Public photo rows at 13:00 Europe/London from
  19 August through 1 September. Today's item is `bq14-01` (`122108483445415831`):
  "Choose your next read with 3 adjectives—not a genre."
- Instagram due dry-run selected `bq14-01` for 13:00. `uk.bookquotes.instagram-due`
  should publish it if this Mac is awake at 12:50/13:00. Do not `--approve` it now.
- Instagram illustrated Reels have almost no distribution: *Player of Games*
  `18022991393885494` 4 views / 4 reach / 1.6s avg / 100% 3s skip;
  *Team of Rivals* `18060518723770036` 2 views / 2 reach / 2.6s avg / 100% skip.
  Presidential 34/28, Commonplace 44/41. Comments empty on all four.
- TikTok is the live channel. Zernio sync 19 August 07:35 Europe/London. Followers 0.
  Latest rows: *Team of Rivals* `7675422232285433110` 514 views / 0 likes;
  *Player of Games* `7675397759196957954` 681 views / 1 like and a same-caption
  duplicate `7675398121542929667` 235 views / 1 like; Commonplace
  `7674952452055076118` 859 views / 2 likes. Older rows remain 0. No comments.
- TikTok token was reconnected at 09:05. Status `ok`. Expires
  `2026-08-20T08:04:18Z` (~09:04 Europe/London tomorrow). `needs_reconnection`
  is false. The 09:05 reconnect job should refresh it again tomorrow.
- Today's 19:30 category row is `cr-01`. That illustrated cut is already live as an
  18 August extra. Do not re-upload it. Do not use the rejected Remotion
  `category-reels/` files. Next unused illustrated cut is `cr-03` *Foster* on 21 August
  after muted-phone review.
- No Facebook/Instagram/TikTok comments to answer. App Store downloads remain
  unavailable. First website-link Facebook post is scheduled for 20 August 13:00
  (`122108977917415831`).

### Reconciliation note: 19 August 2026, 09:08 Europe/London

- Meta has a source conflict. The visible Scheduled tab says `No scheduled posts`, while the
  Graph/control-plane read recorded 14 approved Public photo rows from 19 August through 1
  September. The approved `bq14-01` schedule attempt was refused as `duplicate_copy_refused`; no
  new mutation was made. Treat the native UI and Graph queue as unresolved until one source can be
  verified against the other. Do not create another Facebook copy.
- The visible Published table confirms two Facebook posts at 18 August 13:00, both reach 0,
  views 0 and exposed interaction fields 0. The 17 August 13:10 post remains reach 1, views 0.
- TikTok native Recent posts now shows nine public BookQuotes posts. On 18 August the same Player
  of Games caption appeared twice: `7675397759196957954` at 681 native views / 1 like and
  `7675398121542929667` at 235 / 1. The current Team of Rivals extra is
  `7675422232285433110` at 514 in the latest Zernio sync and 587 in the native table. The native
  and Zernio reads differ slightly; preserve both as source observations rather than averaging.
- The Player of Games duplicate is a publishing-integrity failure, not evidence for two creative
  executions. Do not delete automatically, do not upload either file again, and do not treat the
  Team of Rivals extra as the dated 20 August slot.
- TikTok routine publishing is on a single-writer hold until the duplicate path is reconciled.
  Keep the next unused illustrated cut (`cr-03`, Foster) in review for 21 August; do not publish a
  new TikTok item during this audit.

### Current operating loop: 18 August 2026, 09:01 Europe/London

Use this block as the live browser audit. The older 17 August queue block below is historical and
must not be treated as proof of the current native queue.

- Facebook Published shows the latest live post `122108480163415831`, published 17 August at
  13:10. The visible row reads reach 1, views 0, viewers 0, interactions 0, likes 0, comments 0,
  shares 0, saves 0 and follows 0; watch time and link clicks are not available. A separate 17
  August 13:00 prompt `122108480745415831` is also visible with all exposed metrics at zero.
- Facebook Scheduled currently shows only two Public, Facebook-only, unboosted rows, both at 18
  August 13:00: the unfinished-book prompt and the reader-first recommendation prompt. This
  conflicts with the older logged 15-item bank queue. No new item was scheduled and no existing
  row was edited or deleted while the native queue is contradictory.
- Instagram Published shows the presidential-biographies Reel `17905441377304338`, published 17
  August at 11:54. The current native read-back is 32 views, 26 reach, 38 seconds watch time and
  1 second average play time, with 0 visible interactions, likes, comments, shares and saves.
- TikTok Studio is signed in as `@bookquotes.app`. The Commonplace Reel
  `7674952452055076118` is Public once at `https://www.tiktok.com/@bookquotes.app/video/7674952452055076118`
  with 855 views, 2 likes and 0 comments. The five older native rows remain at 0 views, 0 likes
  and 0 comments. This is the first non-zero attributable TikTok result.
- The native Account Check URL resolved to the signed-in Studio surface without visible warning or
  restriction text, but did not expose a formal account-health report. Record that limitation;
  do not treat it as a guarantee of unrestricted account health.
- TikTok establishment stays one reader-first post per day at 19:30. The 18 August
  16:45 *Player of Games* Reel is an extra early cut, not a substitute for the
  19–25 August week. 13:00 bank stills continue from 19 August (`bq14-01`).
  19:30 category Reels continue on their dated rows. Do not re-upload the live
  cr-01 file. The rejected Remotion `category-reels/` files stay unpublished.
- Facebook comments, Instagram comments/Direct and TikTok comments show no new messages. No
  routine reply was made. App Store downloads and activation signals remain unavailable.

### Current operating loop: 17 August 2026, 14:30 Europe/London

Use this block as the 09:00 source of truth. Older dated notes below are history.

- Facebook Graph scheduled queue is **not** empty. 18 August text plus approved bank cards
  `bq14-01`–`bq14-14` sit at 13:00 Europe/London through 1 September (15 future items after
  today's 13:10 publish). Page `1246405755221229` only.
- Content bank `bookquotes-2026-08-a` is **approved**, not draft. Instagram due prefers
  the git bank when readable; launchd falls back to the marketing-os mirror. A commit
  or merge refreshes that mirror. `uk.bookquotes.sync-content-bank` also tries at 12:55.
- Instagram Graph is `--now` only. `uk.bookquotes.instagram-due` at 13:00 publishes today's
  approved bank card. `pre-publish-awake` starts at 12:50. Owner accepted the Mac-on
  residual on 17 August; a non-Mac runner is not required. First bank Instagram date
  is 19 August.
- TikTok token expires `2026-08-18T11:55:56Z`. 09:05 reconnect opens OAuth only when fewer
  than 6 hours remain. Commonplace retry is live; latest Zernio analytics ID
  `7674952452055076118`.
- Category Reel pipeline is live in `CategoryReelPipeline.json`. 13:00 stills stay on
  Facebook/Instagram. 19:30 is one faceless category Reel on TikTok and Instagram
  (same MP4; Instagram `--now`). First week 19–25 August: Player of Games, Team of
  Rivals, Foster, Tinker Tailor, Four Thousand Weeks, Stoner, Culture/Three-Body
  pairing. Draft briefs still need Remotion renders, a hard first-frame hook, and
  `--approve`.
- 13 August Facebook caption is still `dry-run-only`. Owner parked restore
  (`hbec.5.1.7`). CLI `writes_enabled` stays false.
- Instagram profile photo is live. Graph read at 16:42 shows
  `has_profile_pic=true` for `@bookquotes.app`. Owner uploaded the official
  app icon in the Instagram app. Pin is `DcDVq58DNVI`.
- Instagram Graph insights at 14:56: Commonplace 44 views / 95% 3s skip /
  1.9s avg watch. Presidential 20 / 94% / 1.5s. Illustrated intro 12 / 100% /
  1.0s. Library-phone intro 7 / 86% / 4.8s. The app retention curve is not in
  Graph. Volume is too small for a verdict; library-phone is the only hold.
- App Store Sales and Trends UI is empty. Downloads stay null. Search Console was refreshed
  17 August 14:29.

### TikTok health: 17 August 2026, 07:20 Europe/London

- Zernio now returns a live `@bookquotes.app` account: active, no reconnect flag,
  analytics access true, last sync 05:55 Europe/London, no sync error. `meta_cli.py
  posts --channel tiktok` reads this path.
- Five native videos have content IDs and synced metrics. All current values are 0.
  That closes the old “no attributable analytics” gap. It does not show distribution.
- The 14 August Commonplace Zernio post `6a7f031b2fc86999e9e30916` is still `failed`
  with `Daily active user quota reached.` No TikTok content ID. A new-day retry is
  allowed; do not reuse that failed Zernio ID.
- The Zernio TikTok token expires at 22:46 UTC today. Reconnect in Zernio before then
  or tonight’s publish path dies.

### Instagram: why nothing new since 15 August

- Graph is connected and can publish Reels immediately. It cannot schedule. The daily
  09:00 job only maintains the Facebook queue, so Instagram stays quiet until someone
  runs `publish --channel instagram --now --approve`.
- Three Reels are live. Numbers are unchanged from 16 August: Commonplace 44/41, first
  intro 12/12, library-phone intro 7/7. Still 0 likes, comments, saves, followers.
- Profile-editor verification does not block Graph publish.

### Live audit: 17 August 2026, 09:03 Europe/London

- Facebook Published now shows the 16 August reading-reset item as content ID
  `122108191239415831`, published at 13:01. Its visible reach, views, viewers, interactions,
  likes, comments, shares, saves, follows and link clicks are all 0; watch-time fields are Not
  available.
- Facebook Scheduled now contains only two future Public, Facebook-only, unboosted items: 17 and
  18 August at 13:00. This is below the three-day alert threshold and below the seven-day target.
  No replacement was scheduled while the live `dry-run-only` caption incident and concurrent write
  path remain under review.
- Facebook comments show no comments. Instagram comments show no comments, and Instagram Direct
  shows no messages. No routine reply was made.
- Native TikTok Recent posts now lists five Public BookQuotes videos, not two: marked-page product
  proof (28 July, `7667570006032387350`), Team of Rivals (29 July,
  `7667846219120626966`), presidential biographies (29 July, `7667829238065646870`), Player of
  Games (31 July, `7668631665064938774`) and Three-Body Problem (5 August,
  `7670655931193068823`). The latest native post is therefore 5 August at 22:02; no new post has
  appeared since then.
- Every native TikTok row shows 0 views, 0 likes and 0 comments. The TikTok dashboard key metrics
  remain placeholders, and the native Account Check route returns Access Denied. The separate
  Zernio health report says analytics access is enabled, but the native account-health and
  attributable analytics gate is still not satisfied. TikTok publication and the proposed two-a-day
  cadence remain paused.

### Manual publish: 17 August 2026, 11:54 Europe/London

- Instagram `--now --approve`: presidential biographies Reel with the phone-overview
  cover. Graph ID `17905441377304338`. Permalink
  `https://www.instagram.com/reel/DcI3nv9j-bV/`. Initial insights 0/0.
- TikTok `--now --approve`: Commonplace Ritual retry. Zernio post
  `6a82e8684c5d29bbff1741c1` reached `published` with TikTok content ID
  `7674951820296898582`. Analytics have not attached yet. The 14 August failed
  Zernio job remains on file and was not reused.
- Facebook Graph scheduled queue is empty. Today's 13:00 slot is not sitting in
  Graph as scheduled. The 19 August–1 September content bank is still 14 drafts.
  Superseded at 13:12: queue restored and all 14 bank cards approved. See Current
  operating loop.

### Queue restore: 17 August 2026, 13:12 Europe/London

- TikTok reconnect completed. `token_expires_at` moved from 22:46 UTC today to
  `2026-08-18T11:55:56Z` (12:55 tomorrow). TikTok access tokens on this path last
  about 24 hours. `uk.bookquotes.tiktok-reconnect` runs at 09:05 and opens OAuth
  only when fewer than 6 hours remain. Manual: `reconnect --channel tiktok`.
- Facebook today published at 13:10:
  `1246405755221229_122108480163415831`
  https://www.facebook.com/122107379391415831/posts/122108480163415831
- Facebook scheduled queue now has 15 items: 18 August text plus `bq14-01`–`bq14-14`
  at 13:00 Europe/London through 1 September.
- All 14 content-bank cards are approved (`john-mcneil`, native queues reconciled).
- Instagram Mac path is live. launchd could not read `~/Documents`, so the agent
  publishes from `/Users/skyhub/bookquotes-marketing-os/content-bank/` (14 approved
  cards mirrored). A 13:18 kickstart from launchd returned `no_due_item` / exit 0.
  A 19 August dry-run selected `bq14-01` with the local PNG. `pre-publish-awake`
  holds sleep from 12:50. After any bank edit, rerun `bin/sync_content_bank.py`.

### Search Console rollup: 17 August 2026, 14:29 Europe/London

- Property `sc-domain:bookquotes.uk` still reads as `siteOwner` via application
  default credentials. Sitemap was read only: Success, 15 submitted, 0 indexed,
  last downloaded 14 August 21:18 UTC. Homepage URL Inspection remains PASS /
  Submitted and indexed; last crawl still 7 August 06:53 UTC. No sitemap
  resubmit and no indexing request.
- Final Search Analytics through 16 August: homepage 1 click / 9 impressions.
  Query rows are now present (measured zeros on clicks): book quote finder,
  book quote search, book quotes finder, quote finder for books, quote finder
  in books. Cloudflare HTTP traffic stays unavailable.

### App Store instrumentation: 17 August 2026, 14:23 Europe/London

- Team API key `XL86RSSVSY` is installed at the existing external App Store Connect
  path and is shown as Admin. The older Individual key was not deleted. Metadata,
  versions and IAPs still read 200. Per-app `analyticsReportRequests` now reads 200.
  July finance is authorized and empty (`no sales for the date specified`).
  Downloads stay null.
- Owner confirmed vendor `93932031`. Finance accepts it. Sales and Trends UI shows
  no reports. Daily Sales still returns `Invalid vendor number`; that is Apple's
  empty-account catch-all, not a wrong vendor or missing role. Retry after the
  first processed period. Do not invent zeros.
- Four generated campaign links are recorded in `GrowthEvidence.json` with
  `pt=128448172`: `facebook`, `instga`, `tiktok`, `b00k quotes`.
- TikTok Commonplace retry now has distribution. Zernio read 227 views on
  `7674952452055076118` at 14:17. Owner reported 298 on the native surface.
  Likes, comments, shares and saves are measured zeros. This is the first
  non-zero BookQuotes TikTok view count in the ledger.

## Facebook

### Live audit: 16 August 2026, 09:02 Europe/London

- The 15 August scheduled Facebook text item `A reading list is useful when it leaves room for
  the book you did not know you needed` published once at 13:01 as content ID
  `122107908201415831`. Visible reach, views, viewers, interactions, likes, comments, shares,
  saves, follows and link clicks are all 0; watch-time fields are Not available.
- The 13 August placeholder item remains `dry-run-only` at reach/views/viewers 2/2/2. It was not
  edited automatically. The 14 August text and extra Reel also remain at visible zeroes.
- The Scheduled Library now reads three future Public, Facebook-only, unboosted items on 16, 17 and
  18 August at 13:00. This is at the three-day threshold and below the seven-day runbook target; no
  new item was created while the concurrent publishing path and placeholder incident remain under
  review.
- Facebook comments show no comments. Instagram comments show no comments and Instagram Direct
  shows no messages. No routine reply was made.

### Live audit: 16 August 2026, Instagram and TikTok

- Instagram's 14 August 22:15 Commonplace Ritual Reel now reads reach 41 and views 44, with visible
  engagement at 0. The 15 August 08:12 intro Reel reads reach/views 12/12, and the 08:21 library-
  cover variant reads 7/7. Viewers, completion and full retention details remain Not available.
- The two 15 August intro variants still share overlapping core copy. No deletion or further
  Instagram publication was made automatically; keep them as a duplicate-candidate comparison until
  the user decides whether one should remain live.
- TikTok Studio still shows only two native BookQuotes posts: 5 August at 22:02 and 31 July at
  11:07. The dashboard remains at 1 account-level video view, with profile views, likes, comments
  and shares at 0 and no attributable content ID. Account Check again redirects to the dashboard
  without account-health evidence. TikTok remains paused.

### Live audit: 15 August 2026, 09:04 Europe/London

- The 14 August scheduled Facebook text item `Do you keep the first line, the last line, or the
  line you argued with?` published once at 13:00 as content ID `122107651779415831`. Visible reach,
  views, viewers, interactions, likes, comments, shares, saves, follows and link clicks are all
  0; watch-time fields are Not available.
- An additional Facebook Reel, `Your reading journal should not become homework`, published at
  12:47 as content ID `122107649667415831` and also reads back with visible metrics at 0. This
  created two primary Facebook items on 14 August, so it is recorded as an extra-slot observation
  rather than treated as evidence for increasing cadence.
- The 13 August item still displays `dry-run-only` with reach/views/viewers 2/2/2. It remains a
  content-integrity blocker and was not edited automatically. The Scheduled Library now reads
  four future Public, Facebook-only, unboosted items on 15, 16, 17 and 18 August at 13:00; this is
  above the three-day alert threshold but below the seven-day runbook target.
- Facebook comments show no comments. Instagram comments show no comments, and no Instagram direct
  message requiring action was visible. No routine reply was made.

### Live audit: 15 August 2026, Instagram and TikTok

- Meta Published read-back confirms three BookQuotes Instagram Reels. The 14 August 22:15
  Commonplace Ritual test has reach 27 and views 31, with viewers/watch-time not exposed and all
  visible engagement at 0. The 15 August 08:12 intro Reel and 08:21 library-cover variant each
  show 0 views so far, with reach and viewer data not exposed at this early checkpoint.
- The two 15 August intro Reels share overlapping core copy and should be reviewed as a duplicate
  candidate before any further Instagram posting. No deletion was made automatically. Instagram
  publishing works through the current Graph path, but native profile editing remains verification-
  gated and Instagram has no native scheduling path in the current setup.
- TikTok Studio still shows only two BookQuotes posts: the latest is the Three-Body Problem Reel
  from 5 August at 22:02 and the earlier Player of Games Reel from 31 July at 11:07. The dashboard
  shows 1 account-level video view and 0 profile views, likes, comments and shares; no content ID is
  attributable to that view. The attempted 14 August adapter post failed with `Daily active user
  quota reached` and created no TikTok content ID. No retry was made.
- TikTok account-check again redirected to the dashboard and returned placeholder metrics rather
  than an account-health result. TikTok publishing and the two-a-day cadence remain paused.

### Instagram pin intro cover: 15 August 2026, 08:21 Europe/London

- Replaced the illustrated-page cover with a ShiftPro-style still: dark ink field,
  concentric rings, brand top-left, and a real phone mockup of the library home
  (`screens/appstore/iphone/01_library_grid.png`). The video hook now opens on the
  same library capture. BookQuotes gold/ink/bone only.
- New Instagram ID `18093336461178403`. Permalink
  `https://www.instagram.com/reel/DcDVq58DNVI/`.
- Graph cannot update a published Reel cover or pin. Pin this new Reel in the
  Instagram app: Reel → ••• → Pin to profile. The 08:12 Reel
  `https://www.instagram.com/reel/DcDUmjEDAs3/` is still live; do not delete it
  unless asked.
- CLI read-back timed out after publish; the media list confirms the post.

### Instagram pin intro: 15 August 2026, 08:12 Europe/London

- Posted a 30-second product explainer Reel `BookQuotesIntro` with dedicated cover
  `out/bookquotes-intro-cover.png`. Dark high-contrast tile, brand on, four shipped
  capabilities: photograph a marked page, review extracted words, save with the book,
  search the personal library. End card names tags, collections and export only.
- Instagram ID `17953145868015200`. Permalink
  `https://www.instagram.com/reel/DcDUmjEDAs3/`.
- Superseded as the pin candidate by the 08:21 library-phone cover. Graph cannot pin.
- CLI read-back timed out after publish; the media list confirms the post.

### Instagram test: 14 August 2026, 22:15 Europe/London

- Graph does not need the Business Suite profile-verification prompt to publish. That prompt
  only blocks native profile edits. `instagram_content_publish` was already granted.
- The Facebook Commonplace Ritual Reel was reused: same MP4, same cover, same caption.
- The CLI now hosts the local files on `media.zernio.com`, waits for the Instagram container to
  finish processing, then publishes immediately. No Instagram schedule exists.
- Live Instagram Reel `18112192355072092`. Permalink
  `https://www.instagram.com/reel/DcCQSLRj430/`.
- This is a one-off test, not the start of automatic Instagram posting. Bank cards remain drafts.
  Instagram still cannot be scheduled.

### TikTok adapter: 14 August 2026, 13:00 Europe/London

- `publish --channel tiktok --approve` now uses Zernio for `@bookquotes.app` only. Local Remotion
  MP4s and dedicated covers upload, then post with the same `--approve` gate as Facebook.
- A Commonplace Ritual test was submitted once. Zernio accepted the video and cover, then TikTok
  returned `Daily active user quota reached.` Zernio post `6a7f031b2fc86999e9e30916` is `failed`.
  No TikTok content ID was created. Do not retry today.

### Live publish: 14 August 2026, 12:48 Europe/London

- Published one Facebook Reel as a cover-and-video test: Commonplace Ritual, with the dedicated
  `FeedCover` still `out/community/commonplace-ritual-cover.png`.
- Graph accepted the preferred thumbnail. Content ID
  `1246405755221229_122107649667415831`. Permalink
  `https://www.facebook.com/reel/3633316180171083/`.
- Caption is the existing launch-pack commonplace copy. This is not a duplicate of the 5 August
  commonplace carousel.
- Instagram and TikTok were not posted. Find the line, Annotation debate, One line, and Marked
  page were not re-uploaded.
- The 13 August `dry-run-only` caption was not edited.

### Live audit: 14 August 2026, 08:09 Europe/London

- Meta Business Suite is operating as the `BookQuotes` Facebook Page. The 13 August 13:00
  scheduled item published once, but the native Published table now displays the placeholder
  caption `dry-run-only` for content ID `122107333143415831`. Visible native metrics are reach 2,
  views 2 and viewers 2; interactions, likes, comments, shares, saves, follows and link clicks are
  0, with watch-time fields Not available. This is a content-integrity incident, not a creative
  result.
- The Scheduled Library reads back five future Public, Facebook-only, unboosted items on 14, 15,
  16, 17 and 18 August at 13:00 Europe/London. No duplicate is present in the read-back.
- Facebook Inbox/comments reports no comments or messages requiring action. No routine reply was
  made. The placeholder caption was not edited automatically; restoring the intended caption is an
  approval-required Business Suite mutation.

### Live audit: 14 August 2026, TikTok and Instagram

- TikTok Studio is signed in as `@bookquotes.app`. The initial dashboard read-back showed 1
  account-level video view in the last seven days and 0 profile views, likes, comments and shares;
  the value is not attributable to a content ID. The account-check route redirected to the main
  dashboard and exposed placeholders rather than an account-health result. The recent-post surface
  still shows the Three-Body Problem and Player of Games BookQuotes posts; no new post has been
  verified since 5 August.
- No TikTok upload, schedule, edit, deletion or reply was made. Publishing and the proposed
  two-a-day cadence remain paused until Content/Account Check access and an attributable analytics
  entry are available.
- Meta Business Suite settings shows the connected Instagram accounts `@bookquotes.app` and
  `@shiftpro.app`. BookQuotes profile editing remains verification-gated; no Instagram post or
  native performance metric was verified.

### Incident: 13 August 2026, token-write probe

- Graph now grants `pages_manage_posts` and `instagram_content_publish` in addition to the
  existing read scopes. Identity remains Page `1246405755221229` / Instagram `bookquotes.app`.
- A CLI permission probe accidentally replaced the published 13 August 13:00 Facebook
  margin-notes prompt (`1246405755221229_122107333143415831`) with the placeholder
  `dry-run-only`. No other post was changed. Instagram was not mutated.
- The original caption is not stored in the repository. Restore it from Meta Business Suite
  edit history before treating today's item as the intended reader prompt.
- The BookQuotes CLI now refuses updates while `writes_enabled` is false and refuses probe
  placeholder messages. `--approve` must not be used to test token scope.
- `bin/meta_cli.py publish` is the intended scheduler. Facebook can schedule or post now.
  Instagram can post now from a public JPEG URL and has no native Graph schedule. TikTok
  remains refused. Bank items must be approved. `writes_enabled` stays false so live
  caption edits remain locked.

### Live audit: 13 August 2026, 08:00 Europe/London

- Meta Business Suite is operating as the `BookQuotes` Facebook Page. The 12 August `Try the
  24-hour highlight test` prompt is Published once at 13:00 with visible reach 1 and the other
  exposed interaction, view, viewer, follow, comment, share, save and link-click values at 0;
  watch-time fields are Not available. This is an initial under-24-hour read-back, not a creative
  verdict.
- The Scheduled Library reads back one Public, Facebook-only, unboosted item per day on 13, 14,
  15, 16, 17 and 18 August at 13:00 Europe/London. Planner and Scheduled Library agree on the
  visible queue; no duplicate is present in the read-back.
- Facebook comments reports `No comments`. Inbox shows no message requiring action. No routine
  reply was made and no approval-required draft is outstanding.

### Live audit: 13 August 2026, TikTok and Instagram

- TikTok Studio was initially readable as `@bookquotes.app`. The dashboard showed 1 account-level
  video view in the last seven days, with profile views, likes, comments and shares at 0. The
  single view is not attributable to a post, so it cannot close the native analytics gate.
- The TikTok Studio Content and Account Check routes returned `Access Denied` during the same run.
  No new post has been published since the 5 August `The Three-Body Problem` Reel, and no upload,
  schedule, edit, deletion or reply was made. Publishing remains paused.
- Meta Business Suite now visibly includes the connected Instagram asset `@bookquotes.app` under
  the combined BookQuotes asset. The Instagram profile editor still requires account verification;
  no Instagram post, reach, comment or message metric was verified. Facebook scheduling remains
  Facebook-only.

### Live audit: 12 August 2026

- Meta Business Suite remains on the `BookQuotes` Facebook Page. The 11 August reading-life
  prompt is Published once at 13:00 with native reach, views, viewers, follows, interactions,
  likes, comments, shares, saves and link clicks all displaying 0; watch-time fields are not
  available. The Scheduled Library reads back one Public item per day from 12 through 18 August
  at 13:00 Europe/London, Facebook-only and unboosted.
- Facebook comments reports `No comments`. No routine reply was made and no approval-required
  draft is outstanding.

### Live audit: 11 August 2026

- Meta Business Suite is operating as the `BookQuotes` Facebook Page. Native Scheduled Library
  read-back now shows one Public, Facebook-only, unboosted item on each day from 11 to 18 August
  at 13:00 Europe/London. The queue contains the original 11 August reading-life prompt, the
  12 August 24-hour highlight test, the 13 August margin-notes prompt, the 14 August marked-line
  prompt, the 15 August accidental-discovery reading-list prompt, the 16 August reading-reset
  prompt, the 17 August book-conversation prompt and the 18 August unfinished-book prompt.
- A duplicate 11 August copy of the 13 August margin-notes prompt was found during native
  reconciliation and permanently deleted. The valid 13 August item remains present once. No
  duplicate retry was made while the earlier scheduler state was uncertain.
- Facebook comments reports `No comments`; Inbox shows no message requiring action. No routine
  reply was made and no approval-required draft is outstanding.

### Live audit: 11 August 2026, TikTok and Instagram

- TikTok Studio confirms the account username is `@bookquotes.app`. Content lists five Public
  posts once; the latest is `The Three-Body Problem` reader-fit Reel, content ID
  `7670655931193068823`, published 5 August 2026 at 22:02 Europe/London. The four earlier posts
  are dated 28, 29 and 31 July. No TikTok post has been published since 5 August.
- TikTok Analytics, Last 7 days, reports 0 video views, profile views, likes, comments and
  shares. Each of the five visible content rows also reports 0 views, 0 likes and 0 comments;
  comments reports `No comments yet`. Retention, completion, saves, profile visits, follows,
  link taps and attributable post analytics remain Not available. The account is public: the
  Private account checkbox is off in Settings.
- TikTok remains held against the native publishing gate until an attributable analytics entry
  and normal distribution are evidenced. No second daily slot or catch-up uploads were made.
- BookQuotes Instagram remains disconnected from Meta Business Suite, so Instagram publication,
  reach, comments and messages remain Not verified.

### Live audit: 8 August 2026, 08:09 Europe/London

- Meta Business Suite is operating as the `BookQuotes` Facebook Page. The 7 August `Find the line`
  Reel is listed once as Published at 18:30 with content ID `122105782647415831`; its visible
  reach, views, viewers, follows, interactions, likes, comments, shares, saves and link clicks are
  all 0. Watch-time cells are 0 or Not available in the native table.
- The 8 August reader prompt is present in the native Published table at 13:00 with visible metrics
  at 0. The Scheduled Library now reads back three future Public Facebook-only items once each:
  9 August 10:00 book-club carousel, 10 August 13:00 `A book can be good and still be wrong for
  this week` text prompt, and 11 August 13:00 `A reading life is not measured only by the books
  you finish` text prompt. No media, boost, story share or cross-post was enabled on the two new
  text items.
- Facebook Inbox was checked under the BookQuotes identity. No new message or comment requiring
  action was visible; no routine reply was made and no approval-required draft is outstanding.

### Live audit: 7 August 2026, 21:45 Europe/London

- Meta Business Suite is visibly operating as the `BookQuotes` Page. The Page has 0 followers and
  BookQuotes Instagram remains unconnected.
- The 28-day Insights overview (10 July-6 August) reports 19 views and 3 new viewers; the visible
  audience is 100% non-followers. This is instrumentation evidence, not enough volume for a creative
  or timing decision.
- Content insights lists the 7 August `Find the line` Reel once as Published after its intended 18:30
  slot. Its initial visible reach/views are 0. The 3 August annotation-debate Reel remains at reach 1,
  view 1 and viewer 1; inspected 4-6 August items remain at visible zeroes.
- Planner/Scheduled Library reconciliation was not completed in this audit, so the previously
  recorded 8-9 August queue is not promoted to newly verified status here.
- No post was created, scheduled, edited, deleted or replied to. The next original, text-only
  execution is preflighted in `FB001HighlightTest.md` and intentionally remains a draft until native
  scheduling and read-back can be completed once.

### Live audit: 7 August 2026, 08:01 Europe/London

- Meta Business Suite remains on the `BookQuotes` Facebook Page. The 6 August reader prompt is
  Published once at 13:00 with content ID `122105430807415831`; visible reach, views, viewers,
  follows, interactions, likes, comments, shares, saves and link clicks are all 0. Watch-time and
  other unavailable cells remain Not available.
- The confirmed Facebook queue is now three future Public items: the `Find the line` Reel on 7 August
  at 18:30, the new reader prompt `Do you remember books by their stories, or by the lines you marked?`
  on 8 August at 13:00, and the book-club carousel on 9 August at 10:00. The 8 August item was created
  once, Facebook-only, with no media, link, boost, story share or cross-post.
- Facebook comments and Inbox remain empty. No routine replies were made and no approval-required
  drafts are outstanding.

### Live audit: 6 August 2026, 08:02 Europe/London

- Meta Business Suite is operating as the `BookQuotes` Facebook Page. The 5 August commonplace
  carousel is Published at visible reach 0 and views 0; the 3 August annotation-debate Reel remains
  at reach 1 and views 1 with visible likes, comments, shares, saves and follows at 0.
- The missing 6 August slot was filled once with the verified reader prompt `A reading habit you
  abandoned?`. It is scheduled for 6 August at 13:00 Europe/London, Public, Facebook-only, with no
  media, link, boost, story share or cross-post. Meta's active-time recommendation selected 13:00;
  the usual 12:30 text slot was not available in the native picker.
- The 7 August `Find the line` Reel remains Scheduled for 18:30 Public and the 9 August book-club
  carousel remains Scheduled for 10:00 Public. The queue now has three confirmed future items and
  no duplicate was created.
- Facebook Inbox reports no comments. No messages, routine replies or approval-required drafts are
  outstanding.

### Live audit: 5 August 2026, 08:00 Europe/London

- Meta Business Suite is visibly operating as the `BookQuotes` Facebook Page. The Page shows 0
  followers and the Content Library is available under the correct identity.
- The 4 August hand-copied-lines text post is Published with visible reach 0 and views 0. The
  3 August annotation-debate Reel remains Published with reach 1 and views 1; visible likes,
  comments, shares, saves and follows are 0. Some secondary metrics were still loading.
- The 5 August commonplace-book carousel is confirmed Scheduled for 18:30 Public. The 7 August
  `Find the line` Reel is confirmed Scheduled for 18:30 Public and the 9 August book-club carousel
  is confirmed Scheduled for 10:00 Public. No boost or paid promotion is enabled.
- The confirmed queue contains three future items but has gaps on 6 and 8 August. This is below the
  intended rolling daily cadence; no duplicate or unverified replacement was created in this run.
- Facebook Inbox reports no messages and Facebook comments reports no comments. No routine replies
  were made and no approval-required drafts are outstanding.

### Live audit: 4 August 2026, 08:00 Europe/London

- Meta Business Suite still shows `ShiftPro, shiftpro.app` as the active identity, with Facebook and
  Instagram follower counts of 0. BookQuotes publishing and performance remain Not verified.
- No Facebook item was created, scheduled, rescheduled or published while the identity was ambiguous.

### Identity resolution: 4 August 2026

- Following the user's explicit authorisation, Meta Business Suite was switched to the `BookQuotes`
  Facebook Page. The BookQuotes Content Library and Scheduled tab are now visible.
- The latest published item is the annotation-debate Reel from 3 August at 19:00. The visible library
  reports reach 1, views 1 and viewers 1, with visible likes, comments, shares, saves and follows at 0.
- The confirmed Public Facebook queue is: 4 August 12:30 text prompt; 5 August 18:30 commonplace-book
  photo; 7 August 18:30 product-proof Reel; 9 August 10:00 book-club photo.
- BookQuotes Instagram remains disconnected, so these scheduled items are Facebook-only.
- No item was created, edited, rescheduled or published during the identity switch.

### Live audit: 3 August 2026, 08:01 Europe/London

- Meta Business Suite loads, but the active selector is `ShiftPro, shiftpro.app`; the BookQuotes Page is
  not visibly active. Facebook and Instagram queue, publication, metrics, comments and messages are
  therefore Not verified.
- No Facebook item was created, scheduled, rescheduled or published while the identity remained ambiguous.

The following content is confirmed in Meta Business Suite Planner for the BookQuotes Facebook
Page. Times use the account's Atlantic/Canary setting, which matches Europe/London during this
campaign.

| Date | Time | Format | Topic | Status |
| --- | --- | --- | --- | --- |
| Mon 27 Jul | 18:30 | Reel | Marked-page product proof | Published |
| Tue 28 Jul | 19:00 | Carousel | Annotation reader roll call | Scheduled |
| Wed 29 Jul | 12:30 | Text | What happens to annotations? | Scheduled |
| Thu 30 Jul | 18:30 | Reel | One book, one line | Scheduled |
| Sat 1 Aug | 10:00 | Carousel | Remember more of what you read | Scheduled |
| Sun 2 Aug | 18:00 | Link post | Digital commonplace-book guide | Scheduled |
| Mon 3 Aug | 19:00 | Reel | Annotation debate | Scheduled |
| Tue 4 Aug | 12:30 | Text | The last line copied by hand | Scheduled |
| Wed 5 Aug | 18:30 | Carousel | Ten-minute commonplace ritual | Scheduled |
| Fri 7 Aug | 18:30 | Reel | Find the line | Scheduled |
| Sun 9 Aug | 10:00 | Carousel | Three passages for book club | Scheduled |

All new Reel uploads passed Meta's automatic copyright check. Each new Reel uses its matching
custom cover from `Marketing/Video/Remotion/out/community/`.

No paid boost or advertising was enabled.

The 27 July launch Reel was confirmed in Published content at 19:29 Europe/London. Performance
figures were still at zero immediately after publication and were too early to interpret.

Live audit on 28 July:

- The latest Reel was listed as published at 18:31 on 27 July with 1 view and 0 engagement.
- The Planner contained substantive future entries for 28-30 July and 1 August.
- The Content Library's Scheduled tab reported no scheduled posts at the same time.
- The next daily run must reconcile that Meta discrepancy before assuming those entries will
  publish.

Live audit on 29 July at 10:20 Europe/London:

- The available Meta Content Library showed ShiftPro posts and a ShiftPro content identity, not
  BookQuotes. Its visible performance figures must not be used in BookQuotes reporting.
- BookQuotes Facebook publication and queue status are therefore **Not verified** until the active
  Page identity is visibly switched to BookQuotes and the Planner and Content Library agree.

Live audit on 29 July at 10:35 Europe/London:

- Meta was switched from ShiftPro to the BookQuotes Page and confirmed the active BookQuotes
  identity.
- The `What happens to your annotations when you finish a book?` reader prompt is confirmed
  Published at 12:30 today. Initial figures were 0 across visible measures, which is too early to
  interpret.
- The BookQuotes Content Library Scheduled tab is empty. The planned future queue did not persist
  into the native scheduler and must be rebuilt from the verified campaign assets before relying
  on automatic Facebook publishing.

Live audit on 30 July at 08:20 Europe/London:

- The BookQuotes Scheduled Library still reported no scheduled items at the start of the run.
- A preflighted `One book, one line` Reel was uploaded under the BookQuotes identity, passed
  Meta's copyright check, remained Public, had AI labelling and Boost both off, and was scheduled
  for 18:30 today. Meta displayed `Your post is scheduled`.
- After a reload, the Scheduled Library still displayed no items. Treat the scheduler success
  notice as evidence of intent but do not create a duplicate. This is a verified Meta
  Planner/Library reconciliation failure; the rolling Facebook queue remains under three
  confirmed items.

## Instagram

The `@bookquotes.app` Instagram asset is connected in Graph as `17841434821362428`. The Business
Suite profile editor can still show a verification prompt; that does not block CLI publishing.
A first Graph Reel is live: `https://www.instagram.com/reel/DcCQSLRj430/`. Native insights after
24 hours remain unread. Instagram posts are immediate only. The Facebook 13:00 queue stays
Facebook-only unless a separate `--now` Instagram publish is run.

Once the account is created or recovered and connected:

1. Publish the four vertical Reels natively, using the supplied custom covers.
2. Publish each carousel as a native multi-image post.
3. Add daily Stories around annotation polls, current reads, and one-line challenge check-ins.
4. Review native Instagram performance separately from Facebook after 24 hours and seven days.

## TikTok

### Live audit: 8 August 2026, 08:09 Europe/London

- TikTok Studio Content lists five `@bookquotes.app` posts once and Public. The latest
  `The Three-Body Problem` reader-fit Reel `7670655931193068823` is approximately 58 hours old
  and remains at 0 views, 0 likes and 0 comments. The four earlier posts also show 0 visible views,
  likes and comments.
- TikTok Analytics, Last 7 days, reports 0 video views, profile views, likes, comments and shares;
  traffic source and search-query panels do not have enough data. Settings confirms the account is
  public because the Private account checkbox is off. TikTok Studio comments reports `No comments
  yet`; no replies were made.
- The 72-hour checkpoint for `7670655931193068823` is due at 22:02 Europe/London tonight. No TikTok
  upload, schedule, edit, deletion or reply was made. The native distribution/attributable-analytics
  gate remains unresolved, so no additional post was created to compensate for the zeroes.

### Live audit: 7 August 2026, 08:01 Europe/London

- TikTok Studio Content lists five BookQuotes posts once and Public. The manual `The Three-Body
  Problem` reader-fit Reel `7670655931193068823` is now approximately 34 hours old and remains at
  0 views, 0 likes and 0 comments. The four earlier posts also remain at visible 0 views, 0 likes
  and 0 comments.
- TikTok Analytics reports 0 video views, profile views, likes, comments and shares for the last
  seven days. Traffic source and search-query data say there is not enough data; retention,
  completion, saves, profile visits, follows, link taps, Account Check and attributable analytics
  remain Not available.
- Settings confirms the account is public. The TikTok Studio comments route returned Access Denied in
  this run, so no comment or message review was possible there. No upload, schedule, edit, deletion or
  reply was made while the native validation gate remains unresolved.

### Live audit: 6 August 2026, 08:02 Europe/London

- TikTok Studio Content lists five BookQuotes posts once and Public, including the manual
  `The Three-Body Problem` reader-fit Reel `7670655931193068823`, published 5 August at 22:02.
- The new post is approximately 10 hours old and still shows 0 views, 0 likes and 0 comments. The
  four earlier posts also remain at visible 0 views, 0 likes and 0 comments. Do not treat this as a
  creative verdict or as a 24-hour checkpoint.
- TikTok Analytics still reports 0 video views, profile views, likes, comments and shares for the
  last seven days. Search queries, retention, completion, saves, profile visits, follows, link taps,
  Account Check and attributable analytics remain Not available from the accessible web surfaces.
- Settings confirms the account is public (the Private account control is off). No additional TikTok
  upload, schedule, edit, deletion or reply was made because the native validation gate remains
  unresolved.

### Manual publication: 5 August 2026, 22:02 Europe/London

- Following the user's explicit request, the prepared SF-06 `The Three-Body Problem` reader-fit
  Reel was uploaded once through TikTok Web Studio.
- Content ID: `7670655931193068823`.
- Content Check Lite reported no issues. The post was initially under review and Private; its
  audience was changed once to Public after upload, and TikTok confirmed `Privacy setting has been
  updated`.
- The Content table now lists the post once as Public at 5 August, 22:02. Initial visible metrics
  are 0 views, 0 likes and 0 comments; deeper analytics are not yet available.
- No second TikTok post was created. This was a one-off manual publication and does not activate
  routine automatic TikTok scheduling while the account-health and analytics gate remains unresolved.

### Live audit: 5 August 2026, 08:00 Europe/London

- TikTok Studio Content lists four BookQuotes posts once and Public: `7667570006032387350`,
  `7667846219120626966`, `7667829238065646870` and `7668631665064938774`.
- No new post has appeared since `7668631665064938774` on 31 July at 11:07. Every visible Content
  row reports 0 views, 0 likes and 0 comments. The dashboard reports 0 followers, 0 likes and 0
  following; seven-day video views, profile views, likes, comments and shares are all 0.
- Latest comments says `No comments yet`. Watch time, completion, saves, profile visits, follows,
  link taps, Account Check and attributable analytics remain Not available from the accessible web
  surfaces.
- The Inspiration surface is dominated by unrelated news, entertainment and sports topics. No trend
  was promoted into the BookQuotes queue. Routine TikTok publishing remains gated; no upload,
  schedule, edit, deletion or reply was made.

### Live audit: 4 August 2026, 08:00 Europe/London

- TikTok Studio Content lists four BookQuotes posts once and Public: `7667570006032387350`,
  `7667846219120626966`, `7667829238065646870` and `7668631665064938774`.
- No new post has appeared since `7668631665064938774` on 31 July at 11:07. Every visible Content-table
  row reports 0 views, 0 likes and 0 comments. Dashboard key metrics and Latest comments also show zeros
  and `No comments yet`.
- Account Check, Creator Search Insights, retention, completion, saves, profile visits, follows, link taps
  and attributable analytics are Not available from the accessible web surfaces.
- Routine TikTok publishing remains gated. No upload, schedule, edit, deletion or reply was made.

### Live audit: 3 August 2026, 08:01 Europe/London

- TikTok Studio Content lists four BookQuotes posts once and Public: content IDs `7667570006032387350`,
  `7667846219120626966`, `7667829238065646870` and `7668631665064938774`.
- The visible Content table reports 0 views, 0 likes and 0 comments for every item. The account dashboard
  reports 0 followers, 0 likes and 0 following. Deeper retention and attribution data are Not available.
- No comments or messages were visible and no replies were made.
- Routine TikTok publishing remains gated because publication is evidenced but attributable analytics and
  account-status validation are still missing.

The BookQuotes account is live at `@bookquotes.app`. The profile copy is in place, but the
account still needs conversion to a Business Account in the mobile app.

The first recommendation-led package is ready for approval:

| Format | Topic | Status |
| --- | --- | --- |
| Photo carousel | Five presidential biographies | Held for a later native mobile photo-mode comparison |
| Reel | Five presidential biographies | Scheduled for 29 Jul 2026, 19:30 Europe/London; Public |
| Product Reel | Marked-page product proof | Uploaded draft; not published |

The presidential-biographies Reel is the first scheduled editorial post. Its caption, pinned
comment, source notes and publishing checklist are in `PresidentialBiographiesPost.md`. The user
approved the official publisher covers for this proportionate recommendation and review context.
TikTok Web Studio did not offer photo-mode upload, so the companion Reel was scheduled first and
the carousel is retained for a later native mobile comparison.

### Native Scheduler Validation

The first controlled TikTok post is now present in TikTok Studio:

| Date | Time | Format | Topic | Content ID | Status |
| --- | --- | --- | --- | --- | --- |
| Tue 28 Jul | 19:30 | Reel | Marked-page product proof | `7667570006032387350` | Published once; Public; initial metrics displayed as 0 and no account-level analytics yet available |
| Wed 29 Jul | 08:19 | Reel | Should you read *Team of Rivals*? | `7667846219120626966` | Published once; Public; initial metrics displayed as 0 and no account-level analytics yet available |
| Wed 29 Jul | 19:30 | Reel | Five presidential biographies | `7667829238065646870` | Scheduled for 19:30; Public audience; publication and analytics validation pending |
| Fri 31 Jul | Now | Reel | *The Player of Games* Culture reading route | `7668631665064938774` | Published once; Public audience; Content under review; initial metrics 0 |

The upload is Public, 1080p, uses high-quality uploads and passed Content Check Lite with no
issues. The Studio Content table shows the intended 19:30 time.

Live audit on 29 July at 08:25 Europe/London: the 28 July controlled product Reel and the 29 July
morning recommendation Reel were Public and addressable by distinct content IDs. The planned
19:30 presidential-biographies Reel remained scheduled and Public. The Content table showed zero
initial views, likes and comments for all items; no deeper account-level analytics were available.
TikTok's Business/Advanced Access requirement remains unverified, so routine automated TikTok
publishing remains gated despite the successful native publishing checks.

Live audit on 29 July at 10:20 Europe/London: the first two TikTok Reels were Public and listed
once in Studio. Their visible counts remained 0 views, 0 likes and 0 comments. The presidential
biographies Reel remains scheduled for 19:30 with a Public audience setting. Watch time,
completion, saves, shares, profile visits, follows and link taps were not available in the Content
table.

Live audit on 30 July at 08:20 Europe/London: the three existing TikTok items remain listed once
and Public in Studio. The Content table still displays 0 views, likes and comments for each item.
The account-level analytics entry required to activate routine TikTok automation remains
unavailable, so no further TikTok post was uploaded or scheduled.

Public diagnosis on 30 July at 08:45 Europe/London: each TikTok Reel is directly watchable from
its public URL and no violation, copyright or review warning is visible. The account is public,
in the United Kingdom and allows comments, but has 0 followers and 0 total likes. The three
posts still have literal zero counts. Treat this as a distribution or account-eligibility issue
ahead of creative quality; TikTok automation remains paused until account status and analytics
access are resolved.

Live audit on 31 July: the first sci-fi reading-route Reel was uploaded once through TikTok Web
Studio with content ID `7668631665064938774`. It was initially marked Private while under review;
the audience was changed to Public and Studio confirmed `Privacy setting has been updated`. The
item remains marked `Content under review`, so recommendation distribution and analytics are not
yet evidenced.

Live audit on 1 August at 08:01 Europe/London: TikTok Studio now lists `7668631665064938774` once
as the latest public post, dated 31 July at 11:07. Visible account metrics remain 0 views, 0
likes, 0 comments, with no deeper retention, saves, shares, profile or link data exposed. This
is a distribution/measurement observation, not a creative verdict.

Live audit on 1 August at 08:01 Europe/London: the Facebook Content Library is currently showing
the ShiftPro identity and ShiftPro posts. BookQuotes Facebook metrics, comments, messages and
queue status are therefore not verified in this run. Do not use the visible ShiftPro figures as
BookQuotes evidence; restore the BookQuotes Page identity before the next Facebook reconciliation.

Live audit on 1 August at 09:50 Europe/London: the direct `bookquotes.app` Instagram route is
available but is blocked by Meta's UK ads-choice screen before the public profile can be inspected.
No consent choice was made. Instagram connection, posts, metrics, comments and messages remain
unverified.

Live audit on 2 August at 20:39 Europe/London: TikTok Studio still shows the BookQuotes account at
0 followers, 0 likes and 0 following. The latest public sci-fi Reel remains listed once with 0
views, 0 likes and 0 comments; no comments or deeper analytics are available. Meta Business Suite
returned `Sorry, something went wrong` after reporting that the internet connection was restored,
so Facebook and Instagram identity, queue and performance remain unverified. No new post was
created or scheduled.

After successful publication and an attributable analytics entry, the automation may activate
routine TikTok scheduling under `TikTokOperatingRunbook.md`. Start with one post daily at 19:30.
After seven comparable posts, test a distinct second daily slot on no more than two days in one
week before considering any broader increase.

## Daily Publishing Process

The automatic process is defined in `AutomatedPublishingRunbook.md`. At minimum, every daily run:

1. Confirm the post moved from Scheduled to Published.
2. Reconcile Planner and Content Library status.
3. Check the link preview, attached media and Reel cover on a phone-sized view.
4. Maintain the next seven days of routine Facebook content.
5. Reply to low-risk genuine comments within 24 hours.
6. Record reach, meaningful comments, shares, saves, link clicks and follows.
7. Keep useful reader language for the next campaign iteration.

The full campaign rationale, captions, remaining two-week calendar, and measurement rules are in
`IntensiveCampaign.md`.
