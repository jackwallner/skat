# Verification, 2026-10-22

- Swift engine/content XCTest: **67 passed, 0 failures**, using `python3 scripts/test-rules.py` (Swift 6, macOS XCTest, the same Foundation sources and tables as the iOS test target). Includes current generated counting, trick, Grand-matador and independent tactical-defense suites.
- Android: **66 passed, 0 failures, 0 skipped**, via `fm-gradle --local testDebugUnitTest` from `android/`. The wrapper selected the remote Mac, not the Air.
- XcodeGen and `git diff --check` passed.
- Native/JUnit table SHA-256: `82316a129fe7b804e9586ecb6ca3ee21d63e28f75993aec61d3600f2ca3483b6`; copies are byte-identical.
- Branch: `fix/rules-audit-20261022`, based on current origin/main. Original working-tree changes are preserved.
- TestFlight: **1.3.0 (42), VALID**, confirmed through App Store Connect (`4f83630f-087f-4f71-bd3f-c03431d0d966`). `./scripts/testflight.sh --no-bump` exited 0 after signed archive and upload; application code is from `8e33438`.

The host runner selects engine/content suites from the iOS target. It excludes persistence/mastery cases and one UI-only timer assertion in mixed test files. This is not a simulator UI run. Release archiving verifies application compilation separately.

The final 31-row scoring table includes Schwarz after announced Schneider, a loss in own Schwarz, and no duplicate charge for a lost announced Schneider stage. Both platform suites were rerun after this test-only reference extension.
