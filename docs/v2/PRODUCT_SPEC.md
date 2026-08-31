# BookQuotes v2 product specification

**Status:** Accepted product direction; implementation in progress  
**Product:** BookQuotes  
**Working concept:** A personal reading memory for physical books  
**Baseline:** The existing App Store version remains live. TestFlight Build 51 and current `main` provide the engineering baseline, but do not constrain the v2 product structure or visual direction.

## 1. Executive decision

BookQuotes v2 should stop presenting itself primarily as a digital bookshelf, reading tracker, AI extraction demonstration or quote-card generator.

It should become:

> **The fastest and most trustworthy way to turn markings in physical books into a searchable personal reading memory.**

The core promise is:

> **Capture the lines you mark in physical books, then find, revisit and connect them later.**

The product is organised around three verbs:

1. **Capture:** get marked material out of a physical book with minimal interruption.
2. **Remember:** preserve passages with their source, context, notes and provenance.
3. **Connect:** search, resurface, compare and eventually synthesise ideas across books.

The primary product surfaces are therefore:

- **Reading:** the user's passage-first reading memory.
- **Capture:** a direct active-book camera interface.
- **Explore:** search, resurfacing, themes and later semantic connections.
- **Studio:** a contextual action from a passage, not a primary tab.
- **Settings:** a secondary destination rather than a primary product surface.

This is a deliberate product reset. The recent v2 builds provide useful services, models, capture infrastructure, tests and components, but their current navigation and visual hierarchy do not define the target product.

## 2. Product thesis

### 2.1 Problem

People who read physical books often underline passages, add margin notes, use highlighters or photograph pages. These marks express strong intent. They identify what the reader considered important.

The information is then difficult to use:

- marked passages remain trapped in the book;
- photographs disappear into the camera roll;
- manual transcription is slow;
- page context and provenance are lost;
- notes are scattered across apps;
- search across years of physical reading is impossible;
- connections between ideas depend on memory.

Existing products tend to address adjacent jobs such as book tracking, ebook highlighting, generic note-taking, read-later workflows, social quote cards or general AI chat over uploaded documents.

BookQuotes has a more specific and defensible wedge:

> **The user's physical marking is the relevance signal. BookQuotes turns that signal into structured, retrievable knowledge.**

### 2.2 Opportunity

A reliable capture pipeline produces a uniquely personal corpus. It contains only ideas the user deliberately selected while reading.

That corpus can support progressively more valuable functions:

1. accurate capture;
2. exact retrieval;
3. source verification;
4. resurfacing;
5. thematic organisation;
6. related passages;
7. contradictions and comparisons;
8. grounded synthesis across the user's reading.

The long-term product is not merely an app for storing quotations. It is a memory system for what a person learns from physical books.

## 3. Target users

### 3.1 Active physical-book annotator

Reads physical books, underlines passages, uses pencil or highlighter and may currently photograph pages.

Primary job:

> Save what I marked without breaking my reading flow.

### 3.2 Knowledge worker, writer or researcher

Reads to support decisions, writing, teaching or research and may already use Notes, Notion, Obsidian or Readwise.

Primary job:

> Find and connect ideas I deliberately collected over time.

### 3.3 Archive digitiser

Owns heavily marked books and wants to process them efficiently.

Primary job:

> Turn an existing physical archive into structured digital material.

The initial v2 should not optimise for casual readers who rarely mark books, social discovery, streaks, reading statistics or community features.

## 4. Goals

### 4.1 Product goals

- Make existing-book capture available with zero mode-selection ceremony.
- Make the common journey approximately Photo -> Passages -> Save.
- Make saved passages more prominent than book metadata.
- Preserve source provenance as a first-class capability.
- Make search correct, current and grounded in the user's material.
- Establish a credible path from cloud extraction to measured local-first extraction.
- Give humans and coding agents explicit product and architecture contracts.

### 4.2 Non-goals

V2 is not intended to become:

- a Goodreads or StoryGraph competitor;
- a social network;
- a generic document scanner;
- a full note-taking platform;
- a generic chatbot over whole copyrighted books;
- primarily a quote-card generator;
- a reading-streak product;
- a broad book-discovery or recommendation platform.

## 5. Product principles

### Passage-first, book-grounded

Passages are the primary assets. Books provide provenance, grouping and context.

### Capture with almost no ceremony

For an existing active book, opening Capture should immediately start the camera.

### AI should be mostly invisible

Normal users should see:

- 3 passages found;
- 1 needs checking;
- Saved.

They should not normally need to understand provider names, extraction-source labels or raw probability scores.

### Uncertainty changes interaction

- High confidence: selected automatically.
- Medium confidence: visible and labelled **Check**.
- Low confidence: not selected automatically.

### Provenance is part of the product

Every saved passage should retain its book, page number where available, source page, source bounding box, marking type and capture date.

### Local-first, cloud-assisted

The current cloud inference remains the production comparator and fallback. On-device extraction takes control only where measured confidence is sufficient.

### Quiet by default

The normal application should feel like a well-typeset reading notebook, not a luxury-book-themed novelty.

### One primary action per state

- Capture: Take Photo.
- Review: Save Passages.
- Book: Browse Passages.
- Passage: Read, Edit or Use.
- Explore: Search or Open a Connection.
- Studio: Export.

### Recoverable failure

No camera, persistence, network or extraction failure should leave an unexplained spinner or destroy recoverable input.

## 6. Product vocabulary

| Current or internal term | User-facing term |
|---|---|
| Quote | Passage |
| Library home | Reading |
| Extraction result | Passages found |
| AI processing | Checking the page |
| Confidence | Needs checking |
| Capture session | Batch or Draft |
| Daily Serendipity | Revisit |
| Model-assisted | Hidden from normal UI |

The internal SwiftData model may remain `Quote` during the initial reset. Renaming the persisted type is not required to change product language and would add migration risk.

## 7. Information architecture

### 7.1 Primary navigation

#### Reading

The user's saved reading memory.

#### Capture

The active-book camera and capture workflow. This occupies the central tab position.

#### Explore

Search, resurfacing and later grounded connection features.

Studio is accessed through Passage -> Use or Share -> Create Card.

Settings is opened from a secondary control in Reading or Explore.

### 7.2 Navigation rules

- Adding a book from Capture returns to Capture with that book active.
- A search result opens the canonical Passage or Book destination.
- Studio never owns a separate copy of a passage.
- Source provenance always links back to the saved passage.
- Batch is a Capture mode, not a separate top-level destination.

## 8. Reading home

### 8.1 Purpose

Reading should answer:

- What am I reading now?
- What did I save recently?
- What is worth revisiting?
- Which books contain my saved material?

It should not lead with a decorative bookshelf.

### 8.2 Target hierarchy

```text
READING                                      Settings

[ Search your reading... ]

CONTINUE READING

The Beginning of Infinity
18 passages
Last captured yesterday                 Capture

RECENT PASSAGES

“An explanation that can easily be varied...”
The Beginning of Infinity · p. 25

“Risk means more things can happen than will...”
The Most Important Thing · p. 67

REVISIT

“The test of a first-rate intelligence...”
The Crack-Up · saved 8 months ago

BOOKS

[cover] [cover] [cover] [cover]
```

### 8.3 Behaviour

- Search is visible near the top.
- Continue Reading uses the active book.
- Recent Passages prioritises what the user deliberately captured.
- Revisit surfaces older saved material without streaks or engagement manipulation.
- Books remain available after passage-led content.
- Capture from Continue Reading opens the camera with the book already active.

### 8.4 Empty state

Copy:

> Turn the lines you mark in physical books into a searchable reading memory.

Actions:

- Add Book.
- Capture First Passage.

Do not render several empty product sections simultaneously.

## 9. Capture 2.0

### 9.1 Common journey

```text
Open Capture
  -> photograph page
  -> passages found
  -> save
```

The user should not normally need to choose a mode, choose a book, inspect an image, watch a processing screen, enter a separate extraction editor and then save.

### 9.2 Camera screen

```text
The Beginning of Infinity                  Change

┌──────────────────────────────────────────────┐
│                                              │
│                CAMERA PREVIEW                │
│                                              │
│          subtle text-region overlays         │
│                                              │
└──────────────────────────────────────────────┘

Flash                   ●                   Batch
```

Requirements:

- Opening Capture immediately starts the camera when permission and an active book exist.
- The active book persists across sessions.
- Change opens a contextual book switcher.
- Single-page capture is the default.
- Batch is a secondary toggle.
- ISBN scanning belongs to Add or Change Book, not to a parallel top-level capture mode.

### 9.3 Image quality

A clear photograph proceeds directly to passage detection.

A poor photograph shows an inline warning:

> Photo may be blurry.

Actions:

- Retake.
- Use Anyway.

The image-review screen should not be mandatory when the photo is clearly usable.

## 10. Capture result

### 10.1 Target interaction

```text
2 passages found · 1 needs checking

┌──────────────────────────────────────────────┐
│ frozen source page                           │
│                                              │
│ [✓ highlighted detected passage]             │
│                                              │
│ [? ambiguous passage]                        │
│                                              │
└──────────────────────────────────────────────┘

✓ “Good explanations are hard to vary...”

? “The reach of an explanation...”       Check

Retake                                  Save 2
```

### 10.2 Candidate behaviour

- High-confidence candidates are selected.
- Medium-confidence candidates are labelled Check.
- Low-confidence candidates are not selected automatically.
- Tapping an overlay selects the matching card.
- Tapping a card illuminates its source region.
- The user may deselect, edit, add manually or inspect the full source.

After saving, show a concise confirmation and return to the camera for the same active book.

### 10.3 No passages found

Copy:

> No marked passages found.

Actions:

- Add Passage Manually.
- Retake.
- Check Again.

Check Again may invoke cloud fallback when consent and connectivity permit.

## 11. Book context and registration

### 11.1 Book switcher

```text
ACTIVE BOOK

The Beginning of Infinity              ✓

RECENT

Thinking in Bets
The Most Important Thing
Four Thousand Weeks

[ Search books... ]

Scan ISBN
Add Manually
```

### 11.2 Add Book completion

Completing book registration should:

1. create the book;
2. make it active;
3. return directly to Capture.

A cover image is optional. ISBN is an Add Book mechanism, not a capture product in its own right.

## 12. Batch capture

Batch remains a power-user capability for archive digitisation and rapid multi-page capture.

Requirements:

- same visual language as single capture;
- page count and thumbnail strip when enabled;
- immediate safe persistence of each page;
- fast return to the camera after each shutter action;
- Finish opens consolidated review;
- Save Draft remains available;
- drafts are accessible from Capture;
- interruption and low-storage states are recoverable.

Batch should not require restoration of the old full-screen mode-selection interface.

## 13. Book detail

The page should lead with captured material rather than publication metadata.

```text
The Beginning of Infinity
David Deutsch

18 passages · 4 notes
Last captured yesterday

Capture from this book

[ Search within book... ]

ALL      FAVORITES      NOTES

“Good explanations are hard to vary...”
p. 25

“The reach of an explanation...”
p. 44
```

Publisher, year, ISBN, genre and other metadata move under a secondary Details surface.

## 14. Passage detail

Hierarchy:

1. passage text;
2. book, author and page;
3. source image and illuminated provenance;
4. personal note;
5. tags and favourite;
6. related passages when available;
7. actions.

Actions:

- Edit.
- Favourite.
- Add Note.
- Share.
- Create Card.
- Export Markdown.
- View Source.
- Delete.

Studio begins here as a contextual use of the passage.

## 15. Explore

### 15.1 Initial release

Explore initially contains:

- grounded passage search;
- filters;
- Revisit;
- topics only when quality is reliable.

```text
EXPLORE

[ Search your reading... ]

FILTERS
All · Favorites · Notes · Books · Date

REVISIT
Three passages worth returning to

TOPICS
Decision making
Uncertainty
Institutions
Technology
```

### 15.2 Later capabilities

- Related passages.
- Connections.
- Ask Your Reading.
- Different Perspectives.

AI-generated answers must cite actual saved passages. When evidence is insufficient, the system states that rather than supplementing the answer with unsupported general knowledge.

## 16. Studio

Studio remains useful but is removed from the primary v2 tab bar.

Entry points:

- Passage detail -> Create Card.
- Passage share menu -> Design Card.

Requirements:

- preview and export share exactly the same transform state;
- decorative themes remain contained within Studio;
- export failures are visible;
- Markdown formats escape their target syntax correctly.

## 17. Visual direction

### 17.1 Target

> **A beautifully typeset reading notebook with the precision of a first-party utility.**

### 17.2 Four intentional contexts

| Area | Visual character |
|---|---|
| Reading | Warm, quiet, editorial |
| Capture | Dark, functional, camera-like |
| Review | Neutral, precise workspace |
| Studio | Expressive and decorative |

### 17.3 Keep

- strong typography;
- warm neutral palette;
- restrained physical-book cues;
- active-book context;
- source provenance;
- dark camera interface;
- selected Studio themes and export work.

### 17.4 Reduce

- cards inside cards;
- glass outside functional camera contexts;
- gold or gilded accents throughout normal navigation;
- multiple gradients on one surface;
- decorative 3D transforms in information-dense areas;
- random entrance animations;
- excessive haptics;
- verbose explanatory copy;
- multiple competing button styles.

### 17.5 Typography

Use serif for passage text and selected editorial headings. Use system sans-serif for controls, navigation, metadata, labels and status.

### 17.6 Motion

Motion explains state: capture, selection, linked provenance, save and navigation. It does not decorate every list appearance.

## 18. On-device marked-passage extraction

### 18.1 Strategy

Do not replace cloud inference immediately. Build a measured local-first pipeline whose output can be compared with the current production path.

```text
Captured page
  -> on-device OCR and mark detection
  -> calibrated local candidates
  -> sufficient confidence?
       yes: review
       no: cloud fallback -> candidate merger -> review
```

### 18.2 Evaluation corpus

Begin with approximately 250 labelled real pages and expand to at least 1,000 before broad local auto-selection.

Include:

- pencil, biro, fine liner and highlighter;
- partial, broken and double underlines;
- brackets and margin lines;
- annotations touching marks;
- pages with no marks;
- page curvature and gutter shadows;
- cream or aged paper;
- two-column pages;
- varied fonts, sizes and publishers.

Ground truth records:

- expected OCR text;
- expected marked regions;
- expected passage grouping;
- marking type;
- page order.

### 18.3 Metrics

Measure:

- OCR character and word error rates;
- passage precision;
- passage recall;
- false-positive passages per page;
- source-box accuracy;
- user correction rate;
- latency;
- memory;
- energy;
- cloud fallback rate.

### 18.4 Initial gates

Before local output controls automatic selection:

- passage precision at least 95%;
- passage recall at least 85%;
- false-positive rate below 3% on unmarked pages;
- median latency around 1.5 seconds or better on the oldest supported performance class;
- stable 20-page Batch behaviour;
- confidence bands correlated with observed correction rates.

These are gates to test, not claims about current performance.

### 18.5 Approaches

#### Classical computer vision

Contrast, morphology, connected components and line detection.

#### OCR-anchored heuristics

For each recognised text line, inspect the region around and beneath it. Score stroke coverage, darkness, continuity, baseline distance, thickness, orientation, colour saturation and relation to adjacent lines.

This is the first serious production experiment because it constrains the problem more effectively than general page interpretation.

#### Small Core ML classifier

Input: normalised crop around an OCR line.

Output: none, underline, highlight, margin mark or other.

Do not build this until the deterministic baseline and evaluation harness exist.

### 18.6 Rollout

1. diagnostics only;
2. TestFlight shadow mode;
3. local suggestions;
4. high-confidence local auto-selection;
5. local-first with cloud fallback;
6. optional offline mode.

## 19. Privacy and analytics

Analytics must not contain passage text, OCR text, personal notes or page images.

Useful events include:

- camera opened;
- photo taken;
- quality warning shown;
- extraction completed;
- candidate count;
- correction and deselection counts;
- manual passage added;
- save completed;
- extraction latency;
- local/cloud route;
- fallback reason;
- failure category.

## 20. Success metrics

### North-star metric

**Weekly active reading-memory users.**

A user counts after at least one high-value action:

- saving a passage;
- searching and opening a passage;
- revisiting a passage;
- opening a related passage;
- exporting or using a passage.

### Capture targets for TestFlight

- at least 90% of capture sessions containing a photo finish with one or more saved passages;
- median correction below one candidate per page;
- no unexplained processing state;
- no source-page loss after a persistence failure;
- measurable reduction in cloud fallback as local quality improves without precision regression.

## 21. Accessibility

Every major surface requires:

- Dynamic Type layouts, including accessibility sizes;
- VoiceOver labels and meaningful traversal order;
- Reduce Motion behaviour;
- accessible contrast;
- non-colour representation of Check and selected states;
- minimum control targets;
- stable accessibility identifiers for UI automation.

Accessibility is part of acceptance, not a separate polish stage.

## 22. Release gates

### Product

- The purpose is understandable from Reading and Capture.
- Existing-book capture begins without mode-selection ceremony.
- The normal path is Photo -> Passages -> Save.
- Reading is passage-first.
- Studio is contextual.
- Explore provides useful grounded search before advanced AI launches.

### Reliability

- No camera lifecycle dead ends.
- No silent persistence failures in core journeys.
- Batch draft and resume are safe.
- Search reflects edits.
- Provenance overlays align correctly.
- Previous user data remains accessible.

### Extraction

- Local extraction does not control automatic selection before measured thresholds pass.
- Cloud fallback consent is accurate.
- AI answers cite source passages.
- The system admits when evidence is insufficient.

### Design

- Reading, Capture, Review and Studio follow their intended visual contexts.
- There are no unnecessary nested cards.
- Each state has one primary action.
- Dynamic Type, VoiceOver, Reduce Motion and contrast checks pass.

### Repository

- Product and architecture documentation is current.
- One verification command exists.
- Ownership boundaries are enforced.
- Agent instructions are explicit.
- Every PR defines its affected user journey and acceptance criteria.

## 23. Immediate implementation sequence

1. Commit product, architecture and agent contracts.
2. Add a default-off Reading / Capture / Explore shell using existing data and services.
3. Define the reduced v2 design system from low-fidelity target screens.
4. Build Reading data adapters and passage-first home.
5. Create canonical Book and Passage destinations.
6. Introduce the explicit Capture coordinator.
7. Compress capture into Photo -> Passages -> Save.
8. Correct search indexing and build grounded Explore.
9. Build the extraction evaluation harness.
10. Develop OCR-anchored local detection in shadow mode.
11. Add semantic connections only after capture and retrieval are trustworthy.

## 24. Governing question

Every proposed feature should be tested against:

> **Does this make it easier to capture, recover, verify, connect or use something the reader deliberately marked?**

Anything that fails this test remains secondary or is removed from the v2 core.
