VERDICT: FAIL

# Verification of the state machine fixes, 2026-11-06

Independent check of `state-machines-2026-11-06-fixes.md` against `state-machines-2026-11-06-review.md` and the whole change `b9a85ba89f0a696a3ad089169c0f9b1d78144a1b..8cb4a99` (9 commits: 7 fixes, the fixes doc, a fleet snapshot). Every claim was re-read in the code. No app code or tests were changed. Run on the iMac (no Xcode); every test ran on gh-sim.

**Why FAIL:** two of the seven fixes (B2, G1) fix claims the review filed as UNVERIFIED, and neither has a failing test on `b9a85ba`. Check 4 lists that as a failure in its own right. The five fixes for proved claims (B1 with P8, B3, B4, B5) work on their routes, and no regression or newly failing test turned up. The fixes doc turned B2 and G1 into "settled: reachable" by reading Apple's docs and RevenueCat's source. Its own text says the new tests "do not build without" the fixes. There is no run on unfixed code.

## Disputed

The fixes doc has no "Disputed" section and disputes no review finding, so there is nothing to rule on. Its upgrade of B2 and G1 from UNVERIFIED to "settled: reachable" is in effect a dispute of the review's verdicts. I rule against it: a documentation reading does not replace a failing run, and the review asked for a device check before any fix was spent on B2 ("Run the device check before spending a fix on it").

## Fixes

| Id | Works on the route | Test fails without the fix | Regression check | Evidence |
|---|---|---|---|---|
| B1 deck undo keeps the answer | yes | UI test yes (proved); unit tests no | clean | Snapshot before each answer, `FlashcardDrillView.swift:258` (choice pick) and `:373` (swipe). The pick's snapshot rides into `lastSwipe` at `:370`. Undo restores the newest first at `:395-396`. The button is the only route (`:86-94`, label `:93`), and `FlashcardDrillView` has one caller (`RoomView.swift:200`). Scratch revert of only `:395-396`: `DeckUndoUITests/testUndoTakesTheAnswerBack` FAILED on its claim ("after taking the answer back, Dein Fortschritt has no answers"), control passed (run 42351052922). `DeckUndoTests/testUndoneMissThenRightCountsOnlyTheRightAnswer` PASSED with the same revert (run 42348385436): the unit tests call `AnswerSnapshot.restore` themselves (`DeckUndoTests.swift:31-40`), so they guard the store helpers, not the deck |
| P8 choice card graded twice | yes | no direct test of the deck | clean | Same code. `pickAnswer` is cleared at commit (`:379`) and undo (`:397`), and `choose` keeps its `choicePick == nil` guard (`:255`), so after undo only the second pick is recorded. `testChoiceCardPickedAgainAfterUndoIsGradedOnce` is the same store sequence as `testUndoneMissThenRightCountsOnlyTheRightAnswer` and does not drive a choice card |
| B2 reminders never reconcile with iOS | not provable | no failing test on `b9a85ba` | clean (see notes) | **Check 4 failure.** The review verdict is UNVERIFIED. `ReminderScheduleTests` needs `ReminderCenter` and `AppSettings(defaults:center:)`, which do not exist at `b9a85ba` (zero hits in that tree), and the fake center's refusal under `.denied` (`ReminderScheduleTests.swift:20-23`) is the very premise the review said was unproved. Code: `AppSettings.swift:220-231`, called on launch and every activation (`SkatTrainerApp.swift:32`, `:38`). It never clears a toggle, so it does not breach the teardown rule |
| B3 reminder time shifts after a zone change | yes | yes (proved) | clean | Getter rebuilds today's date from the stored hour and minute (`AppSettings.swift:135`, `:168`). Triggers come from the stored integers (`:255`, `:286-288`). Storage keys and defaults are unchanged (`:145-146`, `:178-179`), so existing times read back. Scratch revert (year-1 `Date` built in `init`, triggers read from it): `testChosenTimesSurviveAZoneChangeWhileTheAppIsResident` FAILED with `[11, 10]` vs `[17, 0]`, the review's 11:10 (run 42348385436). Readers: `SettingsView.swift:103` and `GameNightPrepView.swift:94` bind through `$settings`, and the setter sends `objectWillChange` |
| B4 weekly gain after a lapse | yes | lapse test no; sibling test yes | clean | `HomeView.swift:212` now calls `MasteryLedger.record(from:)` (`MasteryLedger.swift:48-50`), which counts with `isMember: true` whatever the membership, so a lapse cannot remove Skat+ items from a day's count. The fix is on the route. But `testALapseAndReturnInventsNoGain` PASSED with the old Home logic (`membershipResolved` guard plus `isPro` scope) moved into `record(from:)` (run 42348385436): it calls `record(from:)` twice with no membership change between, so it cannot see the bug. `testAnsweringStillCountsAsGain` FAILED under the same revert (`nil` vs `5`), but it fails because the unresolved guard skips the write, not on the lapse route |
| B5 streak on one date across zones | yes | not run (outside the top three) | clean | Day key written as a string (`ProgressStore.swift:125`). Legacy `Date` values still read, as midday of the stored day (`:86-91`), so existing streaks carry over (`testAStreakStoredAsADateStillCounts`). `MasteryLedger.dayKey` uses the gregorian calendar in the local zone (`MasteryLedger.swift:112-115`), so non-gregorian device calendars cannot break `daysBetween`. Readers: `currentStreak` only (`HomeView.swift:357`, `StatsView.swift:249`, `DrillCompleteView.swift:55`); reset removes the key (`:183`) |
| G1 lapse while closed keeps game night | not provable | no failing test on `b9a85ba` | clean (see notes) | **Check 4 failure.** The review filed this gap as UNVERIFIED and named the check that would settle it (a sandbox subscription expiring while the app is killed). None was run. `LapsedReminderTests` tests the new `confirmsNoMembership` (`SubscriptionService.swift:434-436`), which does not exist at `b9a85ba`. The route claim rests on a reading of RevenueCat's `isDateActive`. The teardown itself is within the rules: `confirmedNotMember` is set only from a record answered within `freshBaselineAge` (300 s, `:101`, `:421`), and Home acts on it at `HomeView.swift:132-136` |

## What must change

1. **B2 and G1: back the fixes out, or prove them with a failing run on `b9a85ba`.** B2: a device run (revoke notifications, edit the reminder time, re-grant, read the pending requests) on unfixed code, plus a check that a backup restore leaves notification permission undecided. That restore premise is behind `ecf4e4f`'s new launch-time permission prompt (`AppSettings.swift:223-224`) and is not established anywhere. G1: a sandbox subscription that expires while the app is killed, relaunched after more than three days on unfixed code, with the game night toggle still on. Until then these are fixes for unproved claims.
2. **B4 test.** Add a test that fails if Home's write depends on membership again. Today nothing fails if `HomeView.recordMastery` goes back to `masteryByRoom(isMember: subscriptions.isPro)`, and the lapse test passed against the old logic.
3. **B1 and P8 unit tests.** They exercise `AnswerSnapshot` alone. The deck wiring is guarded only by the UI test, which covers a plain card's left swipe. A choice card undone and picked again (P8) has no test through the view.
4. **Fixes doc accuracy.** It cites commit `0818e2f` four times. No such object exists in the repo; the restore-route commit is `ecf4e4f`. Its test runs are said to be "at `0818e2f`". The suite rerun below at the real HEAD gives the same 191 passes, so the result stands, but the reference is wrong.

## Regression check (check 2)

Each changed function, property and view was traced to all callers and readers. The project has no widget, watch or App Group target (`project.yml` has only the app, unit and UI test targets), and no new or changed user-visible string. Duo and iPad layout is untouched: no view's layout changed.

- **Upgrade, stored data.** Reminder hour and minute keys are unchanged. The ledger format is unchanged. `progress.lastActiveDay` changes from `Date` to `String`, but the old value is still read (`ProgressStore.swift:89-90`), so no streak resets on upgrade. Practice records and the seen and missed sets keep their formats. `restoreRecord(nil)` deletes only the one row the undone answer created.
- **Notifications.** Daily and game night triggers have the same components as before (hour, minute, second, plus weekday for game night). `reconcileReminders` replaces pending requests under the same identifiers, so nothing doubles. It runs twice at a cold launch (`onAppear` and the `.active` change), which is harmless. Reconcile never turns a toggle off: `.denied` returns early (`:225-226`), and a refusal of the restore prompt keeps the toggles.
- **Entitlements and trials.** `isPro` and `membershipResolved` are judged exactly as before (`SubscriptionService.swift:419-420`). `confirmedNotMember` is read only by `HomeView.swift:132`. The removed `membershipResolved` guard in `recordMastery` had no other reader (`HomeView.swift:113`, `:252` still use the flag for their own purposes). Game night is Skat+ only (Settings link `SettingsView.swift:105`, Home tile locked for non-members `HomeView.swift:603-609`), so G1 cannot turn off a free player's reminder. The DEBUG local override makes `isPro` true, so it never sets `confirmedNotMember`.
- **Undo and edit paths.** Choice and plain cards both snapshot before they record. Undo takes back a pick on the card now in front, then the swiped card, newest first. Each picker edit stores the integers and reschedules.
- **Day and time zone.** B3 reads the stored wall-clock time in the current zone. B5 compares local date strings on a fixed UTC calendar, so DST cannot move a gap (`testAStreakSpanningADaylightSavingChangeGrows`). The clock-backwards guard (`gap < 0`) is kept.
- **Neighbouring transitions.** At launch, `reconcileReminders` and Home's `confirmedNotMember` auto-off both run on the main actor. Reconcile reads `gameNightReminderEnabled` after its await, so either it sees the toggle already off, or it schedules and the toggle's `didSet` cancels right after. The existing `onChange(isPro)` auto-off is unchanged. `onChange(of: records.records.count)` re-records the ledger after an undo, and the ledger keeps only the latest entry for the day (`MasteryLedger.swift:33-41`), so an undone answer leaves no inflated entry behind.

## Scope (check 4)

| Rule | Result |
|---|---|
| Change beyond the listed bugs | none. Every hunk maps to B1/P8, B2, B3, B4, B5 or G1. The rule file edit documents B4 |
| Trial, onboarding, prices, paywall offers, membership judgement, who sees a paywall | none changed. G1 removes the weekly Skat+ notification for confirmed-lapsed members, which was one way a non-member reached the paywall. That only extends the existing designed auto-off (P6) and is not a paywall rule change |
| Backend, App Store Connect or RevenueCat change needed | none |
| Fix for an UNVERIFIED claim with no failing test on `b9a85ba` | **FAIL: B2 and G1** |
| Stored setting cleared on an inferred state | none. Reconcile never clears. G1 clears the game night toggle only on a record RevenueCat answered within 300 s, the same freshness the churn baseline already uses (`SubscriptionService.swift:463`) |
| Stored format change that can reset data | none. The B5 format change reads the old value |
| Held item changed | none held |
| In-scope claim missing or skipped against the rules | none. All review claims (B1-B5, P8, the gap) are in the table. The one skip (B4's pre-update ledger days) gives "the fix makes the experience worse" with a reason: hiding the chip for every updating player for a week |

## Test results

All on gh-sim, Xcode 27.1, iPhone 17, iOS 27.2.

| Run | Tree | GitHub run | Result |
|---|---|---|---|
| Full unit suite, `--scheme SkatTrainer` | HEAD `8cb4a99` | 42343815372 (`skat@20261106-213815-bb1b-claude-imac0411-1106-214142-31054`) | **191 passed, 0 failed, 0 skipped.** Matches the fixes doc (191/0/0, runs 42336441749 and 42339817091) |
| B1 UI test plus screens, `all --scheme SkatTrainerUITests --only SkatTrainerUITests/DeckUndoUITests` | HEAD | 42353937254 (`...-1107-000457-17438`) | **2 passed, 0 failed.** The claim and its control both pass on the fixed code |
| Scratch revert, unit, 4 tests in one `--only` run | B1 view undo, B3, B4 reverted, tests kept | 42348385436 (`...-1106-224516-8138`) | B3 test FAILED (`[11, 10]` vs `[17, 0]`); B4 `testAnsweringStillCountsAsGain` FAILED (`nil` vs `5`); B4 `testALapseAndReturnInventsNoGain` PASSED; B1 `testUndoneMissThenRightCountsOnlyTheRightAnswer` PASSED |
| Scratch revert, UI, `DeckUndoUITests` | same scratch tree | 42351052922 (`...-1106-232256-22751`) | `testUndoTakesTheAnswerBack` FAILED on its claim; control passed |

One earlier dispatch of the scratch unit run failed on a GitHub API 403 rate limit before it reached a runner (infrastructure, no result). It was rerun as 42348385436. The scratch branch was deleted afterwards. This branch carries only this doc on top of `8cb4a99`.

The top-three proof (the review ranks B1, B3, B4) needed two runs, not one: the `SkatTrainer` scheme runs only the unit target, and B1's only test of the shipping route is a UI test in the `SkatTrainerUITests` scheme.

## Screens (check 5)

The only changed views are `FlashcardDrillView` (undo logic, no layout change) and `HomeView` (two `onChange` handlers and the ledger call, no layout change). The app has no deep links, so `gh-sim` can reach only Home by launch and the deck only through the UI test.

- Home at HEAD, `shots/launch.png` from run 42353937254: renders as before (header, chips 0 and 0, Loslegen card, training tiles, rooms). No layout change.
- Deck after undo at HEAD, from the UI test's own captures in the same run: the deck reads "0 von 12 geschafft" with "Die Karten kennenlernen" back in front and no undo button, and Dein Fortschritt then shows "Noch keine Übung" with no "Antworten" row. The control's capture shows "Antworten" after a swipe without undo.
- The 150 s screen recording (`--record-seconds 150`) ended while the test runner was still installing, so it holds only the simulator home screen. No pixel capture of the deck exists. The UI-tree captures above are what show the deck's state. The Settings and game night time pickers (fed by B3's computed times) could not be reached by launch.

## Notes

- `ecf4e4f` adds a system notification prompt at app activation when a reminder is on and permission is undecided (`AppSettings.swift:223-224`). The fixes doc names a restored phone as the only way to get there. That premise is unverified, and the prompt can land on top of whatever is showing at launch. This is part of the B2 failure above.
- At a cold launch on a restored phone, a lapsed member with only the game night toggle on could see that prompt before `confirmedNotMember` turns the toggle off. Rare, and it vanishes if B2's restore half is backed out.
- Offline-computed RevenueCat records (server unreachable) carry a current `requestDate`. For a lapsed member this sets `confirmedNotMember` from StoreKit's own empty entitlement list, not the network. StoreKit is authoritative for that answer, so I do not count it as an inferred teardown. Worth knowing if the rule is read literally.
- Downgrading to a pre-fix build reads a string `progress.lastActiveDay` as missing and restarts the streak at 1. Downgrade is not a shipping path.
- The B5 legacy read is exact only within 12 hours of the zone that wrote the date. Beyond that, the first read after the upgrade can be off by one day.
- `testChoiceCardPickedAgainAfterUndoIsGradedOnce` duplicates `testUndoneMissThenRightCountsOnlyTheRightAnswer` step for step.
- This doc is not added to `project-docs/README.md`, because the task allows committing only this file.
