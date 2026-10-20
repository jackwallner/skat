---
paths:
  - "Shared/Content/SkatRules.swift"
  - "Shared/Content/PracticeGenerators.swift"
  - "Shared/Content/EndlessPractice.swift"
  - "Shared/Content/HandGenerator.swift"
  - "Shared/Services/Mastery.swift"
  - "SkatTrainerTests/GeneratedPracticeTests.swift"
---

# Skat Trainer: generated practice, miss notes, mastery

- Five Endless skills (`PracticeSkill`): hand reading, Bedienpflicht, Augen zählen, Wer sticht?, Spitzen zählen. Answers for the last three come from `SkatRules` (DSV order: Buben Kreuz, Pik, Herz, Karo; then A, 10, K, D, 9, 8, 7; Null: A, K, D, B, 10, 9, 8, 7). Tests compare against an independent ranked-list oracle, so change both sides together.
- Spitzen questions are Grand only ("nur die Buben zählen"). In a Farbspiel the run continues into the trump suit, which would make answers arguable.
- Wer sticht? never asks what is legal, so Bedienpflicht cannot change the answer.
- `HandGenerator` unseeded deals vary (`variedDeal`); seeded deals (Skat Minute) keep the legacy hands so all devices deal the same daily hands. Do not change seeded output without a version-gated plan.
- `QuickItem.choiceNotes` is parallel to `choices` and must ride the same permutation in `SessionBuilder.prepared`. `QuestionPager.missNote` shows the note only after a wrong pick.
- Mastery: a question is known after two right answers in a row and lapses one full interval past due. Free players are measured only against free sets. Generated skills never count.
- What's New: every `MARKETING_VERSION` with player-visible changes needs an entry in `WhatsNew.releases`. `currentRelease` is the newest entry at or below the running version, so a build without its own entry carries the last notes once to a player who skipped a version (see `membership-and-trial.md`).
