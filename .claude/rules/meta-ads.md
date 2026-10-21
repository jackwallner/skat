---
paths:
  - "Shared/Services/RemoteConfig.swift"
  - "SkatTrainer/Views/HomeView.swift"
  - "project.yml"
---

# Skat Trainer: no Meta SDK, and the remote switches

- No Meta SDK, no tracking prompt, no `NSUserTrackingUsageDescription`
  (Jack 2026-10-21: Meta only in Mahj for now). The inert SDK and its ATT
  code were removed, so App Review never sees a tracking key the app does not
  use, and the privacy labels say no tracking. Adding Meta later means porting
  Mahj's `MetaAds`, its ATT timing and Info.plist keys, a Meta app, the relay
  webhook (Mahj's `project-docs/marketing/meta-ads.md`) and tracking labels,
  all in one submission, and only with Jack's go-ahead.
- `RemoteConfig` reads the current RevenueCat offering's metadata: `trial_cta`
  (`seven_day` control: "7 Tage kostenlos starten" on onboarding and
  "7-Tage-Test starten" on the paywall; `my`: "Meine Probewoche starten";
  `your`: "Deine Probewoche starten") and the switches `rating_prompt`
  and `challenge` (on unless exactly `off`; set the same on every
  offering). The `challenge` switch is declared but nothing reads it: Skat has
  no challenge yet, and one must gate its Home card and deep link on it. DEBUG
  builds pin any key with `-skat.rc.<key> <value>`.
