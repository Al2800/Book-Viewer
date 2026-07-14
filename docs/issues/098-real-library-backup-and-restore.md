# 098 - Replace the quote export claim with a real library backup and restore

Status: closed
Area: Storage / Export / Data Portability
Priority: critical (release blocker 4)

## Problem

Settings describes Export All Data as a restorable backup, but the JSON contains only quotes and books represented by those quotes. It omits much of the library model, and no import or restore workflow exists.

## Acceptance Criteria

- [x] Product copy distinguishes sharing/export from full backup.
- [ ] A versioned backup schema includes all user-created library data and required assets.
- [ ] Books without quotes, relationships, tags, collections, notes, definitions, and settings are preserved.
- [ ] Import validates schema/version and supports cancel, conflict handling, and rollback.
- [ ] Round-trip restore produces an equivalent library.

## Verification

- Fixture-based export/import round-trip tests.
- Corrupt, partial, duplicate, and future-version backup tests.
- Manual restore on a clean simulator/device.

## Resolution

For v1, this is intentionally an export feature rather than a backup feature. The Settings destination is now `Storage & Export`, the action is `Export Quotes`, and the copy accurately limits the payload to quotes and associated book details. A versioned full-library restore remains a post-v1 feature and is no longer represented as available to users.
