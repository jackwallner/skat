# Pre-submit review, Skat Trainer 1.3.2 (build 45), 2026-11-07

## Scope

- Live version: 1.3.1, build 44 (App Store Connect: "ready for distribution"; build 44 uploaded 2026-10-30, commit `bf00f1b`, "chore: bump build 43 to 44").
- Reviewed: `bf00f1b..origin/main` (`d9dbe08`), app sources only (`Shared`, `SkatTrainer`, `project.yml`). Docs, fastlane, tests, qa and android excluded.
- App files changed: `AppSettings.swift`, `MasteryLedger.swift`, `PracticeRecordStore.swift`, `ProgressStore.swift`, `FlashcardDrillView.swift`, `HomeView.swift`, and `project.yml` (version 1.3.2, build 45 only). No change to `SubscriptionService`, `PaywallView`, onboarding, StoreKit configuration, RemoteConfig, Info.plist, assets or any user-visible string.
- The changes are the 2026-11-06 state machine fixes (B1/P8 deck undo, B3 reminder time across zones, B4 weekly gain on re-subscribe, B5 streak across zones), already verified PASS in `state-machines-2026-11-06-verify.md`. This review re-read each hunk against the four checks below.

## Checks

1. Crashes and data loss. No new force unwrap on data (the only `!` is `TimeZone(identifier: "UTC")!`, which cannot fail). `progress.lastActiveDay` changes from `Date` to `String`; the old `Date` still reads, and a downgrade read (`as? Date`) returns nil instead of trapping. `PracticeRecord` and the ledger keep their formats. `AnswerSnapshot` and the `ReminderCenter` seam are main-actor isolated, matching the stores. The permission continuation is resumed exactly once.
2. Purchase and paywall paths. Untouched since the live version. Paywall still shows StoreKit prices and Terms and Privacy links. The ledger write no longer reads `isPro`, so no gating changed.
3. State bugs. Reminder hour and minute keys and defaults are unchanged, so saved times survive the update; every edit still reschedules with the same identifiers, so nothing is scheduled twice. Undo restores both stores newest first and is only reachable while the deck is on screen (not after `DrillCompleteView` has recorded the session). No widgets or app intents in this project.
4. App Review risks. No string, link, price or health copy changed. The local Pro override stays behind `#if DEBUG`.

## Findings

| Severity | File:line | What happens | Status |
|---|---|---|---|
| P2 | `Shared/Services/MasteryLedger.swift:48` | Ledger days written by 1.3.1 while a member was lapsed left out Skat+ items. After the update the first write counts them, so a lapsed-then-returned member can see one inflated "+N" weekly gain chip for under a week. | Not fixed: the stored days do not record which scope wrote them, so removing it means dropping every player's history and hiding the chip for a week. Accepted in the 2026-11-06 verify. |
| P2 | `Shared/Services/AppSettings.swift:203` | Turning a reminder on, then off again before the permission request returns, lets the late callback schedule the reminder while the toggle reads off. Same race as in 1.3.1; needs two taps inside one async hop, so a real user is unlikely to hit it. | Not fixed: not new, not reproducible by hand. |
| P2 | `Shared/Services/AppSettings.swift:202` (B2, held) | Reminders are never reconciled with iOS at launch, so a phone restored from backup with reminders on, or with notifications turned off in iOS Settings, shows the toggle on and gets no notification. Present in 1.3.1. | Not fixed: unverified, held for a device run by the 2026-11-06 fixes doc. |
| P2 | `SkatTrainer/Views/HomeView.swift:118` (G1, held) | A Skat+ lapse that happens while the app is closed keeps the game night reminder on until the app sees `isPro` change. Present in 1.3.1. | Not fixed: unverified, held for a sandbox run by the 2026-11-06 fixes doc. |

No P0 or P1 finding. Nothing in the diff was definitely broken, so no code was changed.

## Tests

`gh-sim test --scheme SkatTrainer` on `origin/main` (`d9dbe08`), Xcode 27.1, iPhone 17, iOS 27.2: GitHub run 42455047538 (`skat@20261107-222805-f6c3-claude-mbpro3aac8-1107-223039-19570`), **182 passed, 0 failed, 0 skipped**.
