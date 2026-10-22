# Skat rules audit, 2026-10-22

Baseline: `75a2a366`. Scope: all 222 catalog exercises, generators, scoring and tactic checks in the committed iOS and Android trainers. The original working tree is preserved. The apps teach drills, not a complete multiplayer adjudication service.

Final integration base: `68aabfc` (current origin/main). Some corrections listed below were already present there and were retained. The table records findings in the original local checkout as well as the remaining fixes. Final verification covers the newer generated engines too.

## Authority and rule table

[DSkV Internationale Skatordnung, November 2022](https://dskv.de/app/uploads/sites/43/2022/11/ISkO-2022.pdf), especially 2.2-2.6, 3.3, 3.6, 4.2 and 4.3.

| Rule | Expected behavior | Native table test on both platforms |
| --- | --- | --- |
| Deck/eyes | 32 cards, 7-A; A/T/K/Q/J=11/10/4/3/2, others zero; total 120. | `cardValuesAndTrumpCounts` |
| Suit/Grand | Suit: four jacks in C,S,H,D order, then A,T,K,Q,9,8,7 of trump. Grand: only jacks trump. | Card/trump and trick tables |
| Null | No trumps; A,K,Q,J,T,9,8,7. Any own trick loses, even zero eyes. | Trick and Null score tables, existing Null tactics |
| Legal play | Follow the actual suit group, including trump; jacks leave their printed suits except in Null. When void, no obligation to trump or overtrump. | `followingAndTrickAnswersUseDisplayedCards` |
| Matadors | Consecutive trumps from CJ, present or absent; count hand plus skat even in Hand. Continue beyond jacks in a suit game, up to eleven; Grand up to four. | `matadorsIncludeSkatAndContinueBeyondJacks` |
| Basic values | D/H/S/C/Grand bases 9/10/11/12/24. Multiply matadors plus game and applicable stages. | `iskoScoringThresholdsAnnouncementsAndOverbids` |
| Outcomes | Declarer needs 61 including skat. Schneider: either side has at most 30; Schwarz: no trick, not merely no eyes. | 28 outcome rows, including 30/31, 89/90 and 120 with an opposing zero-eye trick |
| Announcements | Hand adds one. Announced Schneider/Schwarz require Hand and are binding; failure loses at least the announced stages. Suit/Grand ouvert requires Hand and all tricks. Grand ouvert with four: 264. | Outcome and illegal-announcement rows |
| Loss/overbid | Loss doubles the game value. An overbid rounds at least up to the next multiple of the declared base covering the bid, then doubles. | Outcome rows, including 20/23 Karo and changed Hand matadors |
| Null values | Pickup 23, Hand 35, ouvert pickup 46, ouvert Hand 59. Normal loss doubles fixed value. Impossible overbid Null uses the suit/Grand procedure of 3.6.2, not an invented universal -46 penalty. | Four fixed-value win/loss pairs; actual `vertieft-null-13` explanation and existing expert tests |
| All pass | Eingepasst; next dealer deals. ISkO has no automatic Ramsch. | Primer assertions in scoring table test |

## Corrections

| Before | After | Regression |
| --- | --- | --- |
| `stich-entscheidung-2` and `plus-entscheidung-2` say no hearts but display HA. | Replace HA with DA and state Grand explicitly; both shown cards really are legal. | Actual flashcards checked against the legal-move table |
| Beginner rules imply declarer always picks up the skat. | Explicit choice between pickup/discard and untouched skat for Hand. | Existing Hand-copy checks and reviewed primer |
| Jack trump order described as applying to every normal game. | Explicitly restricted to suit and Grand; Null uses printed suits. | Null versus Grand trick tables |
| Two ace-pattern descriptions imply Grand is unavailable without jacks. | Grand without jacks is legal; these small patterns do not prove a safe full contract. | Matador table includes without four |
| All-pass outcome and no-trump trick winner missing from primer. | Next dealer after all pass; highest led suit wins without trump in trick. | Primer and trick table tests |

The 24 authored expert score answers and existing three-trick minimax proofs were retained. New tests derive score stages from actual points, tricks and announcements, rather than trusting the authored multiplier. Both platforms retain independent exhaustive legal-defense checks for the eight fully specified planning positions, trump-first endgames and Null tactics. Discard exercises state their objective; they do not claim a universally winning discard against unknown hands.

Identical native `rules-reference.json` fixtures contain independently authored expected outcomes. Kotlin export parity is checked separately. `SkatRules.nullScore` deliberately returns no value for an impossible Null overbid; a caller must use the separate 3.6.2 suit/Grand assessment. There is no live contract-declaration UI in this trainer. The independent reference calculator is test-only, alongside the existing runtime `SkatRules` oracle. Current runtime trick results are checked against the same tables; the newer generated counting, trick and Grand-matador suites run as well.

## Verification

Run `xcodegen generate`, the `SkatTrainer` unit-test scheme, and `fm-gradle testDebugUnitTest` from `android/`. No local Gradle execution. See `verification.md` for final receipts.
