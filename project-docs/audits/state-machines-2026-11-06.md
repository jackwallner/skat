# State machine audit, 2026-11-06

Audited committed code only (`git stash -u` found nothing to stash; the tree was clean). No code was changed. Tests ran on GitHub's Macs with `gh-sim test` (Xcode 27.1, iPhone 17, iOS 27.2).

**Summary: 5 bugs. 4 proved by a failing test with passing controls (B1, B3, B4, B5), 1 code path only (B2). 8 product calls (not counted).** Of the 5, B3 is proved for the picker and code path for the notification it reschedules.

## Test seams in this app

Used where they exist:

- Injectable `UserDefaults` suite: `ProgressStore(defaults:)`, `PracticeRecordStore(defaults:)`, `MasteryLedger(defaults:)`, `SkatMinuteStore(defaults:)`, `FeedbackService(defaults:session:)`, `AppSettings(defaults:)`, `WhatsNew.shouldPresent(defaults:)`, `SubscriptionService.observe(_:answeredAt:now:defaults:)`.
- Injected clocks: every store takes `now:`.
- `NSTimeZone.default` (the repo's tests did not use it before; it works, see B3 and B5).
- Pure functions: `MembershipTransitions`, `PaywallPricing.terms`, `OnboardingView.trialDisclosure`.
- XCUITest with launch arguments (`-progress.hasOnboarded YES` and friends) boots past onboarding without a debug hook.

Not available:

- No seam for `UNUserNotificationCenter`. `AppSettings` calls `UNUserNotificationCenter.current()` directly at AppSettings.swift:163, 176, 191, 198, 211, 231. I tried the real center in a hosted test: after the app's own scheduling path ran, `getPendingNotificationRequests` returned nothing on the GitHub runner (both controls failed, see "Recorded results"), so every notification claim stays Code path. A fake would need a protocol in app code, which this audit may not add.
- No constructible `CustomerInfo` fixture in the repo; the real RevenueCat SDK was not used. Entitlement logic was read, not run, except `observe`/`MembershipTransitions` which already have tests.
- `FlashcardDrillView.undo()` is private view state, so it was driven through the UI (B1).

## Bugs, ranked by impact

| Id | Bug | What the user sees | Promise | User route | Impact | Evidence | file:line |
|---|---|---|---|---|---|---|---|
| B1 | Deck undo restores the card but not the answer it recorded | After "Letzte Antwort zurücknehmen", Dein Fortschritt still counts the answer; the card is also in the missed set, its review schedule is reset and its mastery streak is broken | FlashcardDrillView.swift:88 accessibility label "Letzte Antwort zurücknehmen" ("take back the last answer"). Drills/AGENTS.md only promises the card returns to the front, so the label is the promise | Home > Karten & Reizen > Die Karten kennenlernen > tap card to flip > swipe left > toolbar arrow "Letzte Antwort zurücknehmen" > back to Home > "N Tage am Stück" (Dein Fortschritt) | Every free player who uses a deck (four rooms have one) and mis-swipes. Cost: wrong accuracy, wrong "Fehler wiederholen" queue, wrong mastery ring; none of it is recoverable except Settings reset | Proved: UI test `testUndoTakesTheAnswerBack` fails, control `testControlSwipeRecordsAnAnswer` passes | FlashcardDrillView.swift:365-366 (record), 380-393 (`undo` touches only `lastSwipe`, `choicePick`, `queue`, `isFlipped`) |
| B2 | Reminder toggles never reconcile with iOS permission or the pending requests | Toggle stays on ("Tägliche Erinnerung", "Vorbereitung ist geplant") when nothing is scheduled or iOS has notifications off; no warning until the player flips the toggle off and on | GameNightPrepView.swift:78 "Vorbereitung ist geplant"; :97 "Zu dieser Zeit öffnet die Mitteilung jeden <Tag> direkt deine persönliche Übungsrunde."; AppSettings.swift (doc above `reminderPermissionDenied`) shows the app treats a missing permission as a state worth surfacing | Home gear > Üben > Tägliche Erinnerung on (allow) > iOS Settings > Skat Trainer > Mitteilungen off (and on again) > back in the app: toggle still on. Second route: restore to a new iPhone from backup (UserDefaults come back, the pending requests are not in the app container) | Players with a reminder on after a notification permission cycle or a device restore. Frequency unknown, probably a few percent of reminder users; cost is a silently dead reminder they chose, in an app whose retention hook is the reminder | Code path. Nothing in the app reads `getNotificationSettings` or `getPendingNotificationRequests` (grep over Shared and SkatTrainer: zero hits). `AppSettings.init` (AppSettings.swift:132-150) does not schedule. All scheduler call sites: schedule at :99, :117, :126, :166, :201; cancel at :84, :109, HomeView.swift:127. Would settle it: a protocol around the center in `AppSettings`, then a test that builds settings with the toggle persisted on and asserts one `add`. Not provable on the gh-sim runner as is (controls failed). Whether iOS itself drops pending requests when permission is switched off is not verified | AppSettings.swift:132-150, :163-205 |
| B3 | Reminder time is round-tripped through a `Date` built in the launch-time zone, so it shifts when the zone changes while the app is resident | After a flight the picker shows 11:00 instead of 17:00; changing the weekday then reschedules the game night reminder at the shifted time | GameNightPrepView.swift:97 "Zu dieser Zeit ..." and the picker "Erinnerung" showing the saved time; the persisted hour and minute (AppSettings.swift:96-98, :123-125) are what the player chose | Player in Berlin sets Skatabend Do 17:00 > flies to New York, app stays suspended in memory > Home gear > Üben > Skatabend-Vorbereitung: picker reads 11:00 > change the weekday: reminder is rescheduled for 11:00 New York time | Travellers who keep the app resident across a zone change and have a reminder on (daily or game night). Rare, cost: a wrong displayed time always, a wrong reminder time after one more edit | Proved for the picker: `testGameNightHourSurvivesATimeZoneChangeWhileTheAppIsResident` fails with "11" vs "17" after the preconditions pass (zone applied, stored hour still 17, built reading 17). The rescheduled trigger hour is Code path (the center is not observable on the runner). Same shape for the daily reminder (:96, :184) | AppSettings.swift:123, :140, :146, :220 |
| B4 | Weekly gain chip counts items again when membership comes back | "+5 Fragen diese Woche gefestigt" (Home) and "Diese Woche 5 Fragen mehr gefestigt" (Dein Fortschritt) after re-subscribing, though nothing was answered for 8 days | StatsView.swift:78 "Diese Woche N Fragen mehr gefestigt", sub-line "Fragen, die du jetzt zweimal hintereinander richtig beantwortet hast."; HomeView.swift:359 "N Fragen diese Woche gefestigt" | Member lapses > opens Home as a free player (ledger records the free count) > re-subscribes via the paywall: `onChange(isPro)` records the member count (HomeView.swift:206) > chip shows the Skat+ items answered before the lapse as this week's gain | Winback members who open Home free before re-subscribing. Small population, cosmetic cost (a flattering number that is not true), but it is the exact fake-gain failure `.claude/rules/feedback-and-retention.md` says the ledger guards against | Proved: `testWeeklyGainIsNotInventedByAMembershipComingBack` fails (`weeklyGain` returned 5, expected nil); control `testControlWeeklyGainStaysNilWhenMembershipDoesNotChange` passes | MasteryLedger.swift:46-52, HomeView.swift:206, Mastery.swift:75-87 |
| B5 | Streak adds a day for two sessions on the same calendar date when the zone changes between them | Streak shows 2 after practising on 6 Nov in Tokyo and again on 6 Nov in Los Angeles | ProgressStore.swift:84 "Streak counts consecutive calendar days with at least one finished drill." | Practise Wed 6 Nov 10:00 in Tokyo > fly to Los Angeles (arrive Wed 6 Nov) > finish another drill Wed 6 Nov 09:00 local > Dein Fortschritt "2 Tage am Stück" | Players crossing the date line eastbound across a zone change between two sessions. Very rare, cost: a streak one day high | Proved: `testStreakDoesNotGrowForTwoSessionsOnTheSameCalendarDateAcrossZones` fails ("2" vs "1") after preconditions pass; control `testControlSameZoneSameDayKeepsStreakAtOne` passes | ProgressStore.swift:75-100 (`lastActiveDay` stored as a start-of-day `Date` in the zone at write time, compared in the zone at read time) |

## Recorded results (gh-sim, real values)

Unit suite `SkatTrainerTests/StateMachineAuditRepro`, run `skat@20261106-114814-a26d-claude-imacf938-1106-134039-12421`: 8 tests, 2 passed, 6 failed.

| Test | Result | Role |
|---|---|---|
| testControlSameZoneSameDayKeepsStreakAtOne | passed | B5 control |
| testControlWeeklyGainStaysNilWhenMembershipDoesNotChange | passed | B4 control |
| testStreakDoesNotGrowForTwoSessionsOnTheSameCalendarDateAcrossZones | failed: `("2") is not equal to ("1")` | B5 claim |
| testWeeklyGainIsNotInventedByAMembershipComingBack | failed: `XCTAssertNil failed: "5"` | B4 claim |
| testGameNightHourSurvivesATimeZoneChangeWhileTheAppIsResident | failed: `("11") is not equal to ("17")` at the picker assertion; its later notification assertions also failed, inconclusive | B3 claim |
| testControlGameNightHourStaysSeventeenInTheSameZone | failed: `("nil") is not equal to ("Optional(17)")` | control for the notification half of B3: the center showed no pending request, so that half is inconclusive |
| testControlDailyReminderSchedulesWhenTimeIsEdited | failed: `XCTAssertNotNil failed` | B2 control: the center shows nothing even after the app's own scheduling, so B2's claim test cannot be trusted |
| testLaunchReschedulesEnabledRemindersThatAreNotPending | failed | B2 claim, discarded because its control failed. B2 stays Code path |

UI suite `SkatTrainerUITests/StateMachineAuditRepro`, run `skat@20261106-114814-a26d-claude-imacf938-1106-150653-27401`: 2 tests, 1 passed, 1 failed.

| Test | Result | Role |
|---|---|---|
| testControlSwipeRecordsAnAnswer | passed (preconditions: progress empty after Settings reset; undo button appeared after the swipe; progress no longer empty after leaving the deck) | B1 control |
| testUndoTakesTheAnswerBack | failed: `claim: after taking the answer back, Dein Fortschritt has no answers`. Preconditions passed: progress empty after reset, undo button appeared, undo consumed the swipe (button gone). Attachments `stats_empty_true_answers_false` before and `stats_empty_false_answers_true` after | B1 claim |

Two earlier attempts failed to compile (Swift 6 actor isolation in my test files, unrelated to the app); the files recorded here are the fixed ones.

## Product calls (not counted, no citation that the app promises otherwise)

- P1. The timed challenge's clock counts one-second sleeps (PracticeRunView.swift:243), not wall time. Whether backgrounding pauses the 90 s was not run. If it does, the best score can be gamed.
- P2. The daily reminder is a repeating static notification (AppSettings.swift:184): it fires after the player already practised today, and keeps firing for a player who stopped using the app.
- P3. Onboarding `stage` is view state. A kill during the primer or tour restarts onboarding at page 0 while the tour's practice session is already counted (streak 1, one session). `finish()` re-stamps `sessionsAtOnboarding`, so Home extras stay correct.
- P4. Skat-Minute's weekly count uses the completion date, not the played day (SkatMinuteStore.swift `completedThisWeek`). The copy says any five days count; replaying an old archive day this week counts toward this week.
- P5. HomeView has four independent `.sheet` modifiers plus a path on one NavigationStack. `consumePendingDestination` can set `showPaywall` while `showSettings` is already true (HomeView.swift:258-261); SwiftUI presents one at a time. Not run.
- P6. A lapse auto-disables the game night toggle (HomeView.swift:126-128) and a returning member must switch it on again. Consistent with "entirely Skat+ gated" but unannounced.
- P7. A queued churn moment is not replaced when a different departure happens first (`pendingChurnMoment == nil` guard, SubscriptionService.swift): a trial renewal-off ask can show "Bevor deine Probewoche endet" after the trial already lapsed.
- P8. Flashcard undo of a choice card re-opens the choice and grades the next pick again (FlashcardDrillView.swift:249-255), so one card can record two answers. This is the same cause as B1 (nothing recorded is undone) and is fixed with it.

## Related fixes, in order

1. B1: put the previous `PracticeRecord` (or nil) and the previous seen/missed membership into `SwipeRecord` and restore them in `undo()`; give `PracticeRecordStore` and `ProgressStore` a restore call. Clear a choice card's recorded pick the same way (P8).
2. B2: one `reconcileReminders()` called from `AppSettings.init` and when the scene becomes active: read authorization and pending requests, re-add what is enabled and missing, show the permission state when denied. Put the center behind a small protocol so the unit test can fake it.
3. B3: keep the picker value derived from the stored hour and minute at the moment it is shown, and build trigger components from the stored integers, not from a `Date` made at launch. The same change covers the daily reminder.
4. B5: store `lastActiveDay` as a local day key ("2026-11-06", as `MasteryLedger` and `SkatMinuteContent` already do) so a zone change cannot re-label the date.
5. B4: stop crediting items that were not answered inside the window: record the member count with a flag, or compute the gain from items whose `lastAnswered` is inside the window.

## State machines

Scope read: `Shared/Services/*`, `SkatTrainer/Views/*` (Home, Onboarding, Paywall, Settings, GameNightPrep, Skat-Minute, Drills), `SkatTrainer/AppRouter.swift`. There are no widget or watch targets and no backend function in the repo (the feedback sink is a Supabase table in another repo, read only through `FeedbackService`). Entitlements are read from RevenueCat in `SubscriptionService.apply`.

Invariant names are used in the transition tables as `I<machine>.<n>`.

### M1. Membership (SubscriptionService)

State is spread over `isConfigured` (private), `membershipResolved`, `isPro`, `isTrialing`, `expirationDate`, `membershipRecovery` (a Task), UserDefaults `membership.reinstallSyncDone`, `membership.lastSnapshot`, and (DEBUG only) `subscription.localProOverride`.

States:

| State | isConfigured | membershipResolved | isPro | isTrialing | expirationDate |
|---|---|---|---|---|---|
| U0 no store (simulator, screenshots) | false | true after `start()` | override only | false | nil |
| C0 configured, unresolved (cold start, nothing cached, offline) | true | false | false | false | nil |
| F free | true | true | false | false | nil |
| T trial | true | true | true | true | date |
| P paid (monthly or yearly) | true | true | true | false | date |
| L lifetime | true | true | true | false | nil |
| R recovering (reinstall sync running) | true | any | false | false | nil |

Invariants:

- I1.1 `isPro` false while `membershipResolved` is false must never be read as "not a member" by a consumer that sells, lapses, or records (rule file). Consumers: Onboarding CTA (guarded by `ensureOfferings` + `isRecoveringMembership`), Home `recordMastery` (guarded), Home `consumePendingDestination` (guarded for 4 s), Home `onChange(isPro)` (fires only on a change of `isPro`, so the initial false is never read as a lapse). No violation found.
- I1.2 `isPro == (entitlement active) || DEBUG override`; the snapshot used for churn never includes the override.
- I1.3 `isTrialing` implies `isPro`.
- I1.4 `reinstallSyncDone` is set only after a successful `syncPurchases`; a failed sync is retried by `ensureOfferings`.

Transitions (all through `apply(_:)`, from `start()` cache read, `refreshCustomerInfo`, `purchase`, `restore`, the RevenueCat delegate, or recovery):

| From | Event | To | Breaks |
|---|---|---|---|
| C0 | cached record read | F/T/P/L | none |
| C0 | network record | F/T/P/L | none |
| F | purchase `.purchased` | T or P or L | none |
| F | purchase `.pending` (Ask to Buy) | F (UI keeps message) | none; later delegate update flips to T/P |
| T | trial converts | P | none |
| T/P | renewal off | same + `willRenew=false` | arms churn |
| T/P | expiry | F | Home `onChange(isPro)` turns off game night toggle (HomeView.swift:126) |
| F (reinstall) | StoreKit owns entitlement | R then P/L | I1.4 on failure |

### M2. Churn ask

State: `membership.lastSnapshot` (nil or `MembershipSnapshot`), `membership.churnAskSpent` (Bool), `membership.pendingChurnMoment` (nil or `ChurnMoment`), `HomeView.churnPrompt` (@State).

Invariants: at most one ask per departure (I2.1); a returning member earns a fresh ask (I2.2); a first record older than 5 minutes is not a baseline (I2.3); a queued moment is dropped when renewal is back on (I2.4).

| From | Event | To | Breaks |
|---|---|---|---|
| none/none | first fresh record | snapshot saved | none |
| snapshot active+renew | renewal off | pending moment, spent=true | none |
| pending moment | member lapses before Home shows it | pending kept, new moment suppressed (`pendingChurnMoment == nil` guard) | copy mismatch only: sheet title still says the trial is about to end ("Bevor deine Probewoche endet", ReviewPromptSheet.swift) |
| pending moment | renewal back on | pending cleared, spent cleared | none |
| pending | Home bare 0.9 s | `consume`, sheet shown | none |
| pending | app killed | pending persisted | none |

### M3. Purchase flow (OnboardingView trial page, PaywallView)

State: Onboarding `purchasing`, `restoring`, `trialEligible`, `purchaseError`, `showPaywallFallback`, `page`, `stage`; Paywall `purchasing`, `restoring`, `selectedPlan`, `trialEligible`, `message`.

Invariants: a member is never sold (I3.1); the copy names the plan bought (I3.2); a cancel is not an error (I3.3); a changed eligibility redraws and does not buy (I3.4); a paid but unconfirmed entitlement says so (I3.5).

| From | Event | To | Breaks |
|---|---|---|---|
| idle | CTA tap, `isPro` | tour | none |
| idle | CTA tap, offerings missing | fallback paywall | none |
| idle | CTA tap, eligibility changed | redraw, no purchase | none |
| purchasing | `.cancelled` | idle | none |
| purchasing | `.pending` | idle + message | none |
| purchasing | `.purchased`, confirm fails | idle + message | none |
| purchasing | `.purchased`, confirm ok | tour / dismiss | none |
| paywall sheet open | `isPro` flips true | dismiss, Home pushes `pendingAfterUpgrade` | none |

No reachable invalid transition found in this machine. `Purchases.shared.purchase` runs only when `isConfigured`; `setLocalOverride` in the unconfigured branch of `purchase` is unreachable on a real device because the key is valid.

### M4. Onboarding

State: `stage` (@State: pages, howToPlay, tour), `page` 0..4, `skill level` (@AppStorage), `progress.hasOnboarded` (UserDefaults, RootView branches on it), `sessionsAtOnboarding`, `WhatsNew.lastSeenVersion`.

Invariants: `hasOnboarded` set only by `finish()` (I4.1); the tour's practice does not count for Home extras (I4.2); a fresh install is stamped as seen for What's New (I4.3).

Observed: `stage` is view state, so a kill during howToPlay/tour restarts at page 0 with `hasOnboarded == false` while the tour's `recordSession` has already been written (streak 1, totalSessions 1, `completions` set). `finish()` then writes `sessionsAtOnboarding = totalSessions`, which keeps I4.2. Product call P3.

### M5. Reminders (AppSettings + AppRouter + AppDelegate)

State per reminder: persisted `enabled` (UserDefaults), iOS authorization (never read), pending request in `UNUserNotificationCenter` (never read), and for game night the `AppRouter.pendingDestination` plus Home's `path`.

Invariants:

- I5.1 `enabled == true` implies a request with the fixed identifier is pending and iOS permits delivery.
- I5.2 The wall-clock time shown by the picker equals the time stored equals the time the trigger fires.
- I5.3 Game night reminder is enabled only for members (HomeView.swift:126 enforces it on an `isPro` change event).
- I5.4 A tap on the game night notification opens the prep session (member) or the paywall then the session (free).

| From | Event | To | Breaks |
|---|---|---|---|
| off | toggle on, permission granted | on + pending | none |
| off | toggle on, denied | off + alert (shared `reminderPermissionDenied`) | none |
| on+pending | time/day edited | pending replaced | none |
| on+pending | zone changes while process lives | picker shows shifted hour (proved); next reschedule fires at the shifted hour (Code path) | I5.2 (B3) |
| on+pending | iOS drops the requests / restore to new device / permission revoked | on, nothing pending | I5.1 (B2): nothing reads the center at init, on foreground or in the views |
| on | member lapses, Home mounted | off + pending cancelled | none |
| pending dest | cold launch | wait 4 s for membership | none |

### M6. Progress and streak (ProgressStore)

State: `streakCount`, `lastActiveDay` (a `Date` that is the start of a day in the zone current at write time), `totalSessions`, `completions`, `seenItems`, `missedItems`, `lastQuickSessionDay`, `sessionsAtOnboarding`.

Invariants: streak is consecutive calendar days with a finished drill (I6.1, doc comment ProgressStore.swift:84); streak shown never exceeds the live one (I6.2, `currentStreak`); `resetAll` clears every stat (I6.3).

| From | Event | To | Breaks |
|---|---|---|---|
| streak n | session, same local day | n | none |
| streak n | session, next local day | n+1 | none |
| streak n | session, gap > 1 | 1 | none |
| streak n | clock goes back | unchanged, `lastActiveDay` kept | none |
| streak n | zone change between two sessions on the same wall-clock date | n+1 | I6.1 (B5) |
| any | Settings reset | all cleared; `ReviewPromptTracker` kept on purpose | none |

### M7. Practice records and mastery ledger

State: `PracticeRecord` per item (`attempts`, `correct`, `streak`, `dueDate`, `intervalDays`, `ease`, `reviewSuppressed`), `bestChallengeScore`, `MasteryLedger.days` (day key to room to known).

Invariants: an answer recorded is an answer the player gave (I7.1); a ledger gain reflects practice inside the window (I7.2); free players are measured against what they can open (Mastery.swift:75).

| From | Event | To | Breaks |
|---|---|---|---|
| any | answer in a drill | record updated | none |
| flashcard | undo of last swipe | card back in deck, **record and seen/missed sets unchanged** | I7.1 (B1, proved by UI test) |
| ledger free day | membership returns | ledger day includes items answered before the lapse | I7.2 (B4) |

### M8. Flashcard deck (FlashcardDrillView)

State (all @State): `queue`, `isFlipped`, `drag`, `isFlinging`, `choicePick`, `lastSwipe`, `finished`.

Invariants: only a flipped card can be swiped (I8.1); a choice card is graded once, at pick time (I8.2); undo restores everything the swipe changed (I8.3).

| From | Event | To | Breaks |
|---|---|---|---|
| front | tap | flipped | none |
| flipped | fling right/left | `commit`: record + queue change + `lastSwipe` | none |
| committed | undo | queue and flip restored, `lastSwipe=nil`, `choicePick=nil` | I8.3 (B1); for a choice card the pick is graded again on the next pick (I8.2) |
| last card | fling right | finished -> DrillCompleteView records the session | none |

### M9. Quick session, Skat-Minute, game night session

State: `items` snapshot, `index`, `score`, `selection`, `answers`, `finished`, `progress.lastQuickSessionDay`, `SkatMinuteStore.results[dayKey]`.

Invariants: one result per day key (I9.1, enforced in `record`); the daily quick session is spent only on finish (I9.2); the challenge is the one built when the run started (I9.3).

Observed: a run started before midnight and finished after it records under the earlier day key with today's `completedAt`. That is consistent with I9.3 and counts for the week of completion (P4).

### M10. Practice run (endless, timed, review)

State: `items`, `index`, `selection`, `attempted`, `finished`, `secondsRemaining`.

Invariants: a run closed before any answer records nothing (I10.1, `finish()` guard); a review closed early records no session (I10.2); the timed clock is 90 s (I10.3).

Observed: the clock counts one-second sleeps (PracticeRunView.swift:243), not wall time (P1).

### M11. Review prompt tracker and feedback queue

State: `reviewPrompt.launchCount`, `lastShownDate`, `outcome`; `feedback.pending` (cap 20).

Invariants: only the write-review tap ends asks (I11.1); a 4xx drops a row, 408/429/5xx keeps it (I11.2); a flush cannot run twice at once (I11.3, `isFlushing`).

No invalid transition found.

### M12. Home presentation arbitration

State on HomeView: `path`, `showPaywall`, `showSettings`, `showWhatsNew`, `churnPrompt`, `pendingAfterUpgrade`, `homeOnScreen`, plus `router.pendingDestination` and `membershipWaitOver`.

Invariants: What's New and the churn ask appear only on a bare Home (I12.1); a deep link waits for membership resolution (I12.2); `pendingAfterUpgrade` is cleared when the paywall closes without membership (I12.3).

Observed: `consumePendingDestination` sets `showPaywall = true` while `showSettings` may already be true. Four independent `.sheet` modifiers hang on one NavigationStack; SwiftUI presents one at a time. See P5.
