---
paths:
  - "Shared/Services/FeedbackService.swift"
  - "Shared/Services/MembershipTransitions.swift"
  - "Shared/Services/MasteryLedger.swift"
  - "Shared/Services/ReviewPromptTracker.swift"
  - "SkatTrainer/Views/ReviewPromptSheet.swift"
  - "SkatTrainer/Views/Components/ReviewRequest.swift"
  - "SkatTrainer/Views/StatsView.swift"
  - "SkatTrainerTests/FeedbackServiceTests.swift"
  - "SkatTrainerTests/MasteryLedgerTests.swift"
  - "SkatTrainerTests/MembershipTransitionsTests.swift"
---

# Skat Trainer: feedback, the churn question, and the weekly gain

Ported from Bridge Trainer (2026-10-20), which took it from Mahj 1.4 to 1.4.2.
Mahj's `.claude/rules/feedback-and-retention.md` has the reasoning; this file is
what differs here. All player-facing copy is German.

## Ratings (App Review 5.6.1)

No question stands in front of Apple's prompt, ever. A finished drill or Skat
Minute scoring half or better bumps a counter; `requestsReview(after:)` waits
3s, re-checks the screen (view on screen, no alert or share sheet up) and calls
`requestReview()`. Gates live only in `ReviewPromptTracker.shouldRequestReview`:
second cold launch, 30-day cooldown, and opening the write-review page ends the
asks. Also required: onboarded, and RevenueCat `rating_prompt` not `off`.
Settings has two separate rows: "Skat Trainer bewerten" (write-review page,
ends the asks) and "Feedback senden" (never stops them). The old
pending-positive-moment tracker and the mail draft `FeedbackSheet` are gone. No
per-question report link (Jack's call in Mahj: a flag under every answer casts
doubt on the right one).

## The feedback sink

`FeedbackService` posts to the shared Supabase `app_feedback` table (project
`ucoveqbyfuxqvpysmixu`) with `appID = "skat"`. The publishable key can only
INSERT rows where `app` is one of the card trainers (migration
`20261019120000_card_apps_feedback.sql` in the Mahj repo) and `kind` is
`general`, `not_enjoying`, `question` (retired) or `churn`. 2xx is sent;
network error, 408, 429 and 5xx queue the row (cap 20, retried on launch and
every return to the app); any other 4xx is dropped. Nothing personal is sent.
The churn chips are sent as written, so they arrive in German. The public
privacy page (`docs/privacy-policy*.html`, "Feedback") describes the fields
(updated 2026-10-20); keep it in step.

## One sheet, two jobs

`ReviewPromptSheet` has `.feedback` and `.churn(ChurnMoment)`. Neither touches
`ReviewPromptTracker`. `SubscriptionService.observe` compares each RevenueCat
record with the last one (`MembershipTransitions.churnMoment`) and stores at
most one `ChurnMoment` per departure. Every product carries both the `Skat+`
and `pro` entitlements, so the snapshot reads `activeEntitlement(in:)` (`Skat+`
first, then `pro`, then any active one) rather than a single key. A first
record only becomes the baseline if RevenueCat answered within 5 minutes
(`freshBaselineAge`): launch applies the cached record first, which can be
months old. Home shows the question once 0.9s after it is bare
(`HomeView.homeIsBare`) and spends it only when shown.

## Weekly gain

`MasteryLedger` stores known-question counts per room once a day. It builds on
the existing `Mastery.swift` (`RoomMastery`; an item is known after two right
answers in a row and until a full interval past due); there is no second
mastery model. `weeklyGain()` drives the plum "+N" chip on Home and the "Diese
Woche N Fragen mehr gefestigt" card on Dein Fortschritt. Home records only once
`membershipResolved` is true, or a member's first entry of the day would drop
every Skat+ item and fake a gain the next day. Nothing is baked into the
repeating reminders (`AppSettings.dailyReminderBody` is static and number-free;
`ReminderCopyTests` guards it).

## Not ported, on purpose

Trial-end reminder screen (Mahj removed it from the frozen trial flow), the
per-question report link, and the daily and monthly challenge (only its remote
switch exists).
