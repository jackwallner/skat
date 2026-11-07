VERDICT: PASS

# Verification of the state machine fixes, 2026-11-06 (second pass)

Independent check of `state-machines-2026-11-06-fixes.md` (second pass) against `state-machines-2026-11-06-review.md` and the whole change `b9a85ba89f0a696a3ad089169c0f9b1d78144a1b..f081604` (16 commits: 7 fixes, 2 reverts of three of them, 2 test commits, 3 docs commits, 2 fleet snapshots). Every claim was re-read in the code at HEAD. No app code or tests were changed. Run on the iMac (no Xcode); every test ran on gh-sim. This replaces the first-pass verify (FAIL), whose four "must change" items are all resolved (see the last section).

**Why PASS:** the five fixes for proved claims (B1 with P8, B3, B4, B5) work on the review's routes, and each regression test fails with its fix reverted on a scratch branch and passes at HEAD. The full unit suite passes (182/0/0) and so do all four deck UI tests. The two fixes for UNVERIFIED claims (B2, G1) are reverted, and their code is back to base. No regression, no scope breach and no newly failing test turned up.

## Disputed

The fixes doc has no "Disputed" section and disputes no review verdict, so there is nothing to rule on. It accepts the review's UNVERIFIED verdicts on B2 and G1 (holds them for a device run) and the review's product-call framing of P5. I agree with all three holds: each needs a device or sandbox state that a headless run cannot produce (notification permission cycling, a RevenueCat record that expired while the app was killed, a Springboard notification tap), and the review itself asked for a device check before spending a fix on B2.

## Fixes

| Id | Works on the route | Test asserts behaviour, fails without the fix | Regression check | Evidence |
|---|---|---|---|---|
| B1 deck undo keeps the recorded answer | yes | yes, proved (UI test) | clean | A snapshot of the seen/missed marks and the `PracticeRecord` is taken before every answer: plain card at `FlashcardDrillView.swift:373`, choice pick at `:258`. It rides in `SwipeRecord.answer` (`:41`, `:377`). Undo restores it (`:396`) before it puts the card back (`:400-405`). The toolbar button is the only undo route (`:86-94`, label `:93`) and the view has one caller (`RoomView.swift:200`). `AnswerSnapshot` (`PracticeRecordStore.swift:209-226`) restores both stores and persists them (`ProgressStore.swift:153-158`, `PracticeRecordStore.swift:105-108`). Scratch revert of the deck to base: `DeckUndoUITests/testUndoTakesTheAnswerBack` FAILED on its last assertion ("after taking the answer back, Dein Fortschritt has no answers"), control passed (run 42373379854). Passes at HEAD (run 42375760876) |
| P8 choice card graded twice after undo | yes | yes, proved (UI test) | clean | The pick's snapshot (`:258`) is committed into `lastSwipe` (`:370`) and cleared (`:379`). Undo restores a pending pick on the card now in front first, then the swiped card (`:395-397`), so a card answered twice ends where it started. `choose` keeps its `choicePick == nil` guard (`:255`). Scratch revert: `testChoiceCardPickedAgainAfterUndoCountsOnce` FAILED `Optional(2)` vs `Optional(1)` on its last assertion; `testControlTwoChoiceCardsCountTwoAnswers` passed, so the reader tells 1 from 2 (run 42373379854). Passes at HEAD (run 42375760876) |
| B3 reminder time shifts after a zone change | yes | yes, proved | clean | `reminderTime` and `gameNightReminderTime` are now computed from the stored hour and minute on every read (`AppSettings.swift:125-134`, `:158-167`, `:172-174`), so the picker (`SettingsView.swift:103`, `GameNightPrepView.swift:94`) reads the chosen wall-clock time in the current zone. Triggers use the stored integers (`:221`, `:252-254`), so toggling the reminder or changing the weekday (`:153`) reschedules at the chosen time. The setters send `objectWillChange` (`:128`, `:161`). Scratch revert (base `@Published` year-1 `Date` and triggers read from it, `ReminderCenter` seam kept so the test builds): `ReminderScheduleTests/testChosenTimesSurviveAZoneChangeWhileTheAppIsResident` FAILED `[11, 10]` vs `[17, 0]` (picker), `[1, 55]` vs `[7, 45]` (daily), `[11, 10, 7]` vs `[17, 0, 7]` (game night trigger) and the daily trigger after the toggle (run 42371703398) |
| B4 weekly gain counts Skat+ items again on re-subscribe | yes | yes, proved | clean (one note) | Home's write is `HomeView.recordMastery` (`HomeView.swift:200-216`), which calls `MasteryLedger.record(from:)` (`MasteryLedger.swift:48-50`): every known item, Skat+ included, whatever the membership. All four triggers (`HomeView.swift:57`, `:111`, `:113-114`, `:117`) go through it. Scratch revert of the static body to base (the `membershipResolved` guard plus `isPro` scope): `HomeMasteryTests/testALapseAndReturnInventsNoGain` FAILED `XCTAssertNil failed: "5"`, the review's exact value, while its sibling `testAnsweringStillCountsAsGain` passed, so the guard did not mask the write (run 42371703398). The test drives a real `isPro` change between the two writes (`HomeMasteryTests.swift:68-73`) |
| B5 streak grows for one date across zones | yes | yes, proved | clean (one note) | `progress.lastActiveDay` is now a gregorian local day key (`ProgressStore.swift:109`, `:125`), compared on a fixed UTC calendar (`:95-105`). Old stored `Date` values still read (`:86-91`). Readers are `currentStreak` (`:75-78`, used by `HomeView.swift:360-361`, `StatsView.swift:249`, `Drills/DrillCompleteView.swift:55`) and `bumpStreak`; reset removes the key (`:183`). Scratch revert of both functions to base: `ProgressStoreTests/testTwoSessionsOnOneDateAcrossZonesKeepTheStreak` FAILED 2 vs 1 (run 42371703398) |
| B2 reminders never reconcile with iOS | held, back at base | n/a | clean | No reconcile, no activation-time permission prompt: zero hits for `reconcile`, `getNotificationSettings`, `getPendingNotificationRequests` in `Shared`, `SkatTrainer` or the tests. `SkatTrainerApp.swift` has no diff against base. The `ReminderCenter` seam that came with the reverted commit stays (`AppSettings.swift:4-29`) and is behaviour-neutral: the same three `UNUserNotificationCenter` calls, and the permission callback still lands on the main actor (`:202-211`, `:232-241`) |
| G1 lapse while closed keeps game night | held, back at base | n/a | clean | Zero hits for `confirmedNotMember` or `confirmsNoMembership`. `SubscriptionService.swift` has no diff against base. The only auto-off is the base `onChange(of: subscriptions.isPro)` (`HomeView.swift:118-129`), unchanged |
| P5 paywall set while Settings is up | held, unchanged | n/a | clean | No code touched (`HomeView.swift:86-87` and `:130-133` match base) |

### What the tests leave open (device checks)

None of the five tests only asserts the fix's own hook: the UI tests read Dein Fortschritt, and the unit tests read the picker value, the scheduled trigger, the weekly gain and the streak. What they do not cover:

- **B1, the other direction and the other marks.** The UI tests read only the answer count (`PracticeRecordStore.totalAttempts`). Right swipe, undo, right swipe (a card known after one look) and the "Fehler wiederholen" missed list after an undone left swipe are covered only by `DeckUndoTests`, which call `AnswerSnapshot` directly. Device check: in Die Karten kennenlernen, swipe right, undo, swipe right, and confirm the mastery ring does not count the card; swipe left, undo, swipe right, and confirm the card is not in the review mix.
- **B3, a real zone change.** The test moves `NSTimeZone.default`. Device check: with Settings open on Tägliche Erinnerung at 17:00, switch the phone's time zone in iOS Settings, return to the app, and confirm the picker still reads 17:00 and the reminder fires at 17:00 local.
- **B4, a real lapse.** The test flips the local DEBUG override. A sandbox lapse and return within seven days would confirm the Home chip shows no "+N".
- **B5, a real flight.** Tested with `NSTimeZone.default`, same assumption as the review.

## What must change

Nothing.

## Regression check (check 2)

Each changed function, property and view was traced to all callers and readers.

- **Upgrade, stored data.** Reminder hour and minute keys and their defaults (9:00, 17:00) are unchanged (`AppSettings.swift:136-137`, `:169-170`), so existing times read back (`testStoredTimesReadBackAndEditsAreStored`). The ledger and practice record formats are unchanged. `progress.lastActiveDay` changes from `Date` to `String`, and the old `Date` still reads (`ProgressStore.swift:89-90`, `testAStreakStoredAsADateStillCounts` in Berlin, London and Dubai). Against base, the legacy read can only differ for a player whose current zone is 12 or more hours east of the zone that wrote the date, and then it reads one day later, which can delay one streak increment but never resets a streak (a later stored day shrinks the gap). Base was wrong in the opposite direction for every zone west of the writer.
- **Widgets, watch.** None: `project.yml` has only the app, unit test, UI test and screenshot targets. No App Group or shared defaults reader of any changed key.
- **Notifications.** Daily and game night triggers carry the same components as base (hour, minute, second, plus weekday for game night) and the same identifiers. The permission request and denial handling (`reminderEnabled = false`, `reminderPermissionDenied = true`) are unchanged in effect.
- **Entitlements and trials.** No change to `SubscriptionService`, paywall, onboarding, StoreKit configuration or RemoteConfig (zero diff). B4 stops reading membership for the ledger only. Every answer recorder (`QuizDrillView.swift:95`, `HandMatchDrillView.swift:103`, `DiscardDrillView.swift:160`, `FlashcardDrillView.swift:260`, `:375`, `PracticeRunView.swift:259`) sits behind `Room.isLocked` or the generated run, so a never-member's member-scope count equals their free-scope count, and their chip is unchanged.
- **Undo and edit paths.** Choice and plain cards both snapshot before they record. A card answered wrong, re-queued and picked again in front is restored newest first (`:395-396`), then the re-queued copy is removed (`:401-403`). A pick left on the front card when the player leaves the deck stays recorded, as before. `restoreRecord(nil)` deletes only the row the undone answer created. Home's `onChange(of: records.records.count)` (`HomeView.swift:111`) rewrites the ledger after an undo, and the ledger keeps the latest entry per day (`MasteryLedger.swift:33-41`), so no inflated entry stays behind. Each picker edit stores the integers and reschedules, as before.
- **Day and time zone.** B3 reads the stored wall-clock time in the current zone. B5 uses the same `Calendar.gregorianLocal` day key as the ledger and Skat Minute (`Calendar+Gregorian.swift:12-16`), so a non-gregorian device calendar cannot break the parse, and DST cannot move a gap (`testAStreakSpanningADaylightSavingChangeGrows`). The clock-backwards guard is kept (`ProgressStore.swift:117-120`). `quickSessionCompletedToday` still stores a `Date` and is untouched.
- **Localized text.** No user-visible string added or changed; the diff touches comments only.
- **iPhone Duo and iPad layouts.** No view's layout changed: `FlashcardDrillView` changes only state and the undo body, `HomeView` only the ledger call.

## Scope (check 4)

| Rule | Result |
|---|---|
| Change beyond the listed bugs | none. Every app hunk maps to B1/P8, B3, B4 or B5. The `ReminderCenter` seam came from the reverted B2 commit and is kept as B3's test seam, with no behaviour change. The rule file edit documents B4 |
| Trial or onboarding flow, prices, paywall offers, membership judgement, who sees a paywall or trial | none changed (zero diff in `SubscriptionService`, `PaywallView`, onboarding, StoreKit, RemoteConfig) |
| Backend, App Store Connect or RevenueCat change needed | none |
| Fix for an UNVERIFIED claim with no failing test on base | none. B2 and G1 are reverted and held |
| Stored setting or record cleared on an inferred state | none. Undo deletes only the row the player's own undone answer created |
| Stored format change that can reset data | none. B5's legacy `Date` still reads (see upgrade above) |
| Held item changed anyway | none. B2, G1 and P5 code matches base |
| In-scope claim missing, or skipped against the rules | none. B1-B5, P8, G1 and P5 are all in the fixes table; P1-P4, P6, P7 are product calls per the review. B2 and G1 (UNVERIFIED) are held for Jack with the device check that settles each, as the rules allow. The one "Skipped" entry is not a skipped claim: B4 is fixed, and the entry records a one-time upgrade residual (ledger days written by earlier builds while a member was lapsed). Its reason is "the fix makes the experience worse": the stored ledger does not record which scope wrote a day, so removing the residual means dropping pre-update days and hiding the weekly gain chip for a week for every updating player (or every member). The residual is at most one flattering "+N" for under a week, on a population the review already called small. I accept the skip. The rule against a skip whose evidence names a route that still reaches the fault applies to "no route reaches it" skips, not to this one |

## Test results

All on gh-sim, Xcode 27.1, iPhone 17, iOS 27.2.

| Run | Tree | GitHub run | Result |
|---|---|---|---|
| Full unit suite, `gh-sim test --scheme SkatTrainer` | HEAD `f081604` | 42370186634 (`...-imac80fb-1107-035501-7805`) | **182 passed, 0 failed, 0 skipped.** Matches the fixes doc (182/0/0, run 42367766912). All 14 added or edited unit tests are in it and passed: `HomeMasteryTests` (2), `DeckUndoTests` (6), `ReminderScheduleTests` (2), `ProgressStoreTests` B5 (3), `MasteryLedgerTests/testAnsweringStillCountsAsGain` |
| Deck UI tests plus launch, `gh-sim all --scheme SkatTrainerUITests --only SkatTrainerUITests/DeckUndoUITests` | HEAD `f081604` | 42375760876 (`...-imac80fb-1107-051039-2202`) | **4 passed, 0 failed.** Both claims and both controls |
| Scratch revert, unit, one `--only` run of 5 tests | B1/P8 deck, B3, B4, B5 reverted to base, tests kept | 42371703398 (`...-imac80fb-1107-041555-26169`) | As intended: B3 FAILED (`[11, 10]` vs `[17, 0]`), B4 FAILED (`"5"` vs nil), B5 FAILED (2 vs 1); B4 sibling `testAnsweringStillCountsAsGain` and B1 helper `testUndoneMissThenRightCountsOnlyTheRightAnswer` passed (both expected: neither can see its fix's revert) |
| Scratch revert, UI, `DeckUndoUITests` | same scratch tree | 42373379854 (`...-imac80fb-1107-043822-31894`) | As intended: `testUndoTakesTheAnswerBack` and `testChoiceCardPickedAgainAfterUndoCountsOnce` FAILED on their last assertions (P8: `Optional(2)` vs `Optional(1)`); both controls passed |
| Home screenshot, `gh-sim launch` with the onboarded launch arguments | HEAD `f081604` | 42377783976 (`...-imac80fb-1107-053700-15825`) | Launched, Home captured (`shots/launch.png`) |

No test failed at HEAD, so no base comparison or flaky rerun was needed. No run failed on infrastructure.

The top-three proof (B1, B3, B4 in the review's ranking, plus B5) took two scratch runs, not one: the `SkatTrainer` scheme runs only the unit target and the `SkatTrainerUITests` scheme only the UI target (`project.yml:89-118`), and B1's and P8's only tests of the shipping route are UI tests. The scratch branch `scratch-revert` was deleted afterwards; this branch carries only this doc commit on top of `f081604`.

## Screens (check 5)

The changed views are `FlashcardDrillView` (undo state, no layout change) and `HomeView` (the ledger write, no layout change).

- Home at HEAD, real screenshot from run 42377783976 (`shots/launch.png`, onboarded launch arguments): header "Skat Trainer", streak and known chips at 0 and 0, the Loslegen card, the Übungsmodi row (Endlos üben and Skat Minute locked, Skatabend planen), and the rooms Karten & Reizen 0/3, Spielarten 0/2, Drücken 0/2. Layout matches the screen before the change; the weekly gain chip is absent, as expected on a fresh install with no earlier ledger day.

- Deck after undo at HEAD, from the UI test's own captures in run 42375760876: "0 von 12 geschafft" with Die Karten kennenlernen back in front, then Dein Fortschritt shows "Noch keine Übung" with no "Antworten" row. After the P8 sequence the choice deck reads "1 von 6 geschafft" and Dein Fortschritt shows one answer. The app has no deep links, so no pixel screenshot of the deck can be taken by launch.
- The `all` run's own launch screenshot (`shots/launch.png`, run 42375760876) is a fresh install and shows the first onboarding page ("Zwischen den Runden sicherer werden"), rendered normally. Onboarding is not in the diff.

## Previous verify, resolved

1. B2 and G1 fixed unverified claims: both reverted (`revert: hold the reminder reconcile fix until a device run proves it`, `revert: hold the closed-app lapse reminder fix until a device run proves it`) and held for Jack. Confirmed back at base above.
2. B4 test could not see the bug: `HomeMasteryTests/testALapseAndReturnInventsNoGain` now fails on the base body (run 42371703398).
3. B1 and P8 had no test through the deck: `DeckUndoUITests` now drives both and fails on base (run 42373379854).
4. Wrong commit references: the fixes doc cites subjects only, and each one exists in the log.

## Notes

- `HomeView.recordMastery` takes `subscriptions _:` only so the test can pass a membership (`HomeView.swift:209-216`). If a later change made the private instance method (`:200-202`) read `subscriptions.isPro` directly instead of calling the static, `HomeMasteryTests` would not notice. Style, not a defect.
- B4 side effect for lapsed former members: their gain now includes Skat+ items going stale while they cannot practise them, so a lapsed player who learns free items while Skat+ items expire can see a smaller or no "+N". The chip never scolds (negative deltas read as nil, `MasteryLedger.swift:55-60`), and it matches the rule file's new wording. Not a regression.
- `AppSettings.today(hour:minute:)` falls back to `Date()` if `date(bySettingHour:)` returns nil, which cannot happen for stored hours 0 to 23; on a spring-forward day a stored time inside the skipped hour reads as the next valid time in the picker only, and triggers still use the stored integers.
- The `testChosenTimesSurvive...` daily half waits up to 100 `Task.yield()`s for the async permission path. It passed in both HEAD runs and failed only on the scratch revert as intended; if it ever flakes, that loop is the place to look.
- The audit's repro suite (`state-machines-2026-11-06-repro.swift`) still builds `AppSettings(defaults:)`, which compiles with the new defaulted `center:` argument. It is not in any target.
