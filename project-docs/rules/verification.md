# Verification, 2026-10-22

- Swift engine/content XCTest: **67 passed, 0 failures**, using `python3 scripts/test-rules.py` (Swift 6, macOS XCTest, the same Foundation sources and tables as the iOS test target). Includes current generated counting, trick, Grand-matador and independent tactical-defense suites.
- Android: **66 passed, 0 failures, 0 skipped**, via `fm-gradle --local testDebugUnitTest` from `android/`. The wrapper selected the remote Mac, not the Air.
- XcodeGen and `git diff --check` passed.
- XCTest/JUnit table SHA-256: `f39b63ff7fdaa8d18f42e4bdbf50a1b5dbfbc2bbf29a85a5742a8e41cc11ed6f`; copies are byte-identical.
- Branch: `fix/rules-audit-20261022`, based on current origin/main. Original working-tree changes are preserved.
- TestFlight build 42 prepared; upload follows code push, with final receipt recorded here.

The host runner selects engine/content suites from the iOS target. It excludes persistence/mastery cases and one UI-only timer assertion in mixed test files. This is not a simulator UI run. Release archiving verifies application compilation separately.
