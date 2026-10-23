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
- iOS 27.1 moves a `NavigationStack`'s toolbar (gear, back button) into a
  vertical bar on the stack's trailing edge, which in the leading pane lands
  beside the fold with the title still leading. Supervisor review rejected
  that (2026-10-21), so both panes set `toolbarVerticalBehavior(.disabled)`
  while split (`horizontalToolbarInPane`): back button at the pane's leading
  edge, title centred, as on a phone and in Bridge. Folded keeps `.automatic`.
  With both panes horizontal the system drops its vertical status column and
  the status bar runs across the top of the trailing pane.
- Still system sheets, so centred across the fold: the paywall (the trial flow
  is locked to Mahj 1.3.2, moving it needs Jack's go-ahead), What's New, the
  churn and feedback sheets, and sheets raised from inside Settings. Onboarding
  is a full-width readable column.
- Captures: DEBUG only (`DuoScreenshotMode`). `-DuoSeed` fills the real stores
  once per install (`duo.seeded`) with a week of practice, a weekly-gain
  baseline, three Skat Minutes and the local Skat+ override (no RevenueCat, no
  network). `-DuoScreen <route>` opens one route about a second after launch
  and holds it (it wins over the tour). `-DuoTour -DuoRoutes a,b,c` walks Home
  through routes on a timer, for video. Routes: home, quick, room-<id>,
  drill-<id>, stats, endless, minute, prep, timed, howto, settings, paywall.
  Add `-skat.suppressWhatsNew`. The `stats` route pushes a second Dein
  Fortschritt on the left, so skip it for inner shots.
- One `gh-sim all --device 'iPhone Duo'` run captures every surface: base
  `--args "-DuoSeed -skat.suppressWhatsNew -DuoTour ..."` (the recorded first
  launch tours) plus one `--screen "-DuoScreen <route>"` per surface, each
  shot folded and unfolded, `--wait 10`. Never pass `--url` (a custom scheme
  raises "Open in ...?", fake `noop://` URLs make gh-sim exit 1). The
  recording's jump and flicker events at each relaunch are gh-sim terminating
  the app, not the app. A US-region runner once showed the Skatabend time as
  "5:00 PM"; the root view now pins `Locale.skat` (de_DE), so every time reads
  on the 24-hour clock (`DisplayLocaleTests`).
