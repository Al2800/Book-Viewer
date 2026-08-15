# BookQuotes Community Push: Publishing Status

Updated: 15 August 2026

## Automation

Routine organic Facebook publishing is now authorised to run automatically under
`AutomatedPublishingRunbook.md`. The daily automation maintains a seven-day queue, verifies
publication, performs preflight and rights checks, and logs every action.

TikTok research, briefing, quality control and learning may run automatically under
`TikTokOperatingRunbook.md`. TikTok publishing and all Instagram activity remain manual until
their account connections and native posting flows have been verified.

The daily `bookquotes-daily-social-check` automation now coordinates both channels at 09:00
Europe/London. Facebook retains its existing routine publishing authority. TikTok performs a
daily evidence and creative-pattern scout, maintains a preparation queue and runs a deeper
experiment and 70/20/10 portfolio review on Mondays.

## Facebook

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
