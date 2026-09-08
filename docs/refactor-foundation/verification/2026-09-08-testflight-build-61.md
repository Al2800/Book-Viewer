# TestFlight candidate — 2.0.0 (61) — 2026-09-08

## Distribution decision

User authorization: “yes prep a testflight candiate for tests and push please”. This authorizes an internal beta candidate for the user's physical-phone testing, not public App Store submission or closure of unfinished feature acceptance.

- Release task: `book-quote-peo8`.
- Archived source: `eecfbb4` (shared-UI implementation through `f3f7f1b`; intervening `f88586d` is a social-queue audit).
- Bundle: `com.acampbell.bookquotes`; version `2.0.0`; build `61`, verified from the archive's app Info.plist.
- Apple build ID: `e08eba6c-db19-41f1-9073-8db48043dc01`.
- Apple uploaded date: `2026-09-08T02:02:17-07:00`.
- Processing: `VALID`; expired: `false`; non-exempt encryption: `false`.
- Beta detail: `internalBuildState = IN_BETA_TESTING`; `autoNotifyEnabled = true`.
- Internal **Test v1** group has one tester and `hasAccessToAllBuilds = true`; no individual build assignment needed.
- External state is `READY_FOR_BETA_SUBMISSION`; no external beta review or public App Review submission was made.
- Build-specific en-GB **What to Test** notes were saved through App Store Connect.

## Candidate changes

Quiet Reading/Capture/Studio workflow; consistent Passage terminology and scalable controls; adaptive light/dark action contrast; one active-book camera loop; selected-only save with durable review drafts and duplicate-safe retry; explicit mixed-page failure/manual recovery; source-image loading; Reading browse/search improvements; one Studio workspace with canonical preview/export fidelity, cropping/content safety and recoverable export errors.

No replacement SwiftData schema, extraction provider, persisted identity or explicit AI-consent policy. Physical file retirement remains separately approval-gated; no files were deleted. No app was installed on the paired phone by the agent.

## Verification and artifacts

`artifacts/coherent-ui/testflight-61-candidate-20260908.xcresult`:

- 786 unit tests, including one optional local-photo fixture skip, zero failures.
- 13 UI tests, including one opt-in system Reduce Motion skip under the normal setting, zero failures.
- Current/legacy shell navigation; Studio design/export/cropping/XXXL; three successive same-book captures; mixed-page manual recovery; real process-relaunch draft recovery.
- Actual system Reduce Motion was separately executed successfully in `foundation-motion-20260908-41.xcresult`; the restored normal setting explains this candidate's skip.
- Earlier light/dark numerical contrast, semantic accessibility and iPad/adaptive evidence remains in `docs/UI_COMPONENTS.md`.

Distribution:

- Archive: `artifacts/release/BookQuotes-61.xcarchive` — `ARCHIVE SUCCEEDED`.
- Local distribution export: `artifacts/release/BookQuotes-61-export` — `EXPORT SUCCEEDED` using unchanged tracked `scripts/ExportOptions-AppStore.plist`.
- Upload-only options: ignored `artifacts/release/ExportOptions-TestFlight-61.plist`, with build-number management disabled to retain 61.
- Initial upload via local Xcode accounts failed with **Failed to Use Accounts**; no success claimed for that attempt.
- Retry using the existing external App Store Connect API-key configuration succeeded: `artifacts/coherent-ui/testflight-61-upload-api-20260908.log` reports **Upload succeeded / EXPORT SUCCEEDED**.
- Archive/export/initial-upload logs are alongside that log. Credentials and private key material remain outside source control.
- `BUILD_NUMBER=61 node scripts/appstoreconnect_status.js` confirmed processing/encryption/group status; the build beta-detail endpoint confirmed internal testing availability.
- `git diff --check` passed. UBS, cm and Agent Mail are unavailable in this environment; not represented as passing checks.

## Device acceptance handoff

Testing is tracked under the still-open coherent-UI feature beads, not treated as completed by distribution:

| Bead | Device testing focus |
| --- | --- |
| `book-quote-coherent-ui-5sy4.2` | Camera/flash, permission denial/regrant, foreground recovery, ISBN/manual addition and switching, repeated same-book capture and batch recovery. |
| `book-quote-coherent-ui-5sy4.3` | Correct/select passages, Keep Draft and relaunch, save without duplication, source comparison, failed-page retry/manual entry, keyboard and spoken VoiceOver. |
| `book-quote-coherent-ui-5sy4.4` | Existing library survives upgrade; search/browse/filter/navigation and large-library responsiveness on the user's data. |
| `book-quote-coherent-ui-5sy4.5` | Long passages and fit recovery; actual Photos authorization/save, sharing, retained design after cancellation/failure, large-library picker. |

Foundation `.1` is closed; these four feature beads and the epic are not. Simulator evidence is not a camera, Photos, physical VoiceOver or complete performance sign-off. The user should install/update **2.0.0 (61)** in TestFlight and send reproduction steps/screenshots for failures. No uninstall or library deletion is needed for the upgrade test.
