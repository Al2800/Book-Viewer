# 104 - Make UI tests isolated and fail on missing workflow controls

Status: open
Area: XCUITest / Release Gate
Priority: high (release blocker 13)

## Problem

The focused release suite reported 55 passes, 7 failures, and 1 skip. Six Settings tests inherited stale Add Book/camera state and could not find the Settings tab. The reading-status test logs that its required control is missing but still passes because no failing assertion is made.

## Acceptance Criteria

- [ ] Every UI test starts from a deterministic app/database/navigation state.
- [ ] Settings tests can run individually and in the full suite.
- [ ] Required controls use failing assertions rather than best-effort branches.
- [ ] Skips are reserved for genuine environmental limitations and reported separately.
- [ ] The release UI matrix is green on supported phone and iPad simulators.

## Verification

- Repeat the focused suite at least twice with randomized test ordering if supported.
- Run representative tests individually.
- Preserve failure screenshots and result bundles as release evidence.

