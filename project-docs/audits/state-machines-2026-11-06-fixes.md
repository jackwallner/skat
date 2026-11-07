# State machine fixes, 2026-11-06

Fixes for the claims in `state-machines-2026-11-06-review.md`, in the review's ranked order, using its corrected routes and impact.

**Summary: 7 in-scope claims. 7 fixed (B1 with P8, B2, B3, B4, B5, G1), 0 held for Jack, 0 skipped (one B4 upgrade-window residual left alone, see Skipped). 7 fix commits, 26 new regression tests (24 unit, 2 UI kept from the audit's repro: the claim and its control).**

## Claims

| Id | Review verdict | Outcome | Commit | Regression test | What changed |
|---|---|---|---|---|---|
| B1 deck undo keeps the recorded answer | CONFIRMED | fixed | `fe900f4` | `SkatTrainerTests/DeckUndoTests` (7 tests: both swipe directions, earlier history restored exactly, newest first, persistence); `SkatTrainerUITests/DeckUndoUITests` (the audit's UI repro, renamed) | Before each answer the deck takes an `AnswerSnapshot` (the item's seen/missed marks in `ProgressStore` and its `PracticeRecord`, or none). Undo restores it. New `ProgressStore.marks/restoreMarks` and `PracticeRecordStore.savedRecord/restoreRecord` |
| P8 choice card graded twice after undo | CONFIRMED with B1 | fixed with B1 | `fe900f4` | `DeckUndoTests.testChoiceCardPickedAgainAfterUndoIsGradedOnce`, `testNewestFirstRestoresTheStartingState` | The pick's snapshot is kept until the swipe commits it. Undo also takes back a pick on the card now in front, newest first |
| B2 reminders never reconcile with iOS | UNVERIFIED, settled: reachable | fixed | `6537016`, `0818e2f` | `SkatTrainerTests/ReminderScheduleTests` (6 tests, fake center that refuses `add` while notifications are off, as iOS does; `testARestoredPhoneAsksAgainAndSchedules`, `testARefusalOnARestoredPhoneKeepsTheToggles` for the restore route) | `UNUserNotificationCenter` sits behind a small `ReminderCenter` protocol. `AppSettings.reconcileReminders()` re-adds every enabled reminder whenever the app becomes active and iOS allows notifications. When a reminder is on and iOS has not been asked yet (a phone restored from a backup keeps the toggles, not the permission or pending requests), iOS is asked once. The toggles keep the player's choice while iOS says no, so the reminders return with the permission |
| B3 reminder time shifts after a zone change | CONFIRMED-MINOR | fixed | `ba635ca` | `ReminderScheduleTests.testChosenTimesSurviveAZoneChangeWhileTheAppIsResident` (Berlin 17:00 still 17:00 in New York, picker and trigger, daily and game night), `testStoredTimesReadBackAndEditsAreStored` (existing stored times) | `reminderTime` and `gameNightReminderTime` are computed from the stored hour and minute at the moment they are read (today, current zone), not a year-1 `Date` built at launch. Triggers are built from the stored integers. Storage is unchanged |
| B4 weekly gain counts Skat+ items again on re-subscribe | CONFIRMED-MINOR | fixed | `f20323b` | `MasteryLedgerTests.testALapseAndReturnInventsNoGain` (the repro's scenario), `testAnsweringStillCountsAsGain` | Home writes the ledger through `MasteryLedger.record(from:)`, which always counts every known item, Skat+ included, whatever the membership. Free players cannot answer Skat+ items, so the count only moves with practice. This also retires the `membershipResolved` guard it needed. Rule file updated |
| B5 streak grows for one date across zones | CONFIRMED-MINOR | fixed | `d36f494` | `ProgressStoreTests.testTwoSessionsOnOneDateAcrossZonesKeepTheStreak` (the repro's Tokyo to Los Angeles case), `testAStreakStoredAsADateStillCounts` (upgrade), `testAStreakSpanningADaylightSavingChangeGrows` | `progress.lastActiveDay` is now a local day key ("2026-11-06", as `MasteryLedger` uses). A `Date` stored by earlier builds still reads, as the date of its midday, so existing streaks carry over in the writing zone and in zones within 12 hours of it |
| G1 lapse while closed keeps the game night reminder | UNVERIFIED (review's gap), settled: reachable | fixed | `ab6c940` | `SkatTrainerTests/LapsedReminderTests` (3 tests) | `SubscriptionService.confirmedNotMember` is true when a customer record answered in the last 5 minutes shows no membership. Home turns the game night reminder off on it, as it already did when `isPro` turned false while mounted. Older cached records never set it |

### How the unverified claims were settled

- **B2.** Apple documents `UNError.notificationsNotAllowed` ("The app isn't authorized to schedule or receive notifications") as the result of adding a request without authorization, and the review's own probe got the same refusal from `add` under `notDetermined`. The review's sharper route is therefore reachable: notifications off in iOS, edit the reminder time, toggle or (Skat+) weekday in the app (`removePendingNotificationRequests` runs, `add` is refused), notifications back on, and the toggle reads on with nothing pending. The restore-to-a-new-device route had a second hole: with permission undecided on the new phone, nothing ever asked iOS, so the reminders could not come back at all. `0818e2f` asks once when the app becomes active with a reminder on and permission undecided. No device run was possible on this headless machine; the fake center encodes Apple's documented refusal.
- **G1.** RevenueCat's `CustomerInfo.isDateActive` (purchases-ios `Sources/Identity/CustomerInfo+ActiveDates.swift`) judges an entitlement against the record's `requestDate` only within a 3-day grace period, and against the current date after that. A member who lapses and does not open the app for more than three days after the last fetch therefore starts at `isPro == false` from the cached record in `start()`, before Home mounts. `isPro` never changes, so the `onChange(isPro)` auto-off never ran and the weekly Skat+ reminder kept firing and opening the paywall. The same rule is why the fix ignores cached records: a member who renewed would read as lapsed in a stale cache until the network answers.

### Fail without the fix

The new unit tests call the APIs the fixes add (`AnswerSnapshot`, `ReminderCenter`, `reconcileReminders`, `record(from:)`, `confirmsNoMembership`), so they do not build without them. The scenarios they assert are the audit's repro claims, which failed on unfixed code with their preconditions passing (audit run `skat@20261106-114814-a26d-claude-imacf938-1106-134039-12421`, review run `skat@20261106-153050-7064-claude-mbpro0c01-1106-153454-25634`): B3 read 11:10 instead of 17:00, B4 returned a gain of 5 instead of none, B5 returned a streak of 2 instead of 1. `DeckUndoUITests.testUndoTakesTheAnswerBack` is the audit's UI repro unchanged apart from names; it failed on its claim before the fix in UI runs `skat@20261106-114814-a26d-claude-imacf938-1106-150653-27401` and `skat@20261106-153050-7064-claude-mbpro0c01-1106-155625-29512`.

The audit's notification repro tests were not kept: the review showed they ran against the real center without authorization (UNErrorDomain 2003), so their controls could not pass. The fake center replaces them.

## Held for Jack

None. No fix touches the trial or onboarding flow, prices, paywall offers, App Store Connect or RevenueCat.

## Skipped

- **B4, upgrade window only.** Ledger entries written by earlier builds while a member was lapsed are free-scope counts, and the format does not say which scope wrote them. A lapsed member who opened Home on an earlier build, updates and comes back within 7 days still sees the old fake "+N" once, for at most a week. Fixing that would mean ignoring every pre-update ledger day, which hides the weekly gain chip for every updating player for up to a week to correct a rare flattering number. That makes the experience worse, so the stored ledger is read as before.

## Not in scope

- P1, P2, P3, P4, P6, P7: product calls per the review. Left alone.
- P5 (paywall requested while Settings is open): the review files it as a product call, not run. Its only route is a non-member tapping a game night notification while Settings is up; G1 now turns that reminder off for lapsed players, which removes the main way a non-member gets one. Not changed.
- The Android port's `ProgressStore.kt` stores the last active day the same way as the old iOS code (B5). This task covers the iOS app only.

## Test results

All on gh-sim, Xcode 27.1, iPhone 17, iOS 27.2, at `0818e2f` (every fix applied).

- Full unit suite, `gh-sim test --scheme SkatTrainer`: run `skat@20261106-195629-18b7-claude-mbpro3af9d-1106-195948-12695` (GitHub Actions run 42336441749). **191 passed, 0 failed, 0 skipped.** Includes `DeckUndoTests`, `ReminderScheduleTests`, `LapsedReminderTests`, `MasteryLedgerTests` and `ProgressStoreTests`.
- UI regression test, `gh-sim test --scheme SkatTrainerUITests --only SkatTrainerUITests/DeckUndoUITests` (the `SkatTrainer` scheme runs only the unit target): run `skat@20261106-195629-18b7-claude-mbpro3af9d-1106-204522-3713` (GitHub Actions run 42339817091). **2 passed, 0 failed.**

No test failed, so nothing needed a rerun on b9a85ba89f0a696a3ad089169c0f9b1d78144a1b. The audit's repro suite (`state-machines-2026-11-06-repro.swift`) stays in this folder and is not in any test target.
