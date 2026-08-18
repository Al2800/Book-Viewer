# BookQuotes Social Performance Learning Log

Updated: 18 August 2026

## Purpose

This is the durable record of what BookQuotes learns from Facebook, Instagram and TikTok.
Each monitoring run should append evidence here, compare it with earlier observations, and update
the hypothesis register only when the evidence warrants it.

The goal is not to maximise raw views. Prefer downstream value:

- saves and shares;
- meaningful reader comments;
- profile visits and follows;
- link clicks and App Store signals;
- watch completion and repeatable audience language;
- useful product feedback.

## Learning Rules

1. Record the observation before interpreting it.
2. Distinguish platform-wide trends from BookQuotes account evidence.
3. Do not treat one post as proof. Normally require at least three comparable posts or seven days
   of data before raising a hypothesis to high confidence.
4. A publishing failure, rights issue or clearly harmful response can justify immediate action.
5. Compare content by topic, format, hook, posting time and commercial intensity.
6. Keep app-led content near 15% of output unless account evidence supports changing that prior.
7. Routine organic Facebook content may be created, scheduled and published automatically when it
   passes every gate in `AutomatedPublishingRunbook.md`. Sensitive, commercial, legal, ambiguous
   or rights-uncertain content still requires approval.
8. Preserve every historical entry. Correct errors with a dated note rather than rewriting history.

## Hypothesis Register

| ID | Hypothesis | Confidence | Evidence for | Evidence against | Next test |
| --- | --- | --- | --- | --- | --- |
| H1 | Recommendation-led carousels will produce more saves and meaningful comments than app demonstrations. | Medium prior | BookTok is recommendation-led; carousel readers control the pace. | No BookQuotes comparison data yet. | Compare the first three editorial carousels with the first three product Reels. |
| H2 | Specific identity prompts will outperform broad engagement questions. | Medium prior | Reader identities such as underliner, tabber and margin writer invite an easy personal answer. | No BookQuotes comment data yet. | Compare annotation roll-call comments with open-ended reading prompts. |
| H3 | Early evening posts will outperform midday posts for downstream engagement. | Low prior | The initial calendar concentrates visual posts around 18:30-19:00. | No account evidence yet. | Compare similar editorial prompts at midday and early evening. |
| H4 | Practical reading rituals will generate more saves than product-feature explanations. | Medium prior | Checklists and repeatable habits offer durable value independent of the app. | No save data yet. | Compare commonplace-book and reading-memory posts with capture-flow content. |
| H5 | A direct hook in the first three seconds will improve Reel completion. | Medium prior | Current platform guidance emphasises immediate content propositions. | No BookQuotes retention curve yet. | Compare completion and drop-off across the first three Reels. |

Confidence vocabulary: **Low** means a plausible starting assumption; **Medium** means supported by
relevant external evidence or repeated account signals; **High** requires repeatable BookQuotes
account evidence.

## Daily Entry Format

Each run should append:

- date, time and platforms checked;
- content expected, published or failed;
- reach, non-follower reach, views, meaningful comments, shares, saves, watch time, completion,
  profile visits, link clicks, follows and App Store signals where available;
- new comments, messages and recurring audience language;
- routine replies made and drafts awaiting approval;
- trend signals relevant to readers, BookTok, biographies, history, annotation or reading habits;
- hypothesis updates with the evidence and confidence change;
- one or two next actions, clearly distinguishing automatic routine work from anything requiring
  approval.

Use `Not available` rather than zero when a platform does not expose a metric.

## Entries

### 18 August 2026, 09:01 Europe/London

**Platforms checked:** Meta Business Suite BookQuotes Published and Scheduled Content Library,
Facebook comments, Instagram comments and Direct; TikTok Studio dashboard, native Recent posts,
Inspiration and Account Check.

**Observation**

- Facebook Published shows the 17 August 13:10 post `122108480163415831` at reach 1, views 0,
  viewers 0, interactions 0, likes 0, comments 0, shares 0, saves 0 and follows 0. Watch time and
  link clicks are Not available. A separate 17 August 13:00 prompt `122108480745415831` is also
  visible with all exposed metrics at zero.
- Facebook Scheduled shows only two Public Facebook-only, unboosted rows, both at 18 August 13:00.
  This conflicts with the older logged 15-item bank queue. The queue was not edited or extended
  while the native state was contradictory.
- Instagram's latest published item is the presidential-biographies Reel
  `17905441377304338`, published 17 August at 11:54. The current native read-back is 32 views,
  26 reach, 38 seconds watch time and 1 second average play time; visible interactions, likes,
  comments, shares and saves are 0. The current row does not expose follows, saves or link clicks.
- TikTok Recent posts shows `7674952452055076118` once as Public at
  `https://www.tiktok.com/@bookquotes.app/video/7674952452055076118`, published 17 August at
  11:55. The row reads 855 views, 2 likes and 0 comments. The five older BookQuotes rows remain at
  0 views, 0 likes and 0 comments. This is the first non-zero attributable native TikTok result.
- The TikTok Account Check URL resolved to the signed-in Studio surface with no visible warning or
  restriction text, but no formal account-health report was exposed. Treat that as a limitation,
  not as a guarantee that no restriction exists.
- Facebook comments, Instagram comments/Direct and TikTok comments were empty. No routine reply
  was made. App Store downloads, activations and sales remain Not available.

**Interpretation and decision**

- The TikTok distribution and attribution blocker has materially eased: one post is Public once and
  has a native addressable analytics entry. That does not yet establish a creative winner; the
  Commonplace Reel has only one meaningful result.
- Activate the TikTok establishment phase at one reader-first post per day at 19:30 Europe/London,
  maintaining the 60/20/15/5 mix. The next eligible prepared item is Category Reel `cr-01` (Player
  of Games) on 19 August. Do not introduce a second daily slot until seven comparable posts have
  data.
- Keep Facebook at one primary item per day, but do not schedule into the contradictory native
  queue until its saved rows are reconciled. Do not infer topic failure from Facebook zeroes or the
  small Instagram Reel sample.
- No hypothesis confidence or result label changed. The next useful comparison is distribution and
  downstream value across the first seven TikTok establishment posts.

**Next actions**

- Reconcile the Facebook Scheduled Library against the bank before adding the missing future days.
- Let the TikTok reconnect job refresh the expiring token, then advance `cr-01` through the full
  evidence, rights and phone-sized preflight gates for the 19 August 19:30 slot.
- Keep all sensitive, billing, privacy, account-health and App Store replies drafted for review;
  none are currently awaiting approval.

### 13 August 2026, Meta write-scope incident

**Platforms checked:** BookQuotes-only Graph CLI against Page `1246405755221229` and Instagram
`17841434821362428`.

**Observation**

- A refreshed user token now grants Facebook and Instagram write names:
  `pages_manage_posts` and `instagram_content_publish`, plus
  `instagram_manage_comments`. Read scopes remain granted. Identity is still
  `api_identity_verified` for BookQuotes / `bookquotes.app`.
- Facebook listing still returns 19 owned posts. Instagram listing still returns 0 published
  media items.
- A probe `update --approve` executed against the live 13 August 13:00 post
  `1246405755221229_122107333143415831` and replaced its caption with `dry-run-only`.
  That was an operator error, not a publishing decision. The original caption is not in the
  repo.

**Interpretation and decision**

- Token auth now covers Facebook and Instagram for the bound BookQuotes assets.
- Facebook and Instagram publication remain review-gated. The runtime policy still has
  `writes_enabled` false. Instagram published-media edit remains unsupported.
- Restore the 13 August caption from Meta Business Suite before any creative read-back of
  that post.

**Next actions**

- Restore post `1246405755221229_122107333143415831` from Business Suite edit history.
- Keep `--approve` off unless a specific, rights-cleared mutation is requested.

### 13 August 2026

**Platforms checked:** Meta Business Suite BookQuotes Page, Published and Scheduled Content
Library, Facebook comments and Inbox; TikTok Studio dashboard, Content and Account Check routes;
Meta Business Suite Instagram asset.

**Observation**

- Facebook's 12 August `Try the 24-hour highlight test` prompt is Published once at 13:00. The
  initial native read-back shows reach 1, visible views, viewers, follows, interactions, likes,
  comments, shares, saves and link clicks at 0, with watch-time fields Not available. The queue is
  reconciled and contains one Public, Facebook-only, unboosted item per day from 13 through 18
  August at 13:00 Europe/London.
- Facebook comments reports `No comments` and Inbox shows no message requiring action. No routine
  reply was made and no approval-required draft is outstanding.
- TikTok Studio was initially readable as `@bookquotes.app` and showed 1 account-level video view
  in the last seven days; profile views, likes, comments and shares were 0. The view is not
  attributable to a content ID. The Content and Account Check routes then returned `Access Denied`.
- The last readable TikTok recent-post surface still showed the 5 August `The Three-Body Problem`
  Reel and the 31 July Culture Reel. No TikTok post has been added since 5 August. Instagram's
  `@bookquotes.app` asset is visible in Meta Business Suite, but profile editing is blocked by
  account verification and no Instagram publication or performance data is verified.

**External signals**

- TikTok's [Creative Center guidance](https://ads.tiktok.com/help/article/creative-center) remains
  the authoritative place to inspect current trends, keywords, creative patterns and best
  practices. The logged-in Inspiration surface was dominated by unrelated news and entertainment
  topics today, so no generic trend was promoted into the BookQuotes queue.
- TikTok's [BookTok 2026 summer reading list](https://newsroom.tiktok.com/the-booktok-communitys-2026-summer-reading-list?lang=en)
  reports more than 80 million global #BookTok posts as of 1 June 2026. This supports the reader
  community as a durable context, not a reason to change BookQuotes cadence without account data.

**Interpretation and decision**

- Facebook is operational: the identity, publication, queue, privacy and no-boost checks agree.
  The one reach signal is too small for a creative or timing decision; continue the existing
  reader-led queue.
- TikTok has moved from literal account-level zero to one un-attributed view, but this is still a
  distribution and measurement blocker. Do not classify any creative, activate routine posting or
  move to two posts per day from this signal.
- Instagram is connected at the Business Suite asset level but not operationally verified for
  profile editing or publishing. Keep Instagram manual and separate from Facebook reporting.
- No hypothesis confidence or experiment result label changed.

**Next actions**

- Keep Facebook's six-day verified queue and collect the 12 August prompt's 24-hour read-back on
  the next run.
- Restore TikTok's native Content and Account Check access, then require one attributable post
  analytics entry before any new upload or cadence increase.
- Complete Meta's Instagram account-verification step manually before profile changes or Instagram
  publishing are attempted.

### 14 August 2026, 08:09 Europe/London

**Platforms checked:** Meta Business Suite BookQuotes Page, Published and Scheduled Content
Library, Facebook comments and Inbox; TikTok Studio dashboard and account-check route; Meta Business
Suite Instagram account settings.

**Observation**

- The 13 August 13:00 Facebook item published once, but the Published table displays the
  placeholder caption `dry-run-only` for content ID `122107333143415831`. Native visible metrics are
  reach 2, views 2 and viewers 2; interactions, likes, comments, shares, saves, follows and link
  clicks are 0, and watch-time fields are Not available. This invalidates creative interpretation
  of that item until its intended caption is restored.
- The Facebook queue remains healthy at five future Public, Facebook-only, unboosted items for 14
  through 18 August at 13:00 Europe/London. No duplicate, comment or message was found.
- TikTok Studio initially read `@bookquotes.app` and showed 1 un-attributed account-level video view
  in the last seven days, with profile views, likes, comments and shares at 0. The account-check
  route redirected to the dashboard and did not provide an account-health result. The visible
  recent-post surface still contains the Three-Body Problem and Player of Games posts; no new
  TikTok post has been verified since 5 August.
- Meta Business Suite settings shows the connected `@bookquotes.app` Instagram asset, but profile
  editing remains verification-gated and no Instagram publication or native performance data is
  verified.

**Interpretation and decision**

- Facebook distribution is measurable at a very small level, but the placeholder caption is a
  content-integrity blocker. Do not use the 2-reach/2-view signal to judge the creative, and do not
  mutate the live post automatically.
- TikTok remains a distribution and measurement blocker, not evidence that the current science-
  fiction creative is bad. Keep publishing and the two-a-day cadence paused.
- Instagram is connected at the asset level but not operationally verified for profile editing or
  publishing. Keep it separate from Facebook reporting.
- No hypothesis confidence or experiment result label changed.

**Next actions**

- Restore the 13 August Facebook caption through an approved Business Suite edit-history action,
  then capture a corrected read-back before using the post in learning comparisons.
- Keep the Facebook queue running while treating the placeholder item as an incident; do not use
  the CLI `--approve` path for testing.
- Restore TikTok Content/Account Check access and require one attributable post analytics entry
  before any upload or cadence increase.
- Complete Meta's Instagram account-verification step manually before profile changes or Instagram
  publishing are attempted.

### 15 August 2026, 09:04 Europe/London

**Platforms checked:** Meta Business Suite BookQuotes Published and Scheduled Content Library,
Facebook and Instagram comments/Inbox, Instagram account settings; TikTok Studio dashboard, recent
posts and account-check route.

**Observation**

- The scheduled Facebook text item for 14 August published once at 13:00 as content ID
  `122107651779415831`. Visible native reach, views, viewers, interactions, likes, comments,
  shares, saves, follows and link clicks are all 0; watch-time fields are Not available.
- An additional Facebook Reel published at 12:47 as `122107649667415831` and also has visible
  metrics at 0. This resulted in two primary Facebook items on 14 August and is logged as an
  extra-slot observation, not as evidence for a higher routine cadence.
- The 13 August Facebook placeholder incident remains live: `dry-run-only`, reach 2, views 2,
  viewers 2, all other visible engagement 0. The caption was not changed. The future queue has
  four Public Facebook-only items for 15 through 18 August at 13:00, below the seven-day target
  but above the three-day alert threshold.
- Meta Published read-back confirms three Instagram Reels. The 14 August 22:15 Commonplace Ritual
  Reel has reach 27 and views 31, with viewers/watch-time Not available and visible engagement 0.
  The 15 August 08:12 intro Reel and the 08:21 library-cover variant each show 0 views so far;
  reach/viewers/watch-time are Not available at this early checkpoint. The two intro variants share
  overlapping core copy and require a duplicate-candidate review before further Instagram posting.
- Facebook and Instagram comments show no comments. No Instagram direct message requiring action
  was visible. No routine reply was made.
- TikTok Studio still shows only two BookQuotes posts, latest 5 August at 22:02. The dashboard
  shows one account-level video view, profile views/likes/comments/shares 0, and no attributable
  content ID. The 14 August adapter attempt failed with `Daily active user quota reached` before
  TikTok created a content ID. The account-check route redirected to the dashboard and returned
  placeholder metrics.

**Interpretation and decision**

- Facebook has functioning native publication, but the extra same-day Reel means the current output
  should not be used to justify a higher cadence. The queue needs rebuilding toward the seven-day
  target without duplicating or silently editing the live placeholder.
- Instagram now has a measurable early signal on the first test Reel, but the two later intro posts
  are too new and not a clean comparison because their copy overlaps. Do not infer a winner or
  automatically delete either post.
- TikTok remains a native distribution and measurement blocker. The adapter quota failure is an
  operational failure, not a creative verdict, and does not satisfy the runbook's native validation
  gate. Keep TikTok posting and the two-a-day cadence paused.
- No hypothesis confidence or experiment result label changed.

**Next actions**

- Restore the 13 August Facebook caption through an approved Business Suite edit-history action.
- Rebuild the Facebook queue beyond 18 August only after checking for concurrent scheduler writes;
  do not create a duplicate 15 August item.
- Treat the 14 August Instagram Reel as the first early baseline, wait for 24-hour read-back on the
  two intro variants, and review the duplicate candidate manually before any further Instagram
  publishing.
- Resolve TikTok's native account/content access and quota state, then require one attributable
  native post analytics entry before retrying or increasing cadence.

### 17 August 2026, 09:03 Europe/London

**Platforms checked:** Meta Business Suite BookQuotes Published and Scheduled Content Library,
Facebook comments and Instagram comments/Direct; TikTok Studio dashboard, native Recent posts and
Account Check.

**Facebook seven-day review**

- The 16 August reading-reset prompt published once at 13:01 as content ID
  `122108191239415831`. At the 24-hour-plus checkpoint, visible reach, views, viewers,
  interactions, comments, shares, saves, link clicks and follows are all 0; watch-time fields are
  Not available.
- The visible seven-day sample remains distribution-starved: the 13 August placeholder is still
  at 2 reach / 2 views / 2 viewers, the 14 August text and extra Reel are at 0, the 15 August
  reading-list prompt is at 0, and the 16 August reading-reset prompt is at 0. Non-follower reach,
  meaningful comments, shares, saves, profile visits, link clicks, follows and App Store signals are
  Not available or zero where the native table exposes them.
- The Scheduled Library contains only two future Public Facebook-only, unboosted items: 17 and 18
  August at 13:00. The queue is therefore shorter than the three-day alert threshold and below the
  seven-day target. No replacement was scheduled while the `dry-run-only` caption incident and
  concurrent publishing path remain unresolved.
- No Facebook comments or Instagram comments/Direct messages were visible. No routine reply was
  made.

**Facebook interpretation and decision**

- There is no defensible strongest or weakest creative by downstream value: every recent item has
  either near-zero distribution or an unresolved publication-integrity confound. Do not classify the
  reading prompt, reset prompt or Reel as a topic or format failure.
- Keep the Facebook cadence at one primary item per day. Do not increase to two daily items until
  the placeholder caption is restored through approved Business Suite edit history and the queue is
  reconciled in the Scheduled Library.

**Instagram supporting read-back**

- Three Reels remain live. The 14 August Commonplace Reel reads 41 reach / 44 views; the 15 August
  08:12 intro reads 12 / 12; and the 08:21 library-cover intro reads 7 / 7. Visible likes,
  comments, shares, saves and follows remain 0, while viewers, completion and full retention are
  Not available. The two intro variants still overlap in copy, so this is not a clean comparison.

**TikTok seven-day review**

- Native Recent posts now lists five Public BookQuotes videos, correcting the earlier incomplete
  inventory: the 28 July marked-page product Reel, two 29 July biography Reels, the 31 July Player
  of Games route, and the 5 August Three-Body Problem route (`7670655931193068823`). There has
  been no new TikTok post since 5 August.
- All five native rows show 0 views, 0 likes and 0 comments. Native reach, viewers, watch time,
  completion, saves, shares, profile visits, follows and link taps are not exposed in the current
  Content view. The dashboard key metrics remain `--`, and the Account Check route now returns
  Access Denied rather than an account-health result. A separate Zernio health read reports synced
  analytics access, but that does not replace the required native account-health and attributable
  read-back gate.
- No post can be ranked as strongest or weakest. The zeros are evidence of absent visible
  distribution, not evidence that the creative topic failed. No confidence or experiment result
  label changed.

**TikTok portfolio and next test**

- Keep the preparation portfolio at 70% reader-fit/use-condition recommendations, 20% adjacent
  history, culture and annotation bridges, and 10% controlled native-photo/slideshow/audio tests.
- Publishing and the proposed two-a-day cadence remain paused until the native account check and
  attributable analytics gate is clear. The 14 August Zernio attempt remains a quota failure with
  no TikTok content ID; it must not be counted as a creative result or duplicated.

**App Store and attribution**

- No new App Store outcome signal is available. The current authorized read path still lacks
  App Analytics, Sales and Finance report access, so downloads, activations, sales and proceeds are
  not inferred from social zeros.

**Next actions**

- Restore the 13 August Facebook caption through an approved Business Suite edit-history action,
  then extend the queue only after the Scheduled Library confirms each saved item.
- Keep the Instagram duplicate candidate for manual review; do not delete or publish another Reel
  automatically.
- Reconnect or verify the TikTok/Zernio account before its reported token expiry, then require one
  attributable native post analytics entry before any retry or cadence increase.

### 16 August 2026, 09:02 Europe/London

**Platforms checked:** Meta Business Suite BookQuotes Published and Scheduled Content Library,
Facebook and Instagram comments/Inbox, Instagram account settings; TikTok Studio dashboard, recent
posts and account-check route.

**Observation**

- The 15 August Facebook reading-list prompt published once at 13:01 as content ID
  `122107908201415831`. Visible reach, views, viewers, interactions, likes, comments, shares,
  saves, follows and link clicks remain 0; watch-time fields are Not available.
- The 13 August `dry-run-only` placeholder remains live at reach/views/viewers 2/2/2, and the 14
  August text plus extra Reel remain at visible zeroes. The future Facebook queue is now three
  Public Facebook-only items for 16 through 18 August at 13:00, below the seven-day target but at
  the three-day threshold. No new schedule item was created while the concurrent publishing path
  and caption incident remain under review.
- Instagram read-back now shows reach/views of 41/44 for the 14 August Commonplace Ritual Reel,
  12/12 for the 15 August 08:12 intro Reel and 7/7 for the 08:21 library-cover variant. Visible
  engagement is 0 across all three. Viewers, completion, saves and full retention details are Not
  available. The two intro variants continue to share overlapping copy and are not a clean A/B test.
- Facebook and Instagram comments are empty, and Instagram Direct shows no messages. No routine reply
  was made.
- TikTok still has only two native BookQuotes posts, latest 5 August. The dashboard remains at one
  unattributed account-level video view and zero profile views, likes, comments and shares. The
  account-check route redirects to the dashboard without account-health evidence. No TikTok upload,
  schedule, edit, deletion or reply was made.

**Interpretation and decision**

- Facebook publication is functioning, but zero engagement across recent items and the unresolved
  placeholder mean there is no basis for increasing the Facebook cadence or judging the creative.
  The queue needs replenishing toward seven days after the concurrent write path is reconciled.
- Instagram has the first measurable reach signal, but no downstream engagement or retention data.
  Treat the 14 August Reel as an early baseline only; do not call the two intro variants a winner or
  delete either automatically.
- TikTok remains an access, distribution and attribution blocker. The two-a-day cadence stays paused.
- No hypothesis confidence or experiment result label changed.

**Next actions**

- Restore the 13 August Facebook caption through an approved Business Suite edit-history action and
  reconcile the scheduler before extending the queue.
- Wait for fuller Instagram retention data and manually decide whether the duplicate intro variant
  should remain live.
- Resolve TikTok account-health and quota state, then require one attributable native post entry
  before retrying publication.

### 12 August 2026

**Platforms checked:** Meta Business Suite BookQuotes Page, Published and Scheduled Content
Library, and Facebook comments; TikTok Studio Content, Analytics, Settings and comments.

**Observation**

- Facebook's 11 August reading-life prompt published once at 13:00. Native visible metrics remain
  0 for reach, views, viewers, follows, interactions, likes, comments, shares, saves and link
  clicks; watch-time fields are Not available. The future queue reads back one Public,
  Facebook-only, unboosted item per day from 12 to 18 August at 13:00.
- TikTok `@bookquotes.app` still has five Public posts, latest 5 August at 22:02. All visible
  post-level counts and the Last-7-days account analytics remain 0; retention, completion, saves,
  profile visits, follows, link taps and attributable post analytics are Not available. Comments
  reports `No comments yet`. Settings confirms the account is public, but the available web Creator
  Tools menu exposes Analytics only and does not expose Account Check.
- Instagram remains disconnected. Facebook comments remains empty.

**Interpretation and decision**

- No Facebook creative conclusion is possible from zeroes at this volume. Continue the verified
  queue and wait for comparable downstream signals.
- TikTok remains a distribution and measurement blocker, not a verdict on the science-fiction or
  biography creative. Do not upload, schedule, or increase to two daily posts until a controlled
  post has attributable views and normal analytics.
- No hypothesis confidence or experiment result label changed.

**Next actions**

- Reconcile the 12 August Facebook publication and collect its 24-hour metrics on the next run.
- Keep TikTok publishing paused; check Account Check from the native mobile/creator surface if the
  user can access it, then retry one controlled post only after analytics attribution is visible.

### 11 August 2026

**Platforms checked:** Meta Business Suite BookQuotes Page, native Scheduled Library and Facebook
Inbox/comments; TikTok Studio Content, Analytics, Settings and comments.

**Observation**

- Facebook native reconciliation caught and corrected a date-placement error. The repaired queue
  now reads back one Public, Facebook-only, unboosted item per day from 11 to 18 August at 13:00
  Europe/London. A duplicate copy of the 13 August margin-notes prompt was deleted; the valid item
  remains once.
- TikTok account `@bookquotes.app` lists five Public posts once. The latest is the
  `The Three-Body Problem` reader-fit Reel, content ID `7670655931193068823`, published 5 August
  at 22:02. Visible post and Last-7-days account metrics are all 0; deeper distribution and
  retention measures are Not available. TikTok comments reports no comments.
- Instagram is still disconnected. Facebook comments reports no comments and Inbox shows no
  message requiring action.

**Interpretation and decision**

- The Facebook issue was operational and is resolved for the current queue; future runs must always
  verify native row date, privacy, identity and duplication after each reschedule or delete.
- TikTok zeroes cannot distinguish failed distribution from an empty account signal because the
  attributable analytics surface is still unavailable. Do not classify the science-fiction topic,
  Reel packaging or cadence as a creative failure and do not start two-a-day publishing yet.
- No hypothesis confidence or experiment result label changed. Instagram has no measurable data.

**Next actions**

- Keep the verified Facebook queue running and collect the first 24-hour reach, views, comments,
  shares, saves, profile visits, link clicks and follows for each published item.
- Resolve TikTok account-health/analytics attribution before another upload or schedule action;
  inspect the native Account Check surface and verify that a new post receives non-zero attributable
  views before increasing cadence.

### 8 August 2026, 08:09 BST

**Platforms checked:** Meta Business Suite BookQuotes Page, Content Library, Scheduled Library and
Inbox; TikTok Studio Content, Analytics, Settings and comments; official TikTok Creative Center
guidance.

**Publishing and measurement**

- Facebook identity is confirmed as BookQuotes. The 7 August `Find the line` Reel is published once
  at 18:30 with content ID `122105782647415831`; visible metrics remain 0. The 8 August reader
  prompt is listed in Published at 13:00 with visible metrics 0. Native Scheduled Library read-back
  confirms three future Public items: 9 August 10:00 book-club carousel, 10 August 13:00 text prompt,
  and 11 August 13:00 text prompt. Facebook Inbox showed no new messages or comments.
- TikTok lists five Public posts once. `7670655931193068823` is approximately 58 hours old with
  0 views, 0 likes and 0 comments. Last-7-days Analytics is 0 for video views, profile views, likes,
  comments and shares; traffic source and search queries have insufficient data. Settings is public
  and comments reports `No comments yet`.
- TikTok's 72-hour checkpoint is due at 22:02 tonight. Deeper retention, completion, saves, profile
  visits, follows, link taps and attributable post analytics remain Not available.

**Learning and decision**

- No hypothesis or result label changed. The zeroes are account evidence, but without attributable
  analytics they remain a distribution/measurement blocker rather than evidence that the Reel,
  science-fiction topic or packaging has failed.
- TikTok native research remains constrained: current official guidance explains that Creative Center
  Trends can be filtered by industry/time and inspected for trendlines, related videos, audience
  insights and regional popularity, but no comparable current UK BookTok sample was accessible in
  this run. No style-catalogue entry was added. Sources: `https://ads.tiktok.com/help/article/how-to-use-trends`
  and `https://ads.tiktok.com/help/article/creative-center`.

**Next actions**

- Read the TikTok 72-hour checkpoint tonight, then keep or change the gate based on attributable
  evidence rather than posting volume.
- Let the Facebook queue run through 11 August and compare downstream actions when non-zero data
  arrives. Instagram remains unconnected and has no verified publishing or measurement state.

### 7 August 2026, 21:45 BST

**Platforms checked:** Meta Business Suite BookQuotes Page, Content and Insights; Google Search
Console `bookquotes.uk` Sitemaps; public domain/SEO endpoints.

**Publishing and measurement**

- Meta is visibly operating as the `BookQuotes` Page, which has 0 followers. Instagram remains
  unconnected.
- The 28-day Insights overview (10 July-6 August) reports 19 views, 3 new viewers and 100% of the
  visible audience as non-followers. The account sample remains too small for format or timing
  conclusions.
- The Content insights table shows the 3 August annotation-debate Reel at reach 1, view 1 and viewer
  1. The 4-7 August items display zero visible reach/views at the inspected checkpoints. The
  7 August `Find the line` Reel is present once as Published after its 18:30 slot.
- Google Search Console already contains `https://bookquotes.uk/sitemap.xml`, submitted and last read
  on 7 August with status `Success`, 15 discovered pages and 0 discovered videos. It was not
  submitted again. Before the approved action, URL Inspection reported the homepage as unknown to
  Google. The homepage indexing request then completed once and Google added it to the priority
  crawl queue; this is a request state, not evidence that indexing has completed. Performance is
  still processing and shows no clicks or impressions.
- The live canonical HTTPS homepage, robots file and all 15 sitemap URLs pass. HTTP currently serves
  200 without a redirect and `www.bookquotes.uk` does not resolve; these are deployment/domain
  defects, not search-content results.
- No Meta post was created, scheduled, edited, deleted or replied to in this audit. The next
  rights-safe Facebook execution is preflighted in `FB001HighlightTest.md` but remains a draft until
  the native Scheduled Library can be read back.

**Learning and decision**

- There is still insufficient distribution to classify any content treatment. Do not raise cadence
  or label a creative winner/loser.
- Search instrumentation is active enough to begin collecting evidence, but no query/page
  performance claim should be made until Search Console exposes it.
- Structured evidence and deterministic scorecard generation now live in `GrowthEvidence.json`,
  `GrowthOperatingSystem.md` and `GrowthScorecard.md`. Narrative logs remain the audit trail.

**Next actions**

- Deploy and verify canonical HTTP/`www` redirects, then rerun the host matrix.
- Schedule FB-001 once only after BookQuotes identity, Planner and Scheduled Library are available
  together; read back the native entry before changing its structured status from `draft`.
- Record the 24-hour and 72-hour `Find the line` checkpoints without treating zero reach as a
  creative verdict.

### 7 August 2026, 08:01 BST

**Platforms checked:** Meta Business Suite BookQuotes Published, Scheduled, Planner and Facebook
Inbox/comments; TikTok Studio Content, Analytics, Settings and comments route; official TikTok
Creative Center sources.

**Publishing and measurement**

- Facebook's 6 August reader prompt is Published once at 13:00 with content ID
  `122105430807415831`. Visible reach, views, viewers, follows, interactions, likes, comments,
  shares, saves and link clicks are all 0; watch-time and other unavailable cells remain Not
  available.
- The confirmed Facebook queue now covers 7 August 18:30 (`Find the line` Reel), 8 August 13:00
  (new text prompt) and 9 August 10:00 (book-club carousel). All three are Public, Facebook-only,
  and visible in the native Scheduled Library. No boost, story share or cross-post is enabled.
- Facebook Inbox and Facebook comments show no comments or messages. No replies were made.
- TikTok's `7670655931193068823` is approximately 34 hours old and remains at 0 views, likes and
  comments. The four older posts remain at visible zeroes. Analytics still shows 0 video views,
  profile views, likes, comments and shares, with no traffic-source or search-query data.
- TikTok Settings confirms the account is public. The TikTok Studio comments route returned Access
  Denied, so comments and messages are Not available rather than zero. No further TikTok publication
  was attempted.

**Learning and decision**

- The new post has now passed the 24-hour-plus checkpoint without attributable distribution. This
  strengthens the account-state or measurement-blocker interpretation, but still does not establish
  that the reader-fit creative failed. No hypothesis confidence or experiment result label changed.
- Official Creative Center material continues to support search-shaped reader questions, useful
  explanations and comment-led participation as the next packaging priors. The indexed `#reading`
  result is region- and time-sensitive and was not treated as current UK performance evidence.

**Next actions**

- Do not publish, schedule, edit or delete another TikTok post until Account Check and attributable
  analytics are available. Recheck the 72-hour checkpoint after 8 August 22:02 BST.
- Monitor the Facebook 7-9 August queue and record live URLs and metrics after publication.

### 6 August 2026, 08:02 BST

**Platforms checked:** Meta Business Suite BookQuotes Planner, Scheduled and Published content,
Inbox and Facebook comments; TikTok Studio Content, Analytics and Settings; official TikTok Creative
Center and TikTok Next 2026 sources.

**Publishing and measurement**

- Facebook's 5 August commonplace carousel is Published with visible reach 0 and views 0. The
  missing 6 August slot was scheduled once as the Public text prompt `A reading habit you abandoned?`
  for 13:00 Europe/London. The 7 August product Reel at 18:30 and 9 August book-club carousel at
  10:00 remain Scheduled and Public. No boost, story share or cross-post was enabled.
- Facebook comments and Inbox show no comments or messages. No replies were made.
- TikTok lists five Public posts once. The 5 August `The Three-Body Problem` post
  (`7670655931193068823`) is approximately 10 hours old and remains at 0 visible views, likes and
  comments. TikTok Analytics remains at 0 for the last seven days, with deeper measures unavailable.
- TikTok Settings confirms the account is public. Account Check, search-query data, retention,
  completion, saves, profile visits, follows, link taps and attributable analytics remain Not
  available. No further TikTok publication was attempted.

**External signals and learning**

- TikTok's official 2026 trend report emphasises unfiltered process and shared experience, search-led
  curiosity journeys, comments as a creative surface and honest reviews that explain why something is
  worth attention. These are useful packaging priors for reader-fit checks, behind-the-scenes capture
  demonstrations and specific book questions, not evidence of BookQuotes performance.
- No hypothesis confidence changed. TikTok's zero distribution remains a measurement or account-state
  blocker, not a creative verdict. Instagram remains unconnected to the BookQuotes Meta portfolio.

**Next actions**

- Recheck TikTok at the actual 24-hour point for `7670655931193068823`; do not compensate for early
  zeroes by creating a second post.
- Keep the Facebook queue under native reconciliation and continue the evidence-led TikTok research
  queue without routine publication until Account Check and attributable analytics are available.

### 5 August 2026, 22:02 BST

**Platforms checked:** TikTok Studio Content after an explicit one-off user request to publish.

**Publishing and measurement**

- The prepared SF-06 `The Three-Body Problem` reader-fit Reel was uploaded once under
  `@bookquotes.app` with content ID `7670655931193068823`.
- Content Check Lite reported no issues. The post entered review as Private, was changed once to
  Public, and TikTok confirmed the privacy update. The Content table lists it once as Public at
  22:02.
- Initial visible metrics are 0 views, 0 likes and 0 comments. Watch time, completion, saves,
  shares, profile visits, follows, link taps and attributable analytics are Not available.

**Learning and decision**

- No experiment confidence changed. The initial zeroes are an immediate post-publication checkpoint,
  not a creative verdict.
- This was an explicit one-off manual publication. Routine two-per-day TikTok scheduling remains
  paused until Account Check and attributable analytics are available.

### 5 August 2026, 08:00 BST

**Platforms checked:** BookQuotes Facebook Content Library, Scheduled tab, Inbox and Facebook
comments; TikTok Studio Content and dashboard.

**Publishing and measurement**

- Facebook is confirmed under the `BookQuotes` identity. The 4 August hand-copied-lines text post
  is Published at visible reach 0 and views 0. The 3 August annotation-debate Reel remains at reach
  1 and views 1, with visible likes, comments, shares, saves and follows at 0; some secondary cells
  were still loading.
- Facebook has three confirmed future Public items: commonplace carousel on 5 August at 18:30,
  `Find the line` product Reel on 7 August at 18:30, and book-club carousel on 9 August at 10:00.
  The queue has gaps on 6 and 8 August and does not yet represent a full rolling daily queue.
- Facebook Inbox shows no messages and Facebook comments shows no comments. No replies were made.
- TikTok still lists four Public posts once. All visible post counts remain 0 views, 0 likes and 0
  comments; the dashboard remains 0 followers, 0 likes and 0 following. Deeper retention and
  attributable analytics are Not available.

**Learning and decision**

- No confidence changed. Facebook has too little downstream signal to distinguish format or timing;
  TikTok's literal zero distribution remains an account-health or measurement blocker rather than a
  creative verdict.
- The current TikTok Inspiration surface is dominated by unrelated news, entertainment and sports.
  No trend was adopted. Continue the reader-first queue only after native Account Check and
  attributable analytics are evidenced.
- No external publishing action was taken on TikTok. Keep the Facebook queue under review and fill
  the 6 and 8 August gaps only with a fully preflighted, rights-cleared item.

### 4 August 2026, 08:00 BST

**Platforms checked:** TikTok Studio Content and dashboard; Meta Business Suite; current TikTok
BookTok search and official Creative Centre.

**Publishing and measurement**

- TikTok Studio Content still lists four BookQuotes posts once, all Public. The newest is *The Player
  of Games*, published 31 July at 11:07. No new BookQuotes post has appeared since then.
- The four visible Content-table rows remain at 0 views, 0 likes and 0 comments. The dashboard reports
  0 likes, 0 followers and 0 following; its seven-day key metrics show 0 video views, 0 profile views,
  0 likes, 0 comments and 0 shares. Latest comments says `No comments yet`.
- Watch time, completion, saves, shares beyond the visible counters, profile visits, follows, link taps,
  Account Check and attributable account analytics: Not available from the accessible web surfaces.
- Meta Business Suite remains active as `ShiftPro, shiftpro.app`, with Facebook and Instagram followers
  displayed as 0. BookQuotes Facebook and Instagram queue, posts, metrics, comments and messages remain
  Not verified.
- No post was uploaded, scheduled, edited, deleted or replied to in this run.

**Learning and decision**

- No hypothesis confidence changed. The zero-count TikTok account is still a distribution or measurement
  blocker, not a creative verdict.
- Current BookTok search examples reinforce specific reader situations, direct questions, recognisable
  recurring series, comfort or humour framing, and creator-owned voice. These are transferable structures,
  not evidence that any one trend or audio should be copied.
- Do not bulk-publish the prepared sci-fi or recommendation queue. Account Check and attributable
  analytics must be evidenced first.
- Facebook automation remains paused until Meta visibly switches to BookQuotes and Planner and Content
  Library reconcile under that identity.

**Next actions**

- Complete TikTok Account Check and Creator Search Insights in the mobile app before the next upload.
- Resolve the Meta identity selector, then recheck the BookQuotes Content Library and Planner.
- Continue research and production planning only; no new social publishing was authorised by the evidence.

### 4 August 2026, Meta identity resolution

**Platforms checked:** Meta Business Suite BookQuotes Content Library and Scheduled tab.

**Identity and publishing**

- Following the user's explicit authorisation, Meta Business Suite was switched from `ShiftPro,
  shiftpro.app` to the `BookQuotes` Facebook Page.
- The BookQuotes Published library is now visible. The latest item is the annotation-debate Reel,
  published 3 August at 19:00, with visible reach 1, view 1 and viewer 1; visible likes, comments,
  shares, saves and follows are 0.
- The Scheduled tab now shows four Public BookQuotes items: 4 August 12:30 text prompt, 5 August
  18:30 commonplace-book photo, 7 August 18:30 product-proof Reel, and 9 August 10:00 book-club
  photo. No duplicate was created during the identity switch.
- BookQuotes Instagram is still not connected to the Meta portfolio. The current queue is Facebook-only.

**Decision**

- The Facebook identity gate is now resolved and the existing queue can be monitored under BookQuotes.
- Keep Instagram publishing paused until a BookQuotes Instagram asset is connected.
- No post was created, edited, rescheduled or published during this verification.

### 3 August 2026, 08:01 BST

**Platforms checked:** TikTok Studio Content and dashboard; Meta Business Suite.

**Publishing and measurement**

- TikTok Studio Content lists four BookQuotes posts once, all Public: the marked-page product proof
  (`7667570006032387350`, 28 Jul), the *Team of Rivals* reading note (`7667846219120626966`, 29 Jul),
  the presidential-biographies Reel (`7667829238065646870`, 29 Jul) and the *Player of Games* reading
  route (`7668631665064938774`, 31 Jul).
- The Content table displays 0 views, 0 likes and 0 comments for all four posts. The account dashboard
  displays 0 followers, 0 likes and 0 following. Watch time, completion, saves, shares, profile visits,
  follows, link taps and attributable account analytics: Not available.
- The dashboard's Recent posts card displays only the two newest items; the full Content table resolves
  all four. The earlier impression that only two posts existed was a dashboard-scope issue, not evidence
  that the other posts had been deleted.
- TikTok shows no comments yet. No replies were made.
- Meta Business Suite now loads, but the active identity is visibly `ShiftPro, shiftpro.app` with Facebook
  and Instagram follower counts of 0. BookQuotes Facebook and Instagram identity, queue, posts, metrics,
  comments and messages remain Not verified.
- No post was uploaded, scheduled, edited, deleted or replied to in this run.

**Learning and decision**

- No hypothesis confidence changed. Four literal zero-count public posts still indicate an account
  distribution or measurement blocker; they are not evidence that the topics or Reels have failed.
- Keep the TikTok Distribution Reset gate active. Do not schedule the prepared queue until Account Check
  and attributable analytics are available.
- Keep Facebook automation paused until Meta visibly switches to BookQuotes and the Planner and Content
  Library agree on the same Page identity.
- TikTok's official Creative Centre remains the correct research surface for UK trends, Top Ads and keyword
  signals, but no unrelated trend was promoted into the BookQuotes queue. See the [Creative Centre guidance](https://ads.tiktok.com/help/article/creative-center?lang=en-GB).

**Next actions**

- Resolve the Meta identity selector and recheck BookQuotes Content Library before any Facebook queue action.
- Obtain TikTok Account Check and an attributable analytics view in Studio or the mobile app.
- Continue research and production planning only; no further TikTok publishing until the gate is closed.

### 2 August 2026, 20:39 BST

**Platforms checked:** TikTok Studio; Meta Business Suite.

**Publishing and measurement**

- TikTok still shows 0 followers, 0 likes and 0 following. The latest public *The Player of Games*
  Reel remains listed once with 0 views, 0 likes and 0 comments. Watch time, completion, saves,
  shares, profile visits, follows, link taps and attributable account analytics: Not available.
- TikTok's currently visible Inspiration surface remains dominated by unrelated news and
  entertainment topics; no UK BookTok signal was adopted from it.
- Meta Business Suite returned `Sorry, something went wrong` after an `Internet connection was
  restored` alert. Facebook and Instagram identity, queue, posts, metrics, comments and messages:
  Not verified.
- No post was uploaded, scheduled, edited, deleted or replied to in this run.

**Learning and decision**

- No hypothesis confidence changed. Literal zero TikTok distribution remains an account-health or
  measurement blocker until Account Check and an attributable analytics entry are evidenced.
- Keep the TikTok Distribution Reset gate active. Do not bulk-publish the prepared sci-fi queue
  while account status and analytics remain unresolved.
- Facebook automation is paused for this run because the active Meta identity and scheduler cannot
  be verified. Retry only after the BookQuotes identity and Content Library are visible together.

### 1 August 2026, 08:01 BST

**Platforms checked:** TikTok Studio; Meta Content Library.

**Publishing and account state**

- TikTok lists the *The Player of Games* Culture reading-route Reel (`7668631665064938774`)
  once as the latest public post, dated 31 July at 11:07. The earlier private-under-review state
  has cleared from the visible recent-post surface.
- TikTok visible account metrics remain 0 views, 0 likes, 0 comments. Watch time, completion,
  saves, shares, profile visits, follows, link taps and attributable account analytics: Not
  available.
- TikTok Inspiration exposed broad current topics, but the visible set was dominated by unrelated
  news and entertainment. No generic trend was adopted as a BookQuotes editorial signal.
- Meta Content Library was showing the ShiftPro identity and ShiftPro posts. BookQuotes Facebook
  publication, queue, metrics, comments and messages: Not verified in this run.

**Community and learning**

- No BookQuotes comments or messages were visible on the checked TikTok surface. No replies were
  made.
- No hypothesis confidence changed. The zero TikTok counts remain an account-distribution or
  measurement issue until an attributable analytics entry and comparable reach exist.

**Next actions**

- Recheck TikTok at the 24-hour and 72-hour checkpoints, recording the first non-zero or still-zero
  evidence without inferring a creative failure prematurely.
- Restore and visibly confirm the BookQuotes Facebook Page identity before reconciling its queue or
  reporting any Meta performance.

### 1 August 2026, 09:50 BST

**Platforms checked:** TikTok Studio; Facebook Content Library; Meta Business Suite; public
Instagram route.

**Account progress**

- TikTok remains at 0 followers, 0 following and 0 likes. The latest public *The Player of Games*
  Reel is listed once; visible account metrics remain 0 views, 0 likes and 0 comments. No comments
  are visible and no reply was made.
- Facebook remains on the ShiftPro identity. The visible content and notifications are ShiftPro
  activity, so they are excluded from BookQuotes reporting. The Meta Business Suite inbox surface
  also returned `Sorry, something went wrong`.
- Instagram's public `bookquotes.app` route reached Meta's UK ads-choice screen before the profile
  could be inspected. No consent option was selected, so Instagram progress remains unverified.

**Learning and next actions**

- There is no new BookQuotes performance signal yet. The immediate blockers are account identity and
  access verification, not evidence that the TikTok creative has failed.
- Restore BookQuotes in Meta before interpreting Facebook data or relying on its queue. Complete the
  Instagram ads choice in the browser if you want the profile and connection status checked; then
  verify Instagram natively rather than inferring it from the public route.

### 29 July 2026, 10:20 BST

**Platforms checked:** TikTok Studio Content; Meta Content Library.

**Publishing**

- TikTok lists the marked-page product proof (`7667570006032387350`, 28 Jul 19:30) and *Team of
  Rivals* (`7667846219120626966`, 29 Jul 08:19) once and as Public. Five presidential biographies
  (`7667829238065646870`) remains scheduled for 19:30 with a Public audience setting.
- The available Meta Content Library was visibly in the ShiftPro identity and contained ShiftPro
  posts. No BookQuotes Facebook publication or queue conclusion can be drawn from that surface.

**Performance and community**

- TikTok Studio Content displays 0 views, 0 likes and 0 comments for the two published Reels.
  Watch time, completion, saves, shares, profile visits, follows, link taps and App Store signals:
  Not available.
- No BookQuotes Facebook metrics, comments or messages were available because the active Meta
  identity did not match the BookQuotes Page. No replies were made.

**Learning update**

- No hypothesis confidence changed. The TikTok posts are too new and the available surface does
  not supply quality or retention metrics.
- Correct Meta Page identity is now a prerequisite for Facebook measurement and automatic queue
  reconciliation. Do not interpret ShiftPro data as BookQuotes performance.

**Next actions**

- Recheck TikTok at the next 24-hour checkpoints, ideally from the analytics surface needed for
  the native-validation gate.
- Switch Meta Business Suite to the BookQuotes Page before the next Facebook publishing action;
  then reconcile Planner and Scheduled Library against the same Page identity.

### 29 July 2026, 10:35 BST

**Platforms checked:** BookQuotes Facebook Content Library.

**Publishing**

- Meta identity was switched from ShiftPro to BookQuotes and the confirmation banner states that
  the account is acting as BookQuotes.
- The 12:30 reader-research prompt, `What happens to your annotations when you finish a book?`,
  is confirmed Published on the BookQuotes Page.
- The BookQuotes Scheduled tab reports `No scheduled posts`. The previously recorded future
  Planner cards are therefore not a reliable queue.

**Performance and community**

- Today's prompt displayed 0 across the immediately visible metrics. No comments or messages
  were visible; no replies were made.

**Next actions**

- Rebuild the seven-day BookQuotes Facebook queue from the approved, rights-cleared content pack,
  starting with the 30 July `One book, one line` Reel after full native preflight.

### 30 July 2026, 08:20 BST

**Platforms checked:** BookQuotes Facebook Content Library and native Reel composer; TikTok
Studio Content.

**Publishing**

- Facebook: `One book, one line` was uploaded to the BookQuotes Page, passed Meta's copyright
  check, then scheduled for 18:30 today. The composer confirmed `Your post is scheduled`.
  Visibility was Public, Boost and AI label were off, and group and Story sharing were not used.
- Facebook: reloading the Scheduled Library immediately afterwards still returned `No scheduled
  posts`. No duplicate retry was made because the scheduler confirmation and library are in
  conflict.
- TikTok: the 28 July marked-page Reel, 29 July *Team of Rivals* Reel and 29 July presidential
  biographies Reel all remain listed once and Public. No further TikTok publishing was attempted
  because the automation-validation analytics entry remains unavailable.

**Performance and community**

- TikTok Content table shows 0 views, 0 likes and 0 comments for each existing post. Watch time,
  completion, saves, shares, profile activity, follows and link taps: Not available.
- Facebook's previously published 29 July annotation prompt was not remeasured in this run. No
  comments or messages were actioned.

**Learning update**

- No performance hypothesis changed. Three TikTok zero-count displays are an account-health and
  measurement concern, not evidence that any particular topic or format failed.
- The recurring Meta scheduling discrepancy is now the immediate operational blocker. It prevents
  confirmation of a rolling queue and needs a direct Planner/Library reconciliation before more
  Facebook uploads are created.

**External research**

- TikTok Creative Center guidance confirmed that UK trend research should use the Trends surface
  with time-frame, industry and hashtag analytics. No current trend was adopted from search
  snippets alone.
- TikTok's July BookTok Late coverage continues to support reader community and shared discovery
  as a durable context, rather than a reason to chase generic trends.

**Next actions**

- Verify whether the 18:30 Facebook Reel publishes exactly once; do not create a replacement
  while its status is uncertain.
- Resolve Meta's scheduler-versus-library discrepancy, then rebuild the seven-day Facebook queue.
- Keep TikTok publishing gated; seek the attributable analytics entry before scheduling again.

### 29 July 2026, 08:25 BST

**Platforms checked:** Facebook Planner and Content Library; TikTok Studio Content.

**Publishing**

- TikTok's 28 July controlled product Reel is Public and displayed once under content ID
  `7667570006032387350`; it is therefore no longer merely scheduled.
- The 29 July 08:19 *Team of Rivals* recommendation Reel is Public under content ID
  `7667846219120626966` after TikTok's immediate content-review state cleared.
- The five-presidential-biographies Reel remains scheduled for 19:30 under content ID
  `7667829238065646870`.
- Facebook Planner shows substantive entries, including today's 12:30 annotation question, but
  the Content Library Scheduled tab reports no scheduled posts. Opening the Planner entry exposed
  an editable post; Meta then reported an offline state before the final scheduler screen. The
  draft was closed unchanged to avoid duplicate publication.

**Performance and community**

- TikTok Studio displayed 0 views, likes and comments for all three entries at this early check.
  Watch time, completion, saves, shares, profile visits, follows, link taps and App Store signals:
  Not available.
- No comments or messages were visible in the checked surfaces. No replies were made.

**Learning update**

- No hypothesis confidence changed. Initial zeroes are too early and no deeper analytics were
  exposed.
- TikTok's native publish-once and public-visibility checks now have evidence, but Business or
  Advanced Access and an attributable analytics view remain unverified. Routine automatic TikTok
  publishing stays gated.
- Facebook's Planner/Library disagreement is an active technical risk. Do not assume Planner
  cards are scheduled until the Scheduled library confirms them.

**Next actions**

- Recheck TikTok at the 24-hour checkpoint for publication, analytics and audience response.
- Recheck Facebook connectivity before 12:30; only schedule a replacement after the Content
  Library and final scheduler agree on the saved item.

### 28 July 2026, 09:00 BST

**Platforms checked:** Facebook; Instagram connection status.

**Publishing**

- The 27 July marked-page product Reel published successfully at 18:30.
- The 28 July annotation reader-roll-call carousel is scheduled for 19:00 with public visibility.
- No publishing failure was found.
- Instagram is not connected to the BookQuotes Meta portfolio.

**Performance**

- Launch Reel: 0 reach, 0 views, 0 interactions, 0 comments, 0 shares, 0 saves, 0 follows and
  0 seconds watch time at the time of the check.
- Non-follower reach, completion, profile visits, link clicks and App Store signals: Not available.

**Community**

- No Facebook comments or messages.
- No routine replies made.
- No replies require approval.

**Learning update**

- No hypothesis confidence changed. The launch Reel has produced no signal yet, and one product
  Reel is not a useful basis for format or timing conclusions.
- The first useful comparison begins after tonight's editorial carousel has had 24 hours to accrue
  saves, comments and profile activity.

**Proposed actions requiring approval**

- Keep tonight's scheduled carousel unchanged.
- After 24 hours, compare its downstream engagement with the launch Reel while treating the
  different format and topic as confounding variables, not proof of causation.

### 28 July 2026, live publishing audit

**Facebook**

- The latest published item is the 22-second `Keep the words. Find them again.` Reel, published
  27 July at 18:31.
- At this audit it showed 1 view, 0 engagement and insufficient retention data.
- The Content Library also showed a 24 July item with 0 views.
- The Planner displayed content at 19:00 on 28 July, 12:30 on 29 July, 18:30 on 30 July and 10:00
  on 1 August.
- The Content Library's Scheduled tab simultaneously reported no scheduled posts.
- Opening the 28 July Planner item confirmed that it contains the annotation reader-roll-call
  caption and attached media, so the Planner entries are substantive rather than empty reminders.

**Process change**

- The user authorised automatic routine publishing.
- Facebook now follows `AutomatedPublishingRunbook.md`.
- Automatic publishing remains disabled for TikTok and Instagram until their native flows are
  verified.
- The Planner/Content Library disagreement must be checked before relying on the queue.
