# BookQuotes Growth Scorecard

Generated from structured evidence updated `2026-08-11T17:15:10+01:00`.

## Current signal

- Reporting window: 2026-08-04T17:15:10+01:00 to 2026-08-11T17:15:10+01:00
- Published Facebook items represented: 3
- Visible views: 0
- Visible reach: 0
- Meaningful interactions: 0
- Link clicks: 0
- Interpretation: distribution is too small for a creative or timing winner. Continue controlled instrumentation; do not increase volume.

## Latest social observations

| Date | Status | Platform | Content | Format | Checkpoint | Views | Reach | Saves/1k reach | Comments/1k reach | Decision |
| --- | --- | --- | --- | --- | --- | ---: | ---: | ---: | ---: | --- |
| 2026-08-10 | draft | facebook | The 24-hour highlight test | text | preflight | Not available | Not available | Not available | Not available | Awaiting publication/read-back |
| 2026-08-07 | published | facebook | Find the line | reel | initial | 0 | 0 | Not available | Not available | Insufficient distribution |
| 2026-08-06 | published | facebook | A reading habit you abandoned? | text | 24h-plus | 0 | 0 | Not available | Not available | Insufficient distribution |
| 2026-08-05 | published | facebook | Ten-minute commonplace ritual | carousel | audit | 0 | 0 | Not available | Not available | Insufficient distribution |
| 2026-08-04 | published | facebook | The last line copied by hand | text | audit | 0 | 0 | Not available | Not available | Insufficient distribution |
| 2026-08-03 | published | facebook | Annotation debate | reel | audit | 1 | 1 | 0.0 | 0.0 | Insufficient distribution |

## Experiment readiness

### FB-001: Pending

A practical next-day highlight review ritual will produce more saves and meaningful comments than a feature-led product post.

- Primary metric: `saves_per_1000_reach`
- Executions by treatment: {"feature_led_product": 0, "practical_reader_ritual": 0}
- Minimum per treatment: 3
- Comparison ready: no

## Weekly funnel and attribution

- Baseline window: `7d_pre_experiment`
- Review checkpoints: `24h, 72h, 7d`
- Primary weekly metric: `first_time_downloads`
- Secondary weekly metrics: `qualified_website_sessions, app_store_product_page_views, downloads, activations, sales, proceeds`
- Activation: The reader adds a first book and saves or confirms a first extracted quote in the live BookQuotes app.
- Durable published items: 3
- Channel-only items: 3
- Website campaign-linked items: 0
- App Store campaign-linked items: 0
- Attribution quality: `none` for downstream App Store outcomes until an Apple campaign link or another authoritative install attribution path is read-tested.

### Campaign conventions

| Channel | utm_source | utm_medium | Campaign/content convention |
| --- | --- | --- | --- |
| facebook | `facebook` | `organic_social` | `bq-{experiment_id}-{yyyy_mm}` / `{content_id}-{treatment}` |
| instagram | `instagram` | `organic_social` | `bq-{experiment_id}-{yyyy_mm}` / `{content_id}-{treatment}` |
| tiktok | `tiktok` | `organic_social` | `bq-{experiment_id}-{yyyy_mm}` / `{content_id}-{treatment}` |
| google_search | `google` | `organic_search` | `bq-{experiment_id}-{yyyy_mm}` / `{landing_page_slug}-{treatment}` |
| bookquotes_website | `bookquotes_website` | `owned_web` | `bq-{experiment_id}-{yyyy_mm}` / `{cta_location}-{treatment}` |

## App Store performance

Observed `2026-08-11T17:15:10+01:00` from `app_store_connect_api_read_only` for app `6758091579`.
Live version `1.0.1`; state `READY_FOR_SALE`; downloadable `True`.

| Surface | Available | HTTP | Reason | Next action |
| --- | --- | ---: | --- | --- |
| metadata | True | 200 | Not available | Continue read-only version and metadata polling. |
| analytics | False | 403 | The configured Individual API key returned FORBIDDEN_ERROR for the app analytics report endpoint. | Create or authorize a least-privilege Team API key with App Analytics report access, then repeat the read-only probe. |
| sales | False | 403 | The configured Individual API key returned FORBIDDEN_ERROR for the daily Sales report. | Create or authorize a least-privilege Team API key with Sales report access for vendor 93932031, then repeat the read-only probe. |
| finance | False | 403 | The configured Individual API key returned FORBIDDEN_ERROR for the monthly Finance report. | Create or authorize a least-privilege Team API key with Finance report access for vendor 93932031, then repeat the read-only probe. |

| Outcome | Value | Available | Authoritative source | Reason | Next action |
| --- | ---: | --- | --- | --- | --- |
| downloads | Not available | False | Not available | App Analytics and Sales reports are not authorized for the configured key. | Read downloads from an authorized App Store Connect Analytics or Sales report. |
| first_time_downloads | Not available | False | Not available | App Analytics and Sales reports are not authorized for the configured key. | Read first-time downloads from an authorized App Store Connect Analytics or Sales report. |
| sales | Not available | False | Not available | The daily Sales report returned HTTP 403. | Read sales units from an authorized App Store Connect Sales report. |
| proceeds | Not available | False | Not available | The monthly Finance report returned HTTP 403. | Read proceeds and currency from an authorized App Store Connect Finance or Sales report. |

Downloads, sales and proceeds are reported only from authoritative Apple evidence. HTTP 403 or missing access is `Not available`, never zero.

## Search state

- 2026-08-07: sitemap `Success`, 15 pages discovered; homepage indexed=False; request `Indexing requested; added to Google's priority crawl queue`; performance `Processing; no clicks or impressions shown`.

## Next controlled actions

1. Record the 24-hour and 72-hour checkpoints for `Find the line` without interpreting an initial zero as failure.
2. Execute FB-001 only with a rights-safe original treatment and a declared comparable product baseline.
3. Obtain a Team API key or equivalent authorized Apple report path before reporting downloads, sales or proceeds; keep unavailable values null.
4. Create/read-test App Store campaign links before claiming install attribution; website UTMs alone prove only attributed web visits.
5. Verify homepage indexing and Search Console performance when the inspection surface is available; do not duplicate-submit the sitemap.
6. Promote recurring reader language into a search brief only after three independent occurrences.
