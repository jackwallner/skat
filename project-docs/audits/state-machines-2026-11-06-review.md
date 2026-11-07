# Review of the state machine audit, 2026-11-06

Independent review of `state-machines-2026-11-06.md` and its repro suite. Every claim was re-read against the code. Both repro suites were rerun once on gh-sim, alongside six review checks of my own (removed again afterwards). No app code was changed. The working tree was clean, so `git stash -u` had nothing to stash.

**Summary: 5 claims. 1 CONFIRMED (B1), 3 CONFIRMED-MINOR (B3, B4, B5), 0 NOT A BUG, 1 UNVERIFIED (B2). False-positive rate 0 of 5. The audit is accurate on mechanism but wrong in details: B2's main route probably does not break anything, B3's shown time is 11:10 rather than 11:00, B1's cost is overstated, and its notification controls rest on a false premise.**

## Reruns (real values)

Unit run `skat@20261106-153050-7064-claude-mbpro0c01-1106-153454-25634` (Xcode 27.1, iPhone 17, iOS 27.2), `SkatTrainerTests/StateMachineAuditRepro` plus `StateMachineReviewChecks`: 13 tests, 5 passed, 8 failed.

| Test | Result | Matches audit |
|---|---|---|
| Repro B5 claim | failed `("2") is not equal to ("1")`, preconditions passed | yes |
| Repro B5 control | passed | yes |
| Repro B4 claim | failed `XCTAssertNil failed: "5"`, preconditions passed | yes |
| Repro B4 control | passed | yes |
| Repro B3 claim | failed `("11") is not equal to ("17")` at the picker assertion | yes |
| Repro B3 control and both B2 tests | failed, center shows nothing pending | yes |
| Review: `add` with no authorization | `status=0 error=UNErrorDomain/2003 pendingHasID=false` | new: explains every failed notification control |
| Review: exact shifted time | `year=1 shown=11:10` | new: corrects B3's "11:00" |
| Review: DST alone does not shift the time | passed | new: rules out a wider trigger for B3 |
| Review: left swipe, undo, right swipe | passed: 2 attempts, 1 correct, missed set cleared, `needsReview` true, cleared by one more right answer | new: B1 impact |
| Review: right swipe, undo, right swipe | passed: the card reads as known after one look | new: B1 has a second direction |

UI run `skat@20261106-153050-7064-claude-mbpro0c01-1106-155625-29512`, `SkatTrainerUITests/StateMachineAuditRepro`: 2 tests, 1 passed, 1 failed. The only failure is `claim: after taking the answer back, Dein Fortschritt has no answers`. Every precondition passed (progress empty after reset, undo button appeared, undo consumed the swipe). The control passed. Matches the audit.

## Claims

| Id | Verdict | User route (devices) | Impact | Evidence |
|---|---|---|---|---|
| B1 deck undo keeps the recorded answer | CONFIRMED | Home > Karten & Reizen (free) > Die Karten kennenlernen > tap to flip > swipe > toolbar undo button. Any iPhone or iPad. The audit's route is correct: the button exists whenever `lastSwipe` is set | Any deck user who uses undo, in four free decks (one per free room) plus one Skat+ deck. Undoing a left swipe and re-swiping right leaves a permanent extra wrong attempt in accuracy and keeps the card in "Fehler wiederholen" until it is answered right once more. Undoing a right swipe and re-swiping right marks the card known after one look (inflates the mastery ring and the weekly gain). The audit's "none of it is recoverable except Settings reset" is wrong: the missed set heals on the next right answer and the review flag on the one after. Only the accuracy count is permanent | Records at FlashcardDrillView.swift:365-366 (plain cards) and :253-254 (choice cards); `undo()` at :380-392 restores only queue, flip, `lastSwipe`, `choicePick`; label "Letzte Antwort zurücknehmen" at :88. Drills/AGENTS.md promises only the card returning, so the label is the only promise and it does say "take back the answer". UI claim failed, control passed; store checks above |
| B2 reminders never reconcile with iOS | UNVERIFIED | The audit's route (notifications off in iOS Settings, then on again, with no edit in between) most likely does not lose the reminder: nothing in the app removes the pending request, and iOS is not known to drop pending requests when permission is toggled. Not verified. A sharper route the audit missed: notifications off in iOS > in the app change the reminder time, toggle it, or (Skat+) change the game night weekday > notifications on again. Each of those calls `removePendingNotificationRequests` and then `add` (AppSettings.swift:177-187, :212-227), and `add` fails without authorization, so nothing is pending while the toggle still reads on. Restore to a new device is the audit's other route, and also not verified | Toggle-on users who revoke notifications and then edit a reminder, or who restore to a new phone. Probably very few. Cost: a silently dead reminder until they flip the toggle off and on | Certain from the code: nothing reads authorization or pending requests (grep for `getNotificationSettings`, `getPendingNotificationRequests`, `authorizationStatus` over Shared and SkatTrainer: zero hits), and `init` at AppSettings.swift:132-149 neither schedules nor asks. The doc comment at :89-91 covers only the moment of asking ("the toggle just silently flips back"). It promises no ongoing reconciliation, so the audit leans on it too hard. The runner shows `add` failing under `notDetermined` (UNErrorDomain 2003). It does not show the same under `denied`, which is what the new route needs. Would settle it: a device run (revoke, edit, re-grant, read pending), or a protocol around the center with a fake that refuses `add` |
| B3 reminder time shifts after a zone change in a live process | CONFIRMED-MINOR | Daily: Settings > Üben > Tägliche Erinnerung on > change zone without the app being killed > picker shows the shifted time; toggling the reminder off and on reschedules at the shifted time. Game night (Skat+ only, Settings > Üben > Skatabend-Vorbereitung, SettingsView.swift:105): changing the weekday or toggling reschedules at the shifted time. Editing the time itself is correct, because it stores the new pick. Any device, but iPhone travel with automatic time zone is the realistic case | Travellers who keep the app resident across a zone change and then touch the reminder. Rare. The cost is lasting, which the audit understates: the stored hour stays 17 (AppSettings.swift:123-125 only runs on a time edit), so after the next cold launch the picker reads 17:00 again while the pending trigger stays at 11:10, and nothing repairs it | The `Date` is built from hour and minute only (AppSettings.swift:140, :146-148), which is 1 Jan of year 1 (review check `year=1`), so zones use local mean time and the shift is 5h50, not 6h: Berlin 17:00 reads **11:10** in New York, not the audit's 11:00. Re-read at :184 and :220. The picker binds the same `Date` (GameNightPrepView.swift:92-96, SettingsView.swift:103). Repro claim failed with its preconditions passing. The test fakes the zone change with `NSTimeZone.default`. That a real system zone change reaches `Calendar.current` in a suspended process is assumed from Foundation's behaviour, not run |
| B4 weekly gain counts Skat+ items again on re-subscribe | CONFIRMED-MINOR | Member lapses > opens Home as free (`recordMastery`, HomeView.swift:202-207, writes the free-scope count) > re-subscribes within 7 days > `onChange(isPro)` at :117 writes the member-scope count > Home chip and Dein Fortschritt card show the difference as a gain. Any device | Winback members who open the app while lapsed and return within a week, with Skat+ items still inside their known window. Small. Cosmetic: a flattering "+N" for one week | `weeklyGain` subtracts totals across days with no regard for scope (MasteryLedger.swift:46-51). The free scope excludes Skat+ by design (Mastery.swift:73-77, which is documented and correct). The repro's preconditions hold (5 known as member, 0 as free) and the claim failed with 5. The audit calls this "the exact fake-gain failure" the rule file guards against. The rule (`.claude/rules/feedback-and-retention.md`, Weekly gain) guards a different cause, the unresolved-membership race, and that guard works. Same symptom, not the same documented case |
| B5 streak grows for two sessions on one calendar date across zones | CONFIRMED-MINOR | Practise in Tokyo, fly east across the date line, practise again on the same local date in the Americas. Any device | Close to nobody. The cost is a streak one day high, never one lower. The player did practise on two separate local days of their life, so the result is defensible. Literally it breaks the internal doc comment, not anything a player is told. Recommend leaving it, or folding it into any later day-key change | `lastActiveDay` is a start-of-day `Date` from the zone at write time, re-bucketed in the zone at read time (ProgressStore.swift:85-107). The doc comment at :84 says "consecutive calendar days". The repro claim failed (2 vs 1) with preconditions passing. The test asserts exactly what the claim says |

## What survived, ranked by impact

1. **B1** (CONFIRMED). The only claim on a common route: any deck, any free player, one tap. The cost per hit is small (one stale answer, or one card marked known too early), but it happens every time undo is used. P8 (a choice card is graded twice after undo, FlashcardDrillView.swift:249-254 and :384) has the same cause and should be fixed with it. The audit ranks B1 first, and that is right.
2. **B3** (CONFIRMED-MINOR). Rare, but it is the only surviving claim with a functional cost: a reminder that fires at the wrong time and stays wrong across launches. The audit ranks it third, below the unverified B2.
3. **B4** (CONFIRMED-MINOR). Small winback population, cosmetic cost for one week.
4. **B5** (CONFIRMED-MINOR). Near-zero population and a flattering error. Not worth a fix by itself.

B2 is unranked (UNVERIFIED). The audit placed it second on a route that probably does no harm. Run the device check before spending a fix on it. If the new route holds, it ranks between B1 and B3.

## Product calls

- P1 (timed clock counts sleeps, PracticeRunView.swift:241-246): code read as described. Not run. Agree it is a product call.
- P2 (static repeating daily reminder): it is documented as intended (AppSettings.swift:153-156, `ReminderCopyTests`). Not a bug, and arguably not even a call to make.
- P3 (onboarding stage is view state): not re-verified.
- P4 (Skat Minute week counts `completedAt`, SkatMinuteStore.swift:87-90): confirmed as described. Product call.
- P5 (paywall set while Settings is up, HomeView.swift:86-87, :257-261): reachable only by a non-member tapping a Skat+ notification with Settings open. If SwiftUI drops the second sheet, `showPaywall` stays true and the Home upgrade card's `showPaywall = true` stops opening anything until something resets it. That could be worse than the audit's "one at a time". Not run. Worth one UI test.
- P6 (lapse turns the game night toggle off): agree. See the gap below for when it does not fire.
- P7 (stale churn moment wording): code matches (SubscriptionService.swift:459-466). Product call.
- P8: CONFIRMED with B1 (same cause, same fix).

## Possible gap the audit missed (UNVERIFIED)

The lapse auto-off for the game night reminder (HomeView.swift:118-128) only runs on a change of `isPro` while Home is mounted. A member whose subscription ended while the app was not running starts at `isPro == false` (SubscriptionService.swift:68). If RevenueCat's cached record already reads as expired at `start()`, which is called before Home mounts, there is never a true-to-false change, so the weekly notification keeps firing for a lapsed player and opens the paywall. Whether the cached record reads as active (then the later network refresh produces the change and the toggle turns off) depends on how RevenueCat evaluates `isActive` for a stale cache. Would settle it: a device run with a sandbox subscription that expires while the app is killed.

## Method changes that would have prevented the errors

1. **Check premises with a direct probe before building a control on them.** The notification tests assume "scheduling does not need authorization" (repro docstring). A one-line `add` with a completion handler shows the error (UNErrorDomain 2003, status `notDetermined`). That would have explained the failed controls instead of leaving them as "runner shows nothing". It would also have surfaced B2's real route: revoked permission plus remove-then-add.
2. **Assert the exact value, not one component.** The B3 test checks the hour only, so the doc reports 11:00 when the picker shows 11:10. Asserting hour and minute together, and the `Date`'s year, would have exposed the year-1 local mean time effect.
3. **Run the recovery path before calling a cost permanent.** B1's "not recoverable except Settings reset" falls to a two-call store test. Every impact claim should run the next normal user action after the bad state.
4. **Test both directions of a symmetric bug.** B1's undo of a right swipe (a card known after one look) is the more misleading half for mastery and the weekly gain, and the audit did not test it.
5. **Separate "the code never does X" from "the user loses Y".** B2's evidence proves the first. Its route also needs iOS behaviour (dropping pending requests when permission is cycled) that the audit itself lists as unverified, so B2 should have been filed UNVERIFIED rather than ranked second.
6. **Quote what a rule actually guards.** B4 cites the rule file for a case the rule does not cover. Paraphrased citations made B4 and B2 look stronger than the docs make them.
7. **Rank only what was proved, and weight functional cost above display cost.** An unverified B2 ranked above a proved B3, and a cosmetic B4 sat next to a functional B3 on population alone.
