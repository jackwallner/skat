# Low bug fixes, 2026-11-20

Catalog: `2026-11-20-bug-ux.html`. Base commit `4640270`. Final full-suite run: see below.

| Id | Title | Outcome | Commit | Proof | What changed |
|---|---|---|---|---|---|
| B1 | Onboarding cannot be resumed | fixed | 1fdfee9 | `OnboardingResumeTests/testOnboardingResumeStagePersistsUntilCleared`, run `skat@20261120-211437-1b63-claude-mbprof5a1-1120-211722-4632` (storage only, see notes) | A member who reaches the primer or tour has the stage saved (`ProgressStore.onboardingResumeStage`); `OnboardingView.init` restores it and `finish()` clears it. Loslegen users are not saved, so they still see the trial page again. |
| B2 | Restore tells a lapsed subscriber that no earlier purchase exists | fixed | a3c72dd | `PurchaseErrorCopyTests/testRestoreTellsALapsedMemberTheirMembershipExpired`, same run | `restore()` returns whether the customer record holds any entitlement; all three call sites use `PurchaseErrorCopy.notRestored`, which says "Dein Skat+ ist abgelaufen." for an expired record and keeps the old text for an account with none. No extra button: Settings has its Skat+ row beside Restore, and the paywall and trial page already sell. |
| B3 | Home today card and Skat-Minute hero do not roll over at midnight | fixed | 129fadd | `DayClockTests` (3 tests), same run (mechanism only, see notes) | New `DayClock` republishes `now` on `significantTimeChangeNotification` and `didBecomeActive` when the calendar day differs. Home (today card, streak chip, Minute badge) and `SkatMinuteView` (hero, week count, archive) read `clock.now` instead of `Date()`. |
| B4 | Drill finished with the date set ahead freezes the streak at 1 | fixed | 26c2769 | `ProgressStoreTests/testStreakCountsAgainAfterTheClockWasSetAheadAndRestored`: fails on base (`skat-base-mbprof5a1-1120-214858-6272`, streak 1 not 10), passes in the final run | In `bumpStreak`, a stored day more than 2 days ahead (more than any zone change can explain) is replaced by today and the count is left alone. One and two day backward steps keep the old early return (`testClockGoingBackwardsDoesNotRewindTheLastDay`, `testAFlightAcrossTheDateLineStillKeepsTheLaterDay`). |

## Final run

- Full suite at commit 129fadd (all four fixes): gh-sim run `skat@20261120-211437-1b63-claude-mbprof5a1-1120-211722-4632`, 189 tests, 189 passed, 0 failed, 0 skipped.
- Tests failing on the base commit too: none from the existing suite. The only base failure is the new B4 test, which is the intended before-state.

## For the reviewer

- B1 proof is storage only. A purchase cannot complete on a simulator (the production key is never configured there), so the view path (`onChange(of: stage)` saving only when `subscriptions.isPro`, `init` restoring, `finish()` clearing) is verified by reading, not by a UI test. The stage is saved only for members, so the non-member Loslegen path is unchanged.
- B3 was "plausible". SwiftUI reruns `body` only when an observed value publishes, and nothing observed published on foreground, so the bug is by construction; I did not prove it on a device. The tests cover `DayClock`, not the two views using it (no screenshot, a date rollover cannot be staged headless).
- B4 leaves a 1 or 2 day forward jump frozen for that many days, because those gaps are indistinguishable from a date-line flight (UTC+14 to UTC-12 is a 2 day shift).
- `DayClockTests.setUp` produces one Swift concurrency warning (a `@MainActor` property mutated from the nonisolated `setUp`). It is a warning only.
- The Android port (`android/`) was not touched; these four are iOS code.
- This machine had no `jq`, which `gh-sim get` needs; I used a copy from another fleet folder at `/tmp/jqbin`. Nothing in the repo depends on it.

## Needs Jack

Nothing.
