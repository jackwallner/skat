import XCTest
@testable import SkatTrainer

final class ContentValidityTests: XCTestCase {
    private var allDrills: [Drill] { DrillLibrary.rooms.flatMap(\.drills) }

    private var allHandMatch: [HandMatchQuestion] {
        allDrills.flatMap { drill in
            if case .handMatch(let questions) = drill.kind { return questions }
            return []
        }
    }

    private var allQuiz: [QuizQuestion] {
        allDrills.flatMap { drill in
            if case .quiz(let questions) = drill.kind { return questions }
            return []
        }
    }

    private var allDiscard: [DiscardScenario] {
        allDrills.flatMap { drill in
            if case .discard(let scenarios) = drill.kind { return scenarios }
            return []
        }
    }

    private var allFlashcards: [Flashcard] {
        allDrills.flatMap { drill in
            if case .flashcards(let cards) = drill.kind { return cards }
            return []
        }
    }

    func testHandMatchQuestionsShowFiveCards() {
        for question in allHandMatch {
            XCTAssertEqual(question.tiles.count, 5, "\(question.id) must show a five-card hand")
            XCTAssertEqual(Set(question.tiles).count, question.tiles.count, "\(question.id) repeats a physical card")
        }
    }

    func testHandMatchAnswerIsAmongChoices() {
        for question in allHandMatch {
            XCTAssertTrue(question.choices.contains(question.answer), "\(question.id) answer missing from choices")
            XCTAssertEqual(Set(question.choices).count, question.choices.count, "\(question.id) has duplicate choices")
        }
    }

    func testDiscardDealsHaveTwelveCardsAndRecommendTwo() {
        for scenario in allDiscard {
            XCTAssertEqual(scenario.deal.count, 12, "\(scenario.id) deal must have twelve cards after picking up the Skat")
            XCTAssertEqual(scenario.recommendedDiscard.count, 2, "\(scenario.id) must recommend exactly two cards")
            XCTAssertEqual(Set(scenario.deal).count, scenario.deal.count, "\(scenario.id) repeats a physical card")
            XCTAssertTrue(scenario.recommendedDiscard.allSatisfy(scenario.deal.contains), "\(scenario.id) recommends a card outside the deal")
        }
    }

    func testDiscardDealsUseAStandardDeck() {
        for scenario in allDiscard {
            for card in scenario.deal {
                if case .standard(let rank, _) = card {
                    XCTAssertTrue((7...14).contains(rank), "\(scenario.id) has an invalid Skat rank")
                } else {
                    XCTFail("\(scenario.id) contains a joker; skat uses a standard deck")
                }
            }
        }
    }

    func testQuizAnswerIndicesAreValid() {
        for question in allQuiz {
            XCTAssertTrue(question.choices.indices.contains(question.answerIndex), "\(question.id) has out-of-range answer")
            XCTAssertGreaterThanOrEqual(question.choices.count, 2, "\(question.id) needs at least 2 choices")
            XCTAssertEqual(Set(question.choices).count, question.choices.count, "\(question.id) has duplicate choices")
        }
    }

    func testCardChoicesAreTwoOptionsWithValidAnswer() {
        for card in allFlashcards {
            guard let choice = card.choice else { continue }
            XCTAssertEqual(choice.options.count, 2, "\(card.id) choice must have exactly 2 options")
            XCTAssertTrue(choice.options.indices.contains(choice.answerIndex), "\(card.id) has out-of-range choice answer")
            XCTAssertEqual(Set(choice.options).count, 2, "\(card.id) has duplicate choice options")
        }
    }

    func testAllContentIDsAreUnique() {
        var ids: [String] = []
        for room in DrillLibrary.rooms {
            ids.append(room.id)
            for drill in room.drills {
                ids.append(drill.id)
                switch drill.kind {
                case .flashcards(let cards): ids += cards.map(\.id)
                case .quiz(let questions): ids += questions.map(\.id)
                case .handMatch(let questions): ids += questions.map(\.id)
                case .discard(let scenarios): ids += scenarios.map(\.id)
                }
            }
        }
        XCTAssertEqual(Set(ids).count, ids.count, "Duplicate content IDs found")
    }

    func testEveryRoomHasDrillsAndFreeBeginnerModelIsIntact() {
        XCTAssertFalse(DrillLibrary.rooms.isEmpty)
        for room in DrillLibrary.rooms {
            XCTAssertFalse(room.drills.isEmpty, "\(room.id) has no drills")
            for drill in room.drills {
                XCTAssertGreaterThan(drill.kind.itemCount, 0, "\(drill.id) is empty")
            }
        }
        XCTAssertTrue(DrillLibrary.rooms.first?.isFree == true)
        for room in DrillLibrary.rooms {
            if room.id == "pro-tables" {
                XCTAssertFalse(room.isFree)
            } else {
                XCTAssertTrue(room.isFree)
                XCTAssertEqual(room.drills.filter(\.isPlus).count, 1, "\(room.id) should have one Skat+ extra set")
            }
        }
    }

    func testLockedDrillsResolveByMembership() {
        for room in DrillLibrary.rooms {
            for drill in room.drills {
                XCTAssertFalse(room.isLocked(drill, isMember: true))
                XCTAssertEqual(room.isLocked(drill, isMember: false), !room.isFree || drill.isPlus)
            }
        }
    }

    func testNoEmDashesOrStaleCardCopyInPlayerFacingContent() {
        var copy: [String] = []
        for room in DrillLibrary.rooms {
            copy += [room.name, room.tagline]
            for drill in room.drills {
                copy += [drill.title, drill.subtitle]
                switch drill.kind {
                case .flashcards(let cards):
                    copy += cards.flatMap { [$0.frontTitle, $0.frontSubtitle ?? "", $0.backTitle, $0.backBody] + ($0.choice?.options ?? []) }
                case .quiz(let questions):
                    copy += questions.flatMap { [$0.prompt, $0.explanation] + $0.choices }
                case .handMatch(let questions):
                    copy += questions.map(\.explanation)
                case .discard(let scenarios):
                    copy += scenarios.flatMap { [$0.situation, $0.reasoning, $0.tip] }
                }
            }
        }
        copy += HowToPlayContent.pages.flatMap { [$0.title, $0.body, $0.tip ?? ""] }
        let staleSourceName = ["crib", "bage"].joined()
        for text in copy {
            XCTAssertFalse(text.contains("\u{2014}"), "Em dash found in copy: \(text)")
            XCTAssertFalse(text.localizedCaseInsensitiveContains(staleSourceName), "Stale source-game copy found: \(text)")
            XCTAssertFalse(text.localizedCaseInsensitiveContains("pegging"), "Stale pegging copy found: \(text)")
        }
    }

    /// Every player-visible string, so a rules assertion can be checked once
    /// against the whole app rather than per drill type.
    private var allPlayerFacingCopy: [String] {
        var copy: [String] = []
        for room in DrillLibrary.rooms {
            copy += [room.name, room.tagline]
            for drill in room.drills {
                copy += [drill.title, drill.subtitle]
                switch drill.kind {
                case .flashcards(let cards):
                    copy += cards.flatMap { [$0.frontTitle, $0.frontSubtitle ?? "", $0.backTitle, $0.backBody] }
                case .quiz(let questions):
                    copy += questions.flatMap { [$0.prompt, $0.explanation] + $0.choices }
                case .handMatch(let questions):
                    copy += questions.map(\.explanation)
                case .discard(let scenarios):
                    copy += scenarios.flatMap { [$0.situation, $0.reasoning, $0.tip] }
                }
            }
        }
        copy += HowToPlayContent.pages.flatMap { [$0.title, $0.body, $0.tip ?? ""] }
        copy += HandCategory.allCases.map(\.howToSpot)
        return copy
    }

    /// In Skat "die normale Reihenfolge" means Ass, Zehn, König, Dame, Neun,
    /// Acht, Sieben. That order is right for a Farbspiel and for the side
    /// suits of a Grand, but it is WRONG for Null, where the Zehn drops below
    /// the Bube (Ass, König, Dame, Bube, Zehn, Neun, Acht, Sieben). Teaching
    /// the normal order in a Null sentence is a rules error, so no single
    /// string may ever contain both ideas.
    func testNullCopyNeverClaimsTheNormalCardOrder() {
        for text in allPlayerFacingCopy where text.localizedCaseInsensitiveContains("null") {
            XCTAssertFalse(
                text.localizedCaseInsensitiveContains("normale Reihenfolge")
                    || text.localizedCaseInsensitiveContains("normale Kartenreihenfolge"),
                "Null copy claims the normal card order, which is wrong for Null: \(text)"
            )
        }
    }

    /// In a Handspiel the declarer never picks the Skat up and never discards.
    /// The Skat's card points simply count for them at scoring.
    func testHandGameCopyNeverClaimsADiscard() {
        for text in allPlayerFacingCopy where text.localizedCaseInsensitiveContains("handspiel") {
            XCTAssertFalse(
                text.localizedCaseInsensitiveContains("drückt zwei"),
                "Handspiel copy claims a discard; a Hand game has none: \(text)"
            )
        }
    }

    /// The generated trick drill decides Bedienpflicht by comparing printed
    /// suits. A Bube is trump in a Farbspiel and in a Grand, so it does not
    /// belong to the suit printed on it and would make the generated question
    /// false. The generator must therefore never deal one.
    func testGeneratedTrickItemsNeverDealAJack() {
        let items = EndlessPractice.items(for: .trickPlay, count: 400)
        XCTAssertEqual(items.count, 400)
        for item in items {
            XCTAssertFalse(
                item.tiles.contains(where: \.isJack),
                "Generated trick item deals a Bube, which is trump and not a member of its printed suit: \(item.prompt)"
            )
        }
    }

    /// The values a trainer must actually state, each pinned to the drill that
    /// teaches it, so a future content edit cannot quietly drop them.
    func testCoreSkatValuesAreTaughtSomewhere() {
        let corpus = allPlayerFacingCopy.joined(separator: "\n")
        for fact in ["Karo 9", "Herz 10", "Pik 11", "Kreuz 12", "24", "23", "18", "61"] {
            XCTAssertTrue(corpus.contains(fact), "No drill teaches the value \(fact)")
        }
        XCTAssertTrue(
            corpus.localizedCaseInsensitiveContains("Spitzen"),
            "Spielwert is referenced but Spitzen are never explained"
        )
    }

    func testHowToPlayPagesHaveUniqueIDsAndValidCards() {
        let pages = HowToPlayContent.pages
        XCTAssertFalse(pages.isEmpty)
        XCTAssertEqual(Set(pages.map(\.id)).count, pages.count)
        for page in pages {
            XCTAssertEqual(Set(page.tiles).count, page.tiles.count, "\(page.id) repeats a physical card")
        }
    }

    func testQuickSessionPullsTenItemsAndPrioritizesMisses() {
        let mix = SessionBuilder.quickSession(seen: [], missed: [], includePro: false)
        XCTAssertEqual(mix.count, 10)
        XCTAssertEqual(Set(mix.map(\.id)).count, 10)
        let missedID = mix[0].id
        let biased = SessionBuilder.quickSession(seen: [missedID], missed: [missedID], includePro: false)
        XCTAssertTrue(biased.contains { $0.id == missedID })
    }

    private var lockedItemIDs: Set<String> {
        var ids: Set<String> = []
        for room in DrillLibrary.rooms {
            for drill in room.drills where room.isLocked(drill, isMember: false) {
                switch drill.kind {
                case .flashcards(let cards): ids.formUnion(cards.map(\.id))
                case .quiz(let questions): ids.formUnion(questions.map(\.id))
                case .handMatch(let questions): ids.formUnion(questions.map(\.id))
                case .discard(let scenarios): ids.formUnion(scenarios.map(\.id))
                }
            }
        }
        return ids
    }

    func testQuickSessionExcludesLockedContentForFreeUsers() {
        let mix = SessionBuilder.quickSession(count: 200, seen: [], missed: [], includePro: false)
        XCTAssertFalse(lockedItemIDs.isEmpty)
        for item in mix {
            XCTAssertFalse(lockedItemIDs.contains(item.id), "\(item.id) leaked into a free session")
        }
    }

    func testQuickSessionIncludesLockedContentForMembers() {
        let mix = SessionBuilder.quickSession(count: 500, seen: [], missed: [], includePro: true)
        XCTAssertFalse(Set(mix.map(\.id)).isDisjoint(with: lockedItemIDs))
    }

    func testQuickSessionItemsAreChoiceOnlyWithValidAnswers() {
        let mix = SessionBuilder.quickSession(count: 50, seen: [], missed: [], includePro: true)
        for item in mix {
            XCTAssertGreaterThanOrEqual(item.choices.count, 2)
            XCTAssertTrue(item.choices.indices.contains(item.answerIndex))
        }
    }

    func testQuickSessionExcludesPlainFlashcardsAndDiscard() {
        let plainFlashcardIDs = Set(allFlashcards.filter { $0.choice == nil }.map(\.id))
        let discardIDs = Set(allDiscard.map(\.id))
        let mix = SessionBuilder.quickSession(count: 200, seen: [], missed: [], includePro: true)
        for item in mix {
            XCTAssertFalse(plainFlashcardIDs.contains(item.id))
            XCTAssertFalse(discardIDs.contains(item.id))
        }
    }
}
