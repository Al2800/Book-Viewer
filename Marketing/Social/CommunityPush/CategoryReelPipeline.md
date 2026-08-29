# Category Reel Pipeline

Updated: 18 August 2026

Daily faceless book Reels sit **beside** the 13:00 typography bank. They do not replace it.

| Slot | Channels | What |
| --- | --- | --- |
| 13:00 Europe/London | Facebook, Instagram | Approved bank stills `bq14-*` |
| 19:30 Europe/London | TikTok and Instagram | One faceless category Reel from `CategoryReelPipeline.json` |

App-led posts stay under 15% of the rolling mix. Instagram gets the same MP4 as TikTok via `--now` (Graph cannot schedule). The 13:00 still and the 19:30 Reel must not be the same asset.

## First frame (0–2s)

The open is a use-condition, a correction, a time-cost, a genre contradiction, or a number. Type is already on at frame 0. No logo, no app, no title card, no fade-in. One mark may finish by ~1.2s. If the proposition is not readable muted by two seconds, the Reel fails.

Default video open is the CommunityReel typography hook (paper, rust rail, giant serif), not the phone book-overview. Phone chrome is at most one day in seven and counts toward the 15% app cap. Lined paper as the *first* frame reads as a still and gets skipped; if the body is handwritten, cut to paper only after 5s.

Then hard cuts on a 10s reel: title card at 1s, three visual chips by 2s, a slash through the wrong reason at 4.5s, two-door choice at 6s, hold to 10s. One MP4 for TikTok and Instagram.

The cover PNG is a separate dark-field poster for the grid (3–6 words, center-safe). Do not grab a video frame. A strong cover over a stationery open still dies in-feed.

## Faceless model

- No presenter. Muted-readable in two seconds.
- Use Remotion (`CategoryReel-*` for the daily 15s set; older presidential and sci-fi routes stay as source packs) or original book objects.
- Stance is `Researched` unless a later `Read` record exists.
- Every recommendation names who it is for, what is distinctive, and one reservation.
- No retailer covers, adaptation stills, or substantial quotations.

## Categories

Rotate one a day so romance and fantasy cannot dominate:

1. Science fiction
2. History and biography
3. Literary fiction
4. Crime and spy fiction
5. Ideas nonfiction
6. Classics and backlist
7. Pairing or wildcard

## 09:00 research

1. Open today's row in `CategoryReelPipeline.json`.
2. If the brief is `ready` and Remotion already exists, queue TikTok `--approve` for 19:30. Do not publish a still as a Reel.
3. If the brief is `needs_illustrated_cut`, do not render or queue the Remotion placeholder. Use `Marketing/Video/IllustratedCategoryReelBrief.md`.
4. Log only useful signals in `TikTokResearchLog.md`. Do not copy another creator's script.
5. Keep three to five future briefs in `draft` or `ready`. Add a new week by appending rotation rows, not by inventing a second bank.

Typography PNG cards remain Instagram/Facebook stills. TikTok needs MP4 plus cover.

## First week

| Date | Category | Brief | Status | Same-day still |
| --- | --- | --- | --- | --- |
| 19 Aug | Science fiction | cr-01 *The Player of Games* | extra live 18 Aug; keep the dated 19:30 week; do not re-upload this MP4 | bq14-01 |
| 20 Aug | History | cr-02 *Team of Rivals* | extra live 18 Aug as format test; keep dated 19:30 row; do not re-upload | bq14-02 |
| 21 Aug | Literary | cr-03 *Foster* | needs illustrated cut | bq14-03 |
| 22 Aug | Crime / spy | cr-04 *Tinker Tailor Soldier Spy* | TikTok inbox hold 25 Aug; do not re-upload | bq14-04 |
| 23 Aug | Ideas | cr-05 *Four Thousand Weeks* | live 23 Aug morning extra; do not re-upload this MP4 | bq14-05 |
| 24 Aug | Backlist | cr-06 *Stoner* | live 24 Aug; TikTok via inbox draft; do not re-upload | bq14-06 |
| 25 Aug | Pairing | cr-07 Culture / Three-Body | live 25 Aug; TikTok via inbox draft; do not re-upload | bq14-07 |

Owner rejected the Remotion placeholder set on 18 August. Do not `--approve` those MP4s.
cr-01 went out early on 18 August from
`Marketing/Video/illustrated-category-reels/01-player-of-games.mp4` with deliberate quiet.
That post sits beside the calendar. Keep 13:00 stills and the 19–25 August 19:30 week
on their dated rows. Do not upload the live cr-01 file a second time. cr-02–cr-07
still need muted-phone review before `--approve`.
