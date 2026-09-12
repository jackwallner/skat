---
paths:
  - "Shared/Content/SkatMinuteContent.swift"
  - "Shared/Services/SkatMinuteStore.swift"
  - "SkatTrainer/Views/SkatMinuteView.swift"
  - "SkatTrainer/Views/GameNightPrepView.swift"
  - "Shared/Content/SessionBuilder.swift"
  - "Shared/Content/HandGenerator.swift"
  - "Shared/Services/AppSettings.swift"
  - "SkatTrainerTests/SkatMinuteTests.swift"
  - "SkatTrainerTests/HandGeneratorTests.swift"
  - "SkatTrainer/Views/Drills/QuickSessionView.swift"
  - "SkatTrainer/Views/SettingsView.swift"
---

# Skat Trainer: game-night rhythm

Moved verbatim from CLAUDE.md. Loads when a matching file is read; update it here.

## Game-night rhythm (1.2)

Skat+ owns two recurring rituals. `SkatMinuteContent` deterministically builds the
same five questions for every member on a local calendar day: two generated
Blattlesen, one Drücken decision, and two Stichspiel questions. Results and a 30-day
archive stay on device in `SkatMinuteStore`; sharing uses the system share sheet and
needs no account or leaderboard.

The Drücken question is built straight from the authored scenarios, NOT through
`SessionBuilder.choiceItems`. The quick-session pool deliberately excludes
those drills, so drawing the daily from it silently produced a four-question
challenge with that skill missing entirely.

`HandGenerator` deals the daily hands from a caller-supplied generator all the
way down: `deal`, `fill`, and `randomHand` are all generic over
`RandomNumberGenerator`. One `.shuffled()` or `.randomElement()` left calling
the system source is enough to make the same day deal different hands on
different devices, and the stability test is what catches it.

`GameNightPrepView` stores a weekly game night in `AppSettings`, schedules a
local notification, and opens directly into `SessionBuilder.gameNightPrep`,
which prioritizes due mistakes, misses, the weakest room, and unseen member
content in that order. Both features are entirely Skat+ gated.
