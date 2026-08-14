# BookQuotes Growth Scorecard

Generated from structured evidence updated <code>2026-08-14T08:09:11+01:00</code>.

## Current signal

- Reporting window: <code>2026-08-07T08:09:11+01:00</code> to <code>2026-08-14T08:09:11+01:00</code>
- Published Facebook items represented: 3
- Visible views: 2
- Visible reach: 3
- Meaningful interactions: 0
- Link clicks: 0
- Interpretation: distribution is too small for a creative or timing winner. Continue controlled instrumentation; do not increase volume.

## Latest social observations

| Date | Status | Platform | Content | Format | Checkpoint | Views | Reach | Saves/1k reach | Comments/1k reach | Decision |
| --- | --- | --- | --- | --- | --- | ---: | ---: | ---: | ---: | --- |
| 2026-08-13 | published | facebook | dry-run-only | text | initial | 2 | 2 | 0.0 | 0.0 | Insufficient distribution |
| 2026-08-12 | published | facebook | Try the 24-hour highlight test | text | initial | 0 | 1 | 0.0 | 0.0 | Insufficient distribution |
| 2026-08-10 | draft | facebook | The 24-hour highlight test | text | preflight | Not available | Not available | Not available | Not available | Awaiting publication/read-back |
| 2026-08-07 | published | facebook | Find the line | reel | initial | 0 | 0 | Not available | Not available | Insufficient distribution |
| 2026-08-06 | published | facebook | A reading habit you abandoned? | text | 24h-plus | 0 | 0 | Not available | Not available | Insufficient distribution |
| 2026-08-05 | published | facebook | Ten-minute commonplace ritual | carousel | audit | 0 | 0 | Not available | Not available | Insufficient distribution |
| 2026-08-04 | published | facebook | The last line copied by hand | text | audit | 0 | 0 | Not available | Not available | Insufficient distribution |
| 2026-08-03 | published | facebook | Annotation debate | reel | audit | 1 | 1 | 0.0 | 0.0 | Insufficient distribution |

## Experiment readiness

### FB-001: Pending

A practical next-day highlight review ritual will produce more saves and meaningful comments than a feature-led product post.

- Primary metric: <code>saves&#95;per&#95;1000&#95;reach</code>
- Executions by treatment: <code>&#123;"feature&#95;led&#95;product": 0, "practical&#95;reader&#95;ritual": 1&#125;</code>
- Minimum per treatment: 3
- Comparison ready: no

## Weekly funnel and attribution

- Baseline window: <code>7d&#95;pre&#95;experiment</code>
- Review checkpoints: <code>24h, 72h, 7d</code>
- Primary weekly metric: <code>first&#95;time&#95;downloads</code>
- Secondary weekly metrics: <code>qualified&#95;website&#95;sessions, app&#95;store&#95;product&#95;page&#95;views, downloads, activations, sales, proceeds</code>
- Activation: The reader adds a first book and saves or confirms a first extracted quote in the live BookQuotes app.
- Durable published items: 3
- Channel-only items: 3
- Website campaign-linked items: 0
- App Store campaign-linked items: 0
- Attribution quality: `none` for downstream App Store outcomes until an Apple campaign link or another authoritative install attribution path is read-tested.

### Campaign conventions

| Channel | utm_source | utm_medium | Campaign/content convention |
| --- | --- | --- | --- |
| facebook | facebook | organic&#95;social | bq-&#123;experiment&#95;id&#125;-&#123;yyyy&#95;mm&#125; / &#123;content&#95;id&#125;-&#123;treatment&#125; |
| instagram | instagram | organic&#95;social | bq-&#123;experiment&#95;id&#125;-&#123;yyyy&#95;mm&#125; / &#123;content&#95;id&#125;-&#123;treatment&#125; |
| tiktok | tiktok | organic&#95;social | bq-&#123;experiment&#95;id&#125;-&#123;yyyy&#95;mm&#125; / &#123;content&#95;id&#125;-&#123;treatment&#125; |
| google&#95;search | google | organic&#95;search | bq-&#123;experiment&#95;id&#125;-&#123;yyyy&#95;mm&#125; / &#123;landing&#95;page&#95;slug&#125;-&#123;treatment&#125; |
| bookquotes&#95;website | bookquotes&#95;website | owned&#95;web | bq-&#123;experiment&#95;id&#125;-&#123;yyyy&#95;mm&#125; / &#123;cta&#95;location&#125;-&#123;treatment&#125; |

## App Store performance

Observed <code>2026-08-11T17:15:10+01:00</code> from <code>app&#95;store&#95;connect&#95;api&#95;read&#95;only</code> for app <code>6758091579</code>.
Live version <code>1.0.1</code>; state <code>READY&#95;FOR&#95;SALE</code>; downloadable <code>True</code>.

| Surface | Available | HTTP | Reason | Next action |
| --- | --- | ---: | --- | --- |
| metadata | True | 200 | Not available | Continue read-only version and metadata polling. |
| analytics | False | 403 | The configured Individual API key returned FORBIDDEN&#95;ERROR for the app analytics report endpoint. | Create or authorize a least-privilege Team API key with App Analytics report access, then repeat the read-only probe. |
| sales | False | 403 | The configured Individual API key returned FORBIDDEN&#95;ERROR for the daily Sales report. | Create or authorize a least-privilege Team API key with Sales report access for vendor 93932031, then repeat the read-only probe. |
| finance | False | 403 | The configured Individual API key returned FORBIDDEN&#95;ERROR for the monthly Finance report. | Create or authorize a least-privilege Team API key with Finance report access for vendor 93932031, then repeat the read-only probe. |

| Outcome | Value | Currency | Available | Authoritative source | Reason | Next action |
| --- | ---: | --- | --- | --- | --- | --- |
| downloads | Not available | Not available | False | Not available | App Analytics and Sales reports are not authorized for the configured key. | Read downloads from an authorized App Store Connect Analytics or Sales report. |
| first&#95;time&#95;downloads | Not available | Not available | False | Not available | App Analytics and Sales reports are not authorized for the configured key. | Read first-time downloads from an authorized App Store Connect Analytics or Sales report. |
| sales | Not available | Not available | False | Not available | The daily Sales report returned HTTP 403. | Read sales units from an authorized App Store Connect Sales report. |
| proceeds | Not available | Not available | False | Not available | The monthly Finance report returned HTTP 403. | Read proceeds and currency from an authorized App Store Connect Finance or Sales report. |

Downloads, sales and proceeds are reported only from authoritative Apple evidence. HTTP 403 or missing access is `Not available`, never zero.

## Search state

- 2026-08-12: Search Console API access: read-tested (siteOwner); Sitemap API state: Success; submitted 15; indexed 0; pending False; warnings 0; errors 0.
  URL Inspection: PASS; Submitted and indexed; canonical https://bookquotes.uk/; last crawl 2026-08-07T06:53:14Z.
  28d (2026-07-14 to 2026-08-10): 1 clicks, 1 impressions; queries 0 rows; pages 1 rows; countries 1 rows; devices 1 rows.
  90d (2026-05-13 to 2026-08-10): 1 clicks, 1 impressions; queries 0 rows; pages 1 rows; countries 1 rows; devices 1 rows.
  Cloudflare HTTP traffic: unavailable (CLOUDFLARE&#95;API&#95;TOKEN is not present in the read environment.); not a Search Console metric.
- 2026-08-07: sitemap <code>Success</code>, 15 pages discovered; homepage indexed=False; request <code>Indexing requested; added to Google's priority crawl queue</code>; performance <code>Processing; no clicks or impressions shown</code>.

## Next controlled actions

1. Record the 24-hour and 72-hour checkpoints for `Find the line` without interpreting an initial zero as failure.
2. Execute FB-001 only with a rights-safe original treatment and a declared comparable product baseline.
3. Obtain a Team API key or equivalent authorized Apple report path before reporting downloads, sales or proceeds; keep unavailable values null.
4. Create/read-test App Store campaign links before claiming install attribution; website UTMs alone prove only attributed web visits.
5. Continue read-only monitoring of homepage indexing and Search Console performance; do not duplicate-submit the existing sitemap or repeat an indexing request during routine evidence refresh.
6. Promote recurring reader language into a search brief only after three independent occurrences.
