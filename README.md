# BookQuotes

**Transform your paper book annotations into a digital quote library**

BookQuotes is an iOS app that captures photos of book pages with underlined passages, margin notes, and highlights, then uses AI to extract and organize your favorite quotes.

## The Problem

You underline sentences, draw margin lines next to important paragraphs, and jot notes while reading physical books. But those insights stay trapped in the book - tedious to transcribe and easy to forget.

## The Solution

1. **Capture a book cover** → AI extracts title, author, metadata
2. **Capture a marked page** → AI identifies and transcribes your underlines/highlights
3. **Build your library** → Beautiful display of quotes, searchable, shareable

## Features

### Phase 1 (MVP)

**Book Registration**
- Cover photo recognition with AI metadata extraction
- **ISBN Barcode Scanning** - near-100% accuracy via Google Books/OpenLibrary
- Manual editing and correction

**Quote Capture**
- **Pre-Upload Image Quality Assessment** - prevents failed extractions
  - Blur detection, brightness analysis, text confidence check
  - Actionable feedback: "Hold steadier", "Improve lighting"
- **Multi-Page Batch Capture** - capture 5-20 pages, process together
- **Custom marking definitions** - define your own annotation vocabulary
- Margin note transcription
- **Quote editing** - correct LLM extraction errors
- **Confidence scoring** - see AI certainty for each quote

**Data Quality**
- **Duplicate detection** - warns before saving similar quotes
- **Correction feedback loop** - your edits improve future accuracy
- **Offline capture queue** - capture anywhere, process when online

**Library**
- Grid/list view with book covers
- Search across quotes and books

### Phase 2
- Collections and tags for organization
- **Rich export formats**: Markdown, Plain Text, JSON, Notion, Obsidian
- Share styled quote cards
- Local backup to Files app
- Reading statistics

### Phase 3
- iCloud sync
- Home screen widgets
- Shortcuts integration
- AI-powered topic categorization

## Tech Stack

| Layer | Technology |
|-------|------------|
| UI | SwiftUI (iOS 17+, iOS 26 Liquid Glass ready) |
| Architecture | MV pattern (Model-View) |
| Persistence | SwiftData (local-first in v1; Cloud sync planned) |
| AI | Google Gemini API (proxied via BookQuotes backend) |
| Camera | AVFoundation |

## Documentation

### Getting Started

| Document | Description |
|----------|-------------|
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | **Start here** — Core patterns, state management, navigation |
| [docs/SERVICES.md](docs/SERVICES.md) | All services explained with usage examples |
| [docs/TESTING.md](docs/TESTING.md) | Testing strategy, patterns, and how to run tests |

### Feature Documentation

| Document | Description |
|----------|-------------|
| [docs/CAPTURE_FLOW.md](docs/CAPTURE_FLOW.md) | End-to-end capture system (single, batch, offline queue) |
| [docs/SEARCH_SYSTEM.md](docs/SEARCH_SYSTEM.md) | SQLite FTS5 search architecture and query processing |
| [docs/CUSTOM_MARKINGS.md](docs/CUSTOM_MARKINGS.md) | User-defined annotation vocabulary system |
| [docs/OFFLINE_AND_EXPORTS.md](docs/OFFLINE_AND_EXPORTS.md) | Offline queue and export formats (Markdown, Obsidian, Notion) |

### Technical Specifications

| Document | Description |
|----------|-------------|
| [docs/DATA_MODELS.md](docs/DATA_MODELS.md) | SwiftData models, relationships, queries |
| [docs/API_INTEGRATION.md](docs/API_INTEGRATION.md) | Gemini API service, prompts, error handling |
| [docs/UI_COMPONENTS.md](docs/UI_COMPONENTS.md) | Design system, components, screens |
| [docs/PRIORITY_FEATURES.md](docs/PRIORITY_FEATURES.md) | 5 priority features with full technical specs |

### Project Planning

| Document | Description |
|----------|-------------|
| [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) | Full project plan, phases, architecture |
| [AGENTS.md](AGENTS.md) | AI agent instructions and workflow guidelines |

## Project Structure

```
BookQuotes/
├── App/                    # App entry, tabs, routing
├── Models/                 # SwiftData models
├── Services/               # Gemini, Camera, Persistence
├── Features/               # Feature modules (Library, Capture, etc.)
├── Components/             # Reusable UI components
├── Utilities/              # Helpers, extensions
└── Resources/              # Assets, localization
```

## Getting Started

### Prerequisites
- Xcode 15.0+
- iOS 17.0+ deployment target

### Setup
1. Clone the repository
2. Open `BookQuotes.xcodeproj` in Xcode
3. Build and run on device/simulator
4. Sign in with Apple to enable AI extraction

## Privacy

- **Your images**: Sent to the BookQuotes proxy and then to Gemini for processing; not stored after processing
- **Your data**: Stored locally on device in this v1 release
- **Minimal account data**: Apple Sign-In identifier, optional email relay, and session status only
- **No analytics**: No tracking, no telemetry, no ad network SDKs

## Supported Marking Styles

| Style | Description |
|-------|-------------|
| Underline | Single line under text |
| Double underline | Emphasis/important passages |
| Margin line | Vertical line next to paragraph |
| Highlight | Colored marker highlighting |
| Bracket | Square/curly brackets around text |
| Margin note | Handwritten notes in margin |

## License

MIT License - see [LICENSE](LICENSE) for details.

---

Built with SwiftUI and powered by Gemini AI.
