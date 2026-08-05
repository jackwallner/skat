# iOS 27 compatibility audit: Skat Trainer

- Audit date: 2026-08-05
- Runtime: iOS 27.0 (24A5390f)
- Xcode: 26.6 (17F113)
- Scheme: `SkatTrainer`
- Unit target: `SkatTrainerTests`
- Overall: Pass with concurrency warnings

## Checks

- Debug build: Pass.
- Unit tests: Pass.
- Normal rebuild after tests: Pass.
- Install and launch smoke test: Pass.
- Runtime UI snapshot: Pass. German onboarding rendered.

## Findings

- `SkatTrainer/Utilities/Theme.swift:180,187,194` has main-actor isolation warnings for haptic calls or initialization.
- `SkatTrainerTests/ReviewPromptTrackerTests.swift`, `PracticeRecordStoreTests.swift`, and `ProgressStoreTests.swift` contain main-actor isolation warnings.
- No iOS 27-specific compiler error or runtime blocker was observed.

## Recommended follow-up

- Isolate haptic work on the main actor and clean test actor annotations before enabling warnings-as-errors.
