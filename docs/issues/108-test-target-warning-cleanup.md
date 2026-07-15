# 108 - Remove test-target and Debug build warnings

Status: closed
Area: Tests / Build / Concurrency
Priority: medium

## Problem

After the production warning gate closed, clean test builds still emitted source diagnostics from
test infrastructure and Xcode warnings while attempting to strip Apple-signed XCTest frameworks.
These messages obscured new regressions and included a Swift 6 sendability warning in the local
HTTP test server.

## Acceptance Criteria

- [x] The hermetic HTTP server declares and documents its queue/lock-based sendability boundary.
- [x] `KeychainError` owns its `Equatable` conformance instead of relying on a test-only
  retroactive conformance.
- [x] Model and UI screenshot tests contain no dead or unreachable compiler paths.
- [x] Debug test builds do not attempt to strip Apple-signed XCTest frameworks.
- [x] A clean build-for-testing emits no warnings.

## Verification

2026-07-15:

- Hermetic server, ISBN playback, Book model, and Keychain tests passed 60 tests, 0 failures, and
  0 skips on iPhone 17 Pro / iOS 26.5.
- The onboarding UI compile/smoke check passed 1 test, 0 failures, and 0 skips.
- A clean `build-for-testing` completed successfully with zero compiler or framework-strip
  warnings.
- The post-change full gate passed 636 app-unit tests with one documented local-photo fixture
  skip, plus 101 UI tests with zero failures or skips on both iPhone 17 Pro and iPad Air 11-inch.
