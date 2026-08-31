# ADR 0001: Keep BookQuotes v2 and extraction work in the main repository

- **Status:** Accepted
- **Date:** 2026-08-31
- **Decision owners:** Product and engineering

## Context

BookQuotes has a live App Store product and a rapidly evolving TestFlight v2 line. The proposed reset changes product hierarchy and visual structure while relying on the same camera, extraction, persistence, source-image, search and export engineering.

The question is whether the reset should be built in a separate repository or inside `Al2800/Book-Viewer`.

## Decision

Build v2 in the existing repository. Introduce it through feature boundaries and a default-off product shell until release gates pass.

The extraction benchmark, local detector and cloud fallback remain in the same repository as the Capture UI that consumes them.

## Reasons

1. **One data model:** A second repository would either duplicate SwiftData models or require a package split before the domain is stable.
2. **One extraction contract:** UI uncertainty states and extraction calibration must evolve together.
3. **One migration path:** Existing App Store data must remain readable throughout v2 development.
4. **One verification system:** Unit, UI, TestFlight and physical-device evidence remain associated with the same commit history.
5. **Lower operational overhead:** A single-person lab benefits from fewer synchronisation and release boundaries.
6. **Selective reuse:** Existing engineering can be retained while product surfaces are replaced behind flags.

## Constraints

Keeping one repository does not mean keeping one undifferentiated application layer. The programme must:

- establish feature and domain ownership;
- prevent views from coordinating infrastructure;
- document invariants for coding agents;
- introduce v2 behind a reversible flag;
- avoid broad rewrites that mix UI, model migration and extraction research in one PR.

## Alternatives considered

### Separate v2 application repository

Rejected because it duplicates or prematurely extracts the most important shared contracts and complicates migration from the live app.

### Extract a shared Swift package first

Deferred. Package extraction before ownership seams stabilise would convert current uncertainty into public APIs that are difficult to change. Stable domain and infrastructure seams may be packaged later.

### Replace the current application in place without a flag

Rejected. The live and TestFlight products provide useful comparison baselines, and the reset requires iterative validation before becoming default.

## Consequences

Positive:

- fastest feedback between product and extraction quality;
- reuse of proven engineering;
- one migration and release history;
- easier end-to-end work for a small team.

Negative:

- temporary coexistence of legacy and v2 surfaces;
- pressure on shared files until boundaries improve;
- feature-flag and dual-shell test overhead.

These costs are accepted and must be removed before final v2 release.
