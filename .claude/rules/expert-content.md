---
paths:
  - "Shared/Content/AdvancedContent.swift"
  - "Shared/Content/AppliedContent.swift"
  - "Shared/Content/DrillLibrary.swift"
  - "Shared/Content/DiscardContent.swift"
  - "Shared/Content/PlusContent.swift"
  - "Shared/Content/MoreContent.swift"
  - "SkatTrainerTests/AdvancedContentTests.swift"
  - "SkatTrainerTests/ContentValidityTests.swift"
---

# Contextual expert content

The 1.2.3 catalog has 222 registered items, including 100 at the Meistertisch.
AdvancedContent replaces the old recall-based expert sets. AppliedContent adds
24 free cases. Preserve existing free beginner sets and Room.isLocked gating.

Every discard exercise states a Lehrziel. A full 12-card deal without opponents'
cards does not prove an objectively optimal winning discard. Teach a verifiable
constraint, such as creating a void while retaining trumps, and distinguish that
constraint from a guaranteed win. Never grade another legal teaching-goal
solution as wrong without clarifying the objective.

AdvancedContentTests checks values and overbid rounding independently, enumerates
all legal defenses for the trump-first and three-trick endgames, and verifies Null rank order.
ValueCase.expected is authored independently of the arithmetic in the test.
Keep the quiz, actual rest cards, and test fixtures aligned when editing tactics.

PlanningCase contains all three rest hands, prior declarer points including skat,
and authored guaranteed points per opening. The test-only independent solver
proves each opening against optimal cooperation of both defenders. Exactly one
opening must force at least 61, with sufficient prior-card eyes available in the
32-card deck. Quiz explanations give sample optimal lines, not promises that
opponents have to choose that specific line.

Rules reference: DSkV Internationale Skatordnung, November 2022:
https://dskv.de/app/uploads/sites/43/2022/11/ISkO-2022.pdf
Exercise wording and hands are original, not copied from the rules document.
The relevant rules include 2.3 (spitzen), 2.4 (base/fixed values), 2.5 (winning
levels), 3.6 (overbidding), and 4.2/4.3 (following and trick winners).
An impossible Null declaration is evaluated as a lost suit or Grand game under
3.6.2, accounting for bid and matadors. Do not teach a blanket double-bid Null
penalty. The skat contributes points and matadors even in Hand games.

All randomness inside HandGenerator's seeded paths must use the supplied
generator. AdvancedContentTests sweeps every generated category with matching
seeds so the shared daily hands cannot silently diverge.
