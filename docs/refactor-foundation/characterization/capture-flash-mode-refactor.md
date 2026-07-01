# Characterization: Capture Flash Mode Refactor

Date: 2026-07-01

## Scope

This slice characterizes the flash control metadata used by `CaptureControlsBar`.

The refactor keeps capture execution, camera setup, image processing, quality analysis, extraction, and review routing outside the slice.

## Characterized Behaviour

`CaptureFlashModeTests` pins:

- auto advances to on.
- on advances to off.
- off advances to auto.
- auto uses `bolt.badge.automatic`.
- on uses `bolt.fill`.
- off uses `bolt.slash`.

## Refactor Rule

`CaptureControlsBar` remains the SwiftUI control bar for haptics, animation, and callback invocation.

`CaptureFlashMode` owns only deterministic mode metadata. It should not own camera hardware state until the camera service exposes a characterized flash adapter.

## Current Verification Blocker

The focused tests could not be re-run in this session because Xcode failed before project compilation due local simulator/cache service errors. See the matching verification note for the exact command output summary.
