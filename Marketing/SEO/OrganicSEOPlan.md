# BookQuotes Organic SEO Plan

Updated: 11 August 2026

## Purpose

Build a durable search channel for people who already have a reading, annotation or book-note
problem. SEO should support the app and the social channels, not become a second stream of generic
book content.

The public website implementation lives under `website/` and is served at `https://bookquotes.uk`.
The current technical baseline, intent map, live read-back and unresolved deployment/host gates are
tracked in [SEOAudit.md](./SEOAudit.md). Keep source, Worker deployment, public routes and Search
Console evidence as separate states.

## Positioning

BookQuotes is a privacy-conscious iPhone app for turning marked pages from physical books into a
searchable personal quote library. The strongest search proposition is the workflow, not a promise
to provide a database of copyrighted quotations.

Use the following language consistently:

- capture underlined or highlighted passages from books;
- review and correct extracted text;
- keep quotes connected to the book and page context;
- search a personal library of saved passages;
- work locally where the product supports it, with remote AI described only where demonstrated;
- export or revisit a commonplace-book style collection.

Avoid building pages around full quote collections, scraped book text, unsupported AI accuracy
claims, or invented reviews. Those would create rights, trust and thin-content problems.

## First Search Clusters

The initial keyword set is now documented with qualitative SERP and competitor evidence in
[KeywordResearch.md](./KeywordResearch.md). Numeric search volume is intentionally marked as
unknown until Google Keyword Planner, a comparable SEO tool, or Search Console data is available.
The first release should optimise for clear search intent and qualified App Store visits rather
than pretending that unverified volume estimates are precise.

| Cluster | Search intent | Proposed page | Evidence needed |
| --- | --- | --- | --- |
| Save quotes from books | How-to | `/guides/how-to-save-quotes-from-physical-books` | Real BookQuotes capture and review flow |
| Digitise book notes | Problem solving | `/guides/how-to-digitise-book-notes` | Context, correction and export workflow |
| Digital commonplace book | Concept and workflow | `/guides/digital-commonplace-book` | Clear definition, practical setup and product fit |
| Searchable book notes | Product/problem | `/` and related guides | Search UI and local-library behaviour |
| Scan highlighted pages | How-to | `/guides/scan-underlined-book-pages` | Camera, crop, OCR and review limitations |
| Book quote organiser for iPhone | Product discovery | `/guides/organise-book-quotes-on-iphone` | Current workflow, device support and App Store CTA |
| Remember what you read | Reading practice | `/journal/what-to-do-with-book-highlights` | Original reading workflow, not generic productivity claims |
| Privacy-first reading notes | Trust | `/guides/private-book-notes-app-iphone` | Current privacy policy and network behaviour |

The product page should be the conversion hub. The how-to pages should be useful even to visitors
who do not install the app, then link naturally to the relevant workflow.

## Editorial Standard

Every page must answer a real reader question within the opening section and include:

1. A descriptive title and a clear first answer.
2. Original screenshots or photographs from the current app, with private data removed.
3. A step-by-step workflow that matches the shipped build.
4. Honest limitations, including OCR, AI extraction, network and correction steps where relevant.
5. A named author or editor and a short About page explaining who maintains the product.
6. Links to the privacy policy, App Store listing and related reading workflow pages.
7. A last-reviewed date that changes only when the content materially changes.

Use AI for outline comparison, transcription assistance and editorial checks, not for mass-producing
pages. Google Search guidance prioritises original, helpful, people-first content and warns against
large-scale automated content made mainly to attract search traffic.

## Technical Foundation

Before publishing:

- one canonical URL per page;
- descriptive page titles, meta descriptions and Open Graph previews;
- accessible headings, alt text and visible text equivalents for screenshots;
- fast mobile pages with compressed images and no app-store-only dead ends;
- `robots.txt` and an XML sitemap;
- Google Search Console with sitemap submission and URL Inspection (the `.8.1` child owns the
  authenticated read-back and must not turn delayed data into zeroes);
- JSON-LD for `SoftwareApplication` on the product page, `Article` on editorial pages and
  `BreadcrumbList` where appropriate;
- no review or rating structured data unless genuine, visible, policy-compliant reviews exist;
- App Store links with separate UTM parameters for SEO, Facebook, TikTok and Instagram;
- privacy, terms, contact and deletion information linked from every page footer.

Google documents that structured data can help Search understand a software application, but it does
not guarantee a rich result. Pages still need to be crawlable, visible and genuinely useful.

## Conversion Path

Search page -> useful workflow answer -> relevant screenshot or short demo -> trust/limitation note
-> App Store CTA -> measured App Store visit.

Do not send every visitor directly to a subscription prompt. The first conversion is a qualified
App Store visit; the product page can then explain free access, subscription features and privacy
accurately.

## 90-Day Cadence

### Days 1-14: Foundation

- Reconcile the public Worker, canonical domain and route matrix.
- Keep the product, support, privacy, terms, guides and journal routes useful and crawlable.
- Add Search Console evidence and maintain the sitemap/UTM conventions.
- Reuse only approved first-party product evidence with meaningful alt text.

### Days 15-45: Useful search coverage

- Publish one substantial workflow page per week.
- Turn each page into one Facebook discussion post, one TikTok search-led brief and one short
  email or community prompt.
- Add internal links based on reader questions, not keyword repetition.

### Days 46-90: Improve what earns attention

- Compare impressions, clicks, landing-page engagement and App Store clicks by query cluster.
- Expand only pages that attract relevant impressions or reader questions.
- Refresh weak pages by improving evidence, screenshots, clarity and internal linking.
- Do not increase publishing volume just because impressions are low; check indexing and intent
  first.

## Measurement

Track separately:

- indexed pages and Search Console coverage;
- impressions, clicks, click-through rate and average position by page and query;
- non-branded versus branded search traffic;
- App Store click-through by UTM source;
- installs, account creation, trial start and subscription conversion where attribution is available;
- recurring search language that should inform the TikTok and Facebook hooks.

The primary SEO success measure is qualified App Store traffic and useful reader discovery, not raw
page views.

## Sources

- Google Search Central, [Creating helpful, reliable, people-first content](https://developers.google.com/search/docs/fundamentals/creating-helpful-content)
- Google Search Central, [Get started with Search for developers](https://developers.google.com/search/docs/fundamentals/get-started-developers)
- Google Search Central, [SoftwareApplication structured data](https://developers.google.com/search/docs/appearance/structured-data/software-app)
- Google Search Central, [Sitemaps overview](https://developers.google.com/search/docs/crawling-indexing/sitemaps/overview)
