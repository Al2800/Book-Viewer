# Characterization: Book Deletion Prompt Refactor

Date: 2026-07-01

## Scope

This slice characterizes the shared destructive book-deletion prompt used by Library browsing and Book Detail.

It does not change model deletion, `ModelContext` saves, haptics, routing, dismissal, or confirmation-dialog state ownership.

## Characterized Behaviour

`BookDeletionPromptTests` pins:

- dialog title includes the book title in the existing format.
- destructive button title remains `Delete Book and All Quotes`.
- singular copy uses `1 quote`.
- zero and many counts use `quotes`.

## Refactor Rule

`BookDeletionPrompt` owns only deterministic user-facing copy for book deletion.

`LibraryView` and `BookDetailView` still own delete side effects because they coordinate SwiftData, haptics, routing/dismissal, and dialog state.

## Current Verification Blocker

The focused tests could not be run in this session because Xcode failed before project compilation due local simulator/cache service errors. See the matching verification note for command output summary and follow-up commands.
