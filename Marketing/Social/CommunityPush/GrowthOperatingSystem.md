# BookQuotes Growth Operating System

Updated: 7 August 2026

## Purpose

This is the control loop that connects BookQuotes social publishing, reader language, website content, Google Search Console and App Store outcomes. It extends—not replaces—`AutomatedPublishingRunbook.md`, `PerformanceLearningLog.md` and the platform-specific registers.

The system optimises for qualified reader attention and useful demand signals, not posting volume. Routine Facebook publishing retains its existing authority. TikTok and Instagram remain gated exactly as documented in `PublishingStatus.md`.

## One weekly loop

1. **Observe:** read native platform metrics, comments, Search Console queries/pages and App Store signals. Record zero only when the platform visibly reports zero; otherwise use `null`/Not available.
2. **Diagnose:** separate distribution, packaging, topic and conversion issues. Do not call a creative weak when it received no meaningful distribution.
3. **Choose:** select one primary variable for each experiment: topic, hook, format, time or CTA. Do not change several at once.
4. **Create:** produce reader-useful content first. Keep app-led posts near 15% until account evidence supports a change.
5. **Preflight:** apply every identity, factual, rights, visual, duplication and paid-promotion gate in `AutomatedPublishingRunbook.md`.
6. **Publish:** use one controlled Facebook item per day; keep TikTok/Instagram behind their current gates.
7. **Measure:** capture 24-hour, 72-hour and 7-day checkpoints where the native platform supports them.
8. **Promote learning:** change a hypothesis only after at least three comparable executions or seven days of evidence. Safety, rights or publishing failures can stop immediately.
9. **Feed search:** turn repeated reader questions into guide/journal briefs; use Search Console impressions and queries to improve titles, descriptions, internal links and follow-up posts.
10. **Archive:** append narrative evidence to `PerformanceLearningLog.md`, update structured evidence in `GrowthEvidence.json`, and regenerate `GrowthScorecard.md`.

## North-star ladder

Measure the closest available rung without pretending that it proves the next one:

1. Distribution: non-follower reach, search impressions, video starts.
2. Attention: completion, average watch time, carousel progression.
3. Utility: saves, shares and meaningful comments.
4. Intent: profile visits, website clicks, App Store clicks.
5. Outcome: qualified installs, retained users and useful product feedback.

Raw views are a diagnostic input, not the objective.

## Content-to-search flywheel

Each editorial territory owns a website destination and a search intent.

| Territory | Reader question | Website destination | Social proof signal |
| --- | --- | --- | --- |
| Annotation | What should I do with highlights after reading? | `/journal/what-to-do-with-book-highlights` | Saves, comments describing rituals |
| Commonplace books | How do I build a digital commonplace book? | `/journal/build-a-digital-commonplace-book` | Saves, shares, profile visits |
| Reading memory | How can I remember more of what I read? | `/guides/remember-more-of-what-you-read` | Saves and repeatable reader language |
| Capture workflow | How do I digitise underlined book passages? | `/guides/digitize-book-highlights` | Site/App Store clicks |
| Reader control | Is AI extraction private and reviewable? | `/journal/ai-extraction-and-reader-control` | Qualified questions and support clicks |

Promotion rules:

- A recurring reader phrase seen in at least three meaningful comments/messages becomes a candidate query brief.
- A Search Console query with impressions but weak CTR becomes a title/description test before a new article is created.
- A page with clicks but weak downstream intent gets a CTA/internal-link test rather than more top-of-funnel volume.
- New pages must answer a distinct intent and link to at least two relevant existing pages. Do not manufacture thin pages for keyword variants.

## Experiment rules

- Declare the hypothesis and primary metric before publishing.
- Prefer rates when denominators are meaningful; retain raw counts alongside them.
- Minimum comparison: three comparable posts per treatment. Use medians, not the single best post.
- Keep a baseline and note confounds: account state, zero distribution, paid support, missing analytics, unusual timing and platform errors.
- Result labels: `Pending`, `Promising`, `Needs another test`, `Packaging failure`, `Topic failure`, `Winner`, `Stopped`.
- Portfolio mix after usable evidence exists: 70% supported, 20% adjacent, 10% exploratory. Until then, call formats supported—not proven.

## Rights and approval boundaries

A structured record is not permission. Every scheduled/published item must contain a non-empty `rights_basis` and pass the runbook. Typography-only original BookQuotes posts are the default when cover or image rights are uncertain.

Never automate:

- paid spend, boosts, targeting, competitions or discounts;
- legal, privacy, billing or customer-support commitments;
- unclear visual rights or substantial copyrighted extracts;
- deletion of live content except an explicit safety/rights containment decision;
- simulated comments, follows or engagement.

## Data and commands

`GrowthEvidence.json` is the structured source. Preserve prior observations; corrections are new dated observations rather than silent rewrites.

Validate and render the scorecard:

```bash
python3 scripts/growth_scorecard.py \
  Marketing/Social/CommunityPush/GrowthEvidence.json \
  --output Marketing/Social/CommunityPush/GrowthScorecard.md
```

The command fails when required fields, experiment declarations, checkpoint semantics or rights bases are invalid. The generated scorecard is deterministic and should be committed with evidence changes.

## Current decision

Meta is correctly operating as BookQuotes, but the Page has zero followers and the recent organic sample has almost no distribution. Search Console has accepted the sitemap, discovered 15 pages and accepted one homepage indexing request into its priority crawl queue; Performance is still processing with no click/impression data. The next phase is therefore controlled instrumentation and useful reader content—not increased posting volume or duplicate search submissions. Keep Facebook at one primary item per day, maintain the native queue, and use rights-safe practical reading rituals while search and social accrue enough evidence for real comparisons.
