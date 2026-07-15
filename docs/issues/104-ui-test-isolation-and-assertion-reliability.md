# 104 - Make UI tests isolated and fail on missing workflow controls

Status: closed
Area: XCUITest / Release Gate
Priority: high (release blocker 13)

## Problem

The focused release suite reported 55 passes, 7 failures, and 1 skip. Six Settings tests inherited stale Add Book/camera state and could not find the Settings tab. The reading-status test logs that its required control is missing but still passes because no failing assertion is made.

## Acceptance Criteria

- [x] Focused release UI tests start from a deterministic app/database/navigation state.
- [x] Settings tests run individually and as a focused suite.
- [x] Required controls in the affected flows use failing assertions rather than best-effort branches.
- [x] Focused release suite has no skips. Remaining legacy skip sites are reported in issue 106.
- [x] The focused release UI matrix is green on supported phone and iPad simulators.

## Verification

- [x] Repeat the focused suite twice on iPhone.
- [x] Run representative reading-status tests individually on iPhone and iPad.
- [x] Preserve failure screenshots and result bundles as release evidence.

## Completed 2026-07-14

- Removed the unconditional launch tap from the shared UI-test setup. On an empty database it opened Add Book, which left the camera sheet over the tab bar and made Settings tests inherit stale state.
- Added stable Settings destination identifiers and made the shared iPad tab selector tolerate the floating tab bar's nested accessibility elements without weakening workflow assertions.
- The reading-status test now requires the real segmented control, selects Finished, saves, reopens the editor, and verifies persistence. The product control has an accessibility identifier in the editor.
- Fixed Custom Marking text entry: keystroke-by-keystroke sanitization removed spaces between ordinary words. Sanitization remains enforced on save, while the editor now provides an explicit keyboard Next/Done action to move reliably between fields.
- Focused Settings suite: iPhone 17 Pro passed 6/6 twice; iPad Pro 13-inch (M5) passed 6/6. Reading-status persistence passed individually on both phone and iPad.

## Evidence

- iPhone Settings suite, 6/6: `/Users/skyhub/Library/Developer/Xcode/DerivedData/BookQuotes-avxqmbzwmqonovbvenamjvakwlyv/Logs/Test/Test-BookQuotes-2026.07.14_16-11-10-+0100.xcresult`
- iPhone Settings suite repeat, 6/6: `/Users/skyhub/Library/Developer/Xcode/DerivedData/BookQuotes-avxqmbzwmqonovbvenamjvakwlyv/Logs/Test/Test-BookQuotes-2026.07.14_16-21-02-+0100.xcresult`
- iPad Settings suite, 6/6: `/Users/skyhub/Library/Developer/Xcode/DerivedData/BookQuotes-avxqmbzwmqonovbvenamjvakwlyv/Logs/Test/Test-BookQuotes-2026.07.14_16-17-59-+0100.xcresult`
- iPhone reading-status persistence, 1/1: `/Users/skyhub/Library/Developer/Xcode/DerivedData/BookQuotes-avxqmbzwmqonovbvenamjvakwlyv/Logs/Test/Test-BookQuotes-2026.07.14_16-13-12-+0100.xcresult`
- iPad reading-status persistence, 1/1: `/Users/skyhub/Library/Developer/Xcode/DerivedData/BookQuotes-avxqmbzwmqonovbvenamjvakwlyv/Logs/Test/Test-BookQuotes-2026.07.14_16-23-12-+0100.xcresult`
- Unit suite, 602 tests: `/Users/skyhub/Library/Developer/Xcode/DerivedData/BookQuotes-avxqmbzwmqonovbvenamjvakwlyv/Logs/Test/Test-BookQuotes-2026.07.14_16-24-56-+0100.xcresult` (0 failures, 1 existing skip)

## Full-Suite Regression 2026-07-15

- The complete iPhone UI target exposed stale navigation and offscreen lazy-stack selection in
  several library-backed workflows. `BaseUITestCase` now terminates the app before and after every
  case, and shared workflow helpers scroll until a control is rendered and hittable before tapping.
- Library cards and list rows are now real plain-styled buttons rather than gesture-only elements,
  preserving their context menus and press feedback while giving VoiceOver and UI automation a
  native button action.
- The complete iPhone 17 UI target passed 101 tests, 0 failures, and 0 skips on iOS 26.5. Result
  bundle: `/tmp/BookQuotes-full-ui-isolated-2026-07-15.xcresult`.

## Follow-up

The full UI target still contains 33 legacy `XCTSkip` branches. Camera hardware limitations can remain explicitly reported as environmental skips, but missing application controls, navigation, fixtures, or save actions must fail. That work is tracked separately in issue 106 and is not counted as green full-suite evidence.
