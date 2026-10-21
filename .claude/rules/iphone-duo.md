---
paths:
  - "SkatTrainer/Views/HomeView.swift"
  - "SkatTrainer/Utilities/UnfoldedSplit.swift"
  - "SkatTrainer/Utilities/DuoScreenshotMode.swift"
  - "SkatTrainer/Views/StatsView.swift"
  - "SkatTrainer/Views/SettingsView.swift"
---

# Skat Trainer: iPhone Duo (2026-10-21)

Same shape as Bridge Trainer's split, which follows Total Calories (`vitals`).

- Unfolded (regular width, at least 720 pt), `HomeView` puts its own
  NavigationStack (Home, rooms, drills) on the leading side of the fold and
  Dein Fortschritt on the trailing side, so the record a drill is building sits
  beside it and updates as answers land. Fold edges come from
  `GeometryProxy.verticalFold()` (iOS 27.1 `reservedRegions(.division)`), else
  an even split (`UnfoldedSplit`, tested in `UnfoldedSplitTests`). Folded, every
  ordinary iPhone, and the unfolded Duo in portrait keep the single column. iPad
  splits by the same rule; no device checks.
- Both panes get `horizontalSizeClass = .compact`, so each lays out as on a
  phone. Inside HomeView, `horizontalSizeClass` is a computed property that
  already reflects the pane; the window's class is `windowSizeClass`.
- Folding only moves frames. The progress pane mounts on the first unfold and
  is then hidden, never removed, and the Home stack is never rebuilt, so a
  drill in progress survives the fold. Do not wrap either pane in an `if`.
- While split: the stats chips are inert (the breakdown is already open), and
  Settings opens in the trailing pane instead of a sheet (`settingsSheet`
  binding; opening the Duo with the sheet up moves it to the pane).
- On the iOS 27.1 simulator the system moves Home's toolbar (gear, back
  button) into a vertical bar on the leading pane's trailing edge, beside the
  fold, so that pane's cards are about 340 pt wide. That is automatic
  vertical-bar behavior and was left on: it keeps the pane's full height for a
  drill. `.toolbarVerticalBehavior(.disabled)` would trade height for width.
- Still system sheets, so centred across the fold: the paywall (the trial flow
  is locked to Mahj 1.3.2, moving it needs Jack's go-ahead), What's New, the
  churn and feedback sheets, and sheets raised from inside Settings. Onboarding
  is a full-width readable column.
- Captures: DEBUG only (`DuoScreenshotMode`). `-DuoSeed` fills the real stores
  once per install (`duo.seeded`) with a week of practice, a weekly-gain
  baseline, three Skat Minutes and the local Skat+ override (no RevenueCat, no
  network). `-DuoTour -DuoRoutes a,b,c` walks Home through routes on a timer,
  because the capture job cannot tap. Routes: home, quick, room-<id>,
  drill-<id>, stats, endless, minute, prep, timed, howto, settings, paywall.
  Add `-skat.suppressWhatsNew`. The `stats` route pushes a second Dein
  Fortschritt on the left, so skip it for inner shots.
