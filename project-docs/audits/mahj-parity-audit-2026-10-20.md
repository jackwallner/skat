# Skat Trainer: Mahj-inspired feature audit (2026-10-20)

Reference: jackwallner/mahj (`Shared/Services/Mastery.swift`, `PracticeRecordStore.swift`, `EndlessPractice.swift`, rules `mastery-coaching-whats-new.md` and `generated-practice.md`). Mahj terminology and mechanics were not copied; each item was adapted to Skat rules.

Legend: PRESENT, MISSING (now implemented), UNSUITABLE, INCORRECT (fixed).

| Area | Status | Evidence / change |
|---|---|---|
| Endless original practice | PRESENT, thin | `Shared/Content/EndlessPractice.swift` had two skills. Hand reading dealt ONE fixed hand each for Null and Stich (`HandGenerator.deal`), so "ohne Wiederholungen" (RoomView upsell, EndlessPickerView intro) was false for half the categories. Trick play asked one Bedienpflicht rule only. |
| Endless: new generated skills | MISSING, now added | `PracticeGenerators.swift` + `SkatRules.swift`: Augen zählen, Wer sticht? (Farbspiel, Grand, Null), Spitzen zählen (Grand, mit/ohne). Answers come from `SkatRules` and are checked in tests against an independent ranked-list oracle. |
| Hand variety | INCORRECT, fixed | Unseeded deals now vary (`HandGenerator.variedDeal`). Seeded deals (Skat Minute) are untouched so every device still deals the same daily hands. |
| Fix My Mistakes / spaced review | PRESENT | `PracticeRecordStore.reviewQueue`, `PracticeRunView(.review)`. Generated items correctly stay out of the queue. |
| Timed challenge | PRESENT | 90 s, best score in `PracticeRecordStore`. Now mixes the five generated skills. |
| Room-level stats | PRESENT | `StatsView` accuracy per room, weakest room. |
| Mastery (known = right twice running) | MISSING, now added | `Shared/Services/Mastery.swift`; chip in `RoomView` header, Beherrschung card in `StatsView`. Free players are measured only against free sets. |
| Coaching the miss ("Warum nicht?") | MISSING, now added | `QuickItem.choiceNotes` (parallel to `choices`, permuted in `SessionBuilder.prepared`), `QuestionPager.missNote`. Every generated skill has a note per wrong choice, naming the real count or card. Authored items have none (their explanations already cover it). |
| Daily short practice | PRESENT | Skat Minute, Skatabend-Vorbereitung. |
| Reminders | PRESENT | Daily reminder and game night reminder (`AppSettings`). |
| Feedback / ratings | PRESENT, correct | No enjoyment gate (5.6.1); system dialog via `ReviewPromptTracker`. |
| What's New | INCORRECT, fixed | `project.yml` is 1.2.4 but `WhatsNew.releases` had no 1.2.4 entry, so the sheet never appeared for this version. Entry added. |
| Reference / practice-hand flow | PRESENT | HowToPlay primer, flashcards, Hand match. No change. |
| Progression | PRESENT | Rooms, free/Skat+ split, streaks. Mastery levels add visible progression. |
| Charleston, monthly challenge, hand-play engine, Supabase feedback | UNSUITABLE | Mahj specific or need a backend. Not ported. |

## Known limits and judgement calls

- Spitzen questions are Grand only and state "nur die Buben zählen". In a Farbspiel the Spitzen run continues into the trump suit, so mixing it in would make some answers arguable.
- Wer sticht? shows three cards played in order and never asks what is legal, so Bedienpflicht cannot change the answer.
- Skat+ boundary unchanged: the new skills live inside Endless/Zeitprüfung (Skat+). Mastery and Stats are free.
- Generated items are never reviewable; this keeps `practice.records` bounded.

## Persona walkthroughs

See `project-docs/audits/mahj-parity-ui-findings-2026-10-20.md` (written after the captured UI run).
