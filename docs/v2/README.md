# BookQuotes v2 product reset

**Status:** Implementation in progress  
**Engineering baseline:** TestFlight Build 51 / `main` at the start of the reset  
**Live product:** The existing App Store release remains the public fallback while v2 develops behind explicit boundaries.

BookQuotes v2 is a product reset built on the existing capture, extraction, persistence, search and export engineering. It is not a separate application and it is not a rewrite.

## Product definition

> BookQuotes is the fastest and most trustworthy way to turn markings in physical books into a searchable personal reading memory.

The product is organised around three user outcomes:

1. **Capture:** save marked material with minimal interruption.
2. **Remember:** preserve passages with source context and provenance.
3. **Connect:** search, resurface and eventually compare ideas across books.

The intended primary surfaces are **Reading**, **Capture** and **Studio**. Search and later connection work remain capabilities inside Reading, not a primary tab. Settings is a secondary sheet from Reading.

## Documents

- [`PRODUCT_SPEC.md`](PRODUCT_SPEC.md): complete product, interaction, visual and release specification.
- [`ARCHITECTURE.md`](ARCHITECTURE.md): target boundaries, state ownership and migration strategy.
- [`DELIVERY_PLAN.md`](DELIVERY_PLAN.md): phased implementation and pull-request programme.
- [`AGENT_CONTRACTS.md`](AGENT_CONTRACTS.md): mandatory rules for human and AI coding agents.
- [`decisions/0001-keep-v2-in-main-repository.md`](decisions/0001-keep-v2-in-main-repository.md): decision to retain v2 and extraction work in this repository.

## Implementation policy

- New structure is introduced behind explicit feature boundaries until it has passed TestFlight verification.
- The current capture and extraction stack is reused rather than duplicated.
- Product navigation may change substantially; data compatibility and recoverability may not.
- On-device extraction is benchmarked against the existing cloud path before it controls automatic user-visible selection.
- Each pull request must identify the user journey it changes and its acceptance criteria.

## Governing test

Every proposed feature should answer yes to at least one question:

- Does it make marked material easier to capture?
- Does it make a saved passage easier to verify or recover?
- Does it make the reader's material easier to find?
- Does it help the reader connect or use ideas they deliberately selected?

Anything else remains secondary to the v2 core.
