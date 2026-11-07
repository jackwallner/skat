# State machine fixes, 2026-11-06

Fixes for the claims in `state-machines-2026-11-06-review.md`, in the review's ranked order, using its corrected routes and impact. Second pass after `state-machines-2026-11-06-verify.md` (FAIL: B2 and G1 fixed unverified claims; B4 and P8 lacked tests of the shipping route; wrong commit references).

**Summary: 8 in-scope claims. 5 fixed (B1, P8, B3, B4, B5), 3 held for Jack (B2, G1, P5), 0 skipped (one B4 upgrade-window residual noted under Skipped). This pass adds 2 revert commits and 2 test commits on top of the first pass's fix commits. Every fix has a regression test that failed on base or on a scratch revert of the fix.**

Commits are cited by subject. "Base" means `b9a85ba89f0a696a3ad089169c0f9b1d78144a1b`.

## What the verify asked for, and what changed

| Verify item | Done |
|---|---|
| 1. B2 and G1: back the fixes out or prove them with a failing run on base | Backed out. Neither premise can be produced headlessly (see Held for Jack). Commits `revert: hold the reminder reconcile fix until a device run proves it` and `revert: hold the closed-app lapse reminder fix until a device run proves it` |
| 2. B4: a test that fails if Home's write depends on membership again | Home's ledger write is now `HomeView.recordMastery(records:subscriptions:ledger:now:)`, which receives the membership. `HomeMasteryTests` flips the membership from lapsed to member between two writes. Fails with the old membership-scoped body (scratch run below). The old `MasteryLedgerTests.testALapseAndReturnInventsNoGain`, which could not see the bug, is gone |
| 3. B1 and P8: test the deck, not only the store helpers | `DeckUndoUITests.testChoiceCardPickedAgainAfterUndoCountsOnce` drives a choice card through pick, Weiter, undo, pick, Weiter in Stich-Entscheidungen and reads Dein Fortschritt. Fails on base with 2 answers instead of 1; control reads 2 for two cards. The duplicate unit test `testChoiceCardPickedAgainAfterUndoIsGradedOnce` is removed |
| 4. Wrong commit references | This doc cites subjects only. The restore-route commit is `fix: ask for notifications again on a restored phone with reminders on`, now reverted with B2 |

## Claims

| Id | Review verdict | Outcome | Commit | Regression test | What changed |
|---|---|---|---|---|---|
| B1 deck undo keeps the recorded answer | CONFIRMED | fixed | `fix: deck undo takes the recorded answer back` | `SkatTrainerUITests/DeckUndoUITests/testUndoTakesTheAnswerBack` (fails on base, control passes); store helpers in `SkatTrainerTests/DeckUndoTests` | Before each answer the deck takes an `AnswerSnapshot` (seen/missed marks and the `PracticeRecord`, or none); undo restores it |
| P8 choice card graded twice after undo | CONFIRMED with B1 | fixed with B1 | `fix: deck undo takes the recorded answer back`; test in `test: drive a choice card through undo and a second pick in the deck` | `DeckUndoUITests/testChoiceCardPickedAgainAfterUndoCountsOnce` (fails on base: 2 vs 1), control `testControlTwoChoiceCardsCountTwoAnswers` | The pick's snapshot rides into the swipe record; undo restores newest first, so the second pick is the only answer |
| B3 reminder time shifts after a zone change | CONFIRMED-MINOR | fixed | `fix: keep reminder times on the chosen wall-clock time across zones` | `ReminderScheduleTests/testChosenTimesSurviveAZoneChangeWhileTheAppIsResident` (failed `[11, 10]` vs `[17, 0]` on a scratch revert, verify run 42348385436), `testStoredTimesReadBackAndEditsAreStored` (existing stored times) | Picker times are built from the stored hour and minute when read; triggers use the stored integers. Storage unchanged. The `ReminderCenter` seam from `fix: put enabled reminders back when the app becomes active` stays for this test; that commit's reconcile is reverted. The daily half of the test now reschedules by toggling the reminder off and on, the review's route |
| B4 weekly gain counts Skat+ items again on re-subscribe | CONFIRMED-MINOR | fixed | `fix: weekly gain no longer counts Skat+ items again after a lapse`; test in `test: drive Home's weekly gain write through a lapse and return` | `SkatTrainerTests/HomeMasteryTests` (2 tests); `MasteryLedgerTests/testAnsweringStillCountsAsGain` | Home writes every known item, Skat+ included, whatever the membership. The write is a static function that takes the membership so the test can change it |
| B5 streak grows for one date across zones | CONFIRMED-MINOR | fixed | `fix: count the streak by local calendar date across zone changes` | `ProgressStoreTests/testTwoSessionsOnOneDateAcrossZonesKeepTheStreak` (audit repro failed 2 vs 1 on base), `testAStreakStoredAsADateStillCounts` (upgrade), `testAStreakSpanningADaylightSavingChangeGrows` | `progress.lastActiveDay` is a local day key; a `Date` written by earlier builds still reads |
| B2 reminders never reconcile with iOS | UNVERIFIED | held | reverted by `revert: hold the reminder reconcile fix until a device run proves it` | none (the fake-center tests encoded the unproved premise) | Back to base behaviour: no reconcile on activation, no permission prompt at activation |
| G1 lapse while closed keeps the game night reminder | UNVERIFIED (review's gap) | held | reverted by `revert: hold the closed-app lapse reminder fix until a device run proves it` | none | Back to base behaviour: only an `isPro` change while Home is mounted turns the reminder off |
| P5 paywall requested while Settings is up | possible defect, not run | held | none | none | No change |

## Held for Jack

- **B2, reminders after a permission cycle or a restore.** Decision: run the device check, then say whether to reapply the reverted fix. What settles it on base: on a phone, turn a reminder on, switch notifications off in iOS Settings, change the reminder time in the app, switch notifications back on, then confirm whether the reminder fires (or read the pending requests in a debug build). For the restore half, restore a phone from a backup with a reminder on and check whether notification permission comes back undecided. A headless run cannot cycle notification permission (neither `simctl privacy` nor XCUITest's `resetAuthorizationStatus` covers notifications, and gh-sim offers no simulator settings step), and nothing in the app shows pending requests. If the device run fails, the reverted commits `fix: put enabled reminders back when the app becomes active` and `fix: ask for notifications again on a restored phone with reminders on` are the fix: revert the revert.
- **G1, a membership that ends while the app is closed keeps the Skat+ game night reminder.** Decision: run the sandbox check, then say whether to reapply the reverted fix. What settles it on base: a sandbox member with the game night reminder on lets the subscription expire with the app killed, waits more than three days after the last RevenueCat fetch, relaunches, and checks whether the toggle is still on and the weekly notification still fires. The simulator never configures RevenueCat (the production-key guard), so no headless run can produce a cached lapsed record. The reverted fix is `fix: turn the game night reminder off after a lapse while closed`.
- **P5, paywall set while Settings is presented.** Decision: run the check, then decide whether Home should close Settings before it presents the paywall. What settles it: with a non-member holding a pending game night notification (only reachable through G1's state), open Settings, tap the notification, then close Settings and tap the Home upgrade card; if the paywall does not open, `showPaywall` was stuck true. On the runner this needs a delivered local notification tapped from Springboard and the G1 state, neither of which a headless run can set up reliably. The review filed P5 as a product call and the route depends on G1, so it waits with G1.

## Skipped

- **B4, upgrade window only.** Ledger entries written by earlier builds while a member was lapsed are free-scope counts, and the stored format does not say which scope wrote them. A lapsed member who opened Home on an earlier build, updates and returns within 7 days can still see that old "+N" once, for at most a week. Fixing it means ignoring every pre-update ledger day, which hides the weekly gain chip for every updating player for up to a week. That makes the experience worse, so the stored ledger is read as before. The fix itself is not skipped.

## Not in scope

- P1, P2, P3, P4, P6, P7: product calls per the review. Left alone.
- The Android port's `ProgressStore.kt` stores the last active day the same way as the old iOS code (B5). This task covers the iOS app only.

## Test results

All on gh-sim, Xcode 27.1, iPhone 17, iOS 27.2.

| Run | Tree | GitHub run | Result |
|---|---|---|---|
| Full unit suite, `gh-sim test --scheme SkatTrainer` | HEAD | 42367766912 (`skat@20261107-005415-3317-claude-imac17e3-1107-032023-6603`) | **182 passed, 0 failed, 0 skipped.** 191 before this pass, minus 9 tests of the reverted B2 and G1 fixes, minus the two tests the verify showed could not see their bug, plus the 2 `HomeMasteryTests` |
| Deck UI tests, `gh-sim test --scheme SkatTrainerUITests --only SkatTrainerUITests/DeckUndoUITests` (the `SkatTrainer` scheme runs only the unit target) | HEAD | 42357886029 (`skat@20261107-005415-3317-claude-imac17e3-1107-010052-16180`) | **4 passed, 0 failed.** Both claims and both controls |
| Same deck UI tests | base plus only the new UI test file | 42361954275 (`skat-scratch-p8-imac17e3-1107-015837-1116`) | 2 passed, 2 failed, as intended: `testChoiceCardPickedAgainAfterUndoCountsOnce` failed `Optional(2)` vs `Optional(1)`; `testUndoTakesTheAnswerBack` failed on its claim; both controls passed |
| `HomeMasteryTests` | HEAD with `HomeView.recordMastery` counting in `subscriptions.isPro`'s scope again | 42364354177 (`skat-scratch-b4-imac17e3-1107-023200-15084`) | 1 passed, 1 failed, as intended: `testALapseAndReturnInventsNoGain` failed `XCTAssertNil failed: "5"`; `testAnsweringStillCountsAsGain` passed |

No test failed at HEAD, so nothing needed a rerun on base, and no test already failed there. Scratch trees were temporary worktrees, removed afterwards.

The audit's repro suite (`state-machines-2026-11-06-repro.swift`) stays in this folder and is not in any test target.
