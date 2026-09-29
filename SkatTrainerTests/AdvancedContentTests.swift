import XCTest
@testable import SkatTrainer

final class AdvancedContentTests: XCTestCase {
    func testCatalogExceedsMahjScaleAndKeepsAppliedPracticeFree() throws {
        let drills = DrillLibrary.rooms.flatMap(\.drills)
        let count = drills.reduce(0) { $0 + $1.kind.itemCount }
        XCTAssertGreaterThanOrEqual(count, 222)
        print("Skat editorial catalog: \(count) items")
        let master = try XCTUnwrap(DrillLibrary.room(id: "pro-tables"))
        XCTAssertEqual(master.drills.reduce(0) { $0 + $1.kind.itemCount }, 100)
        XCTAssertFalse(master.isFree)
        for drillID in ["applied-bidding", "applied-tricks"] {
            let room = try XCTUnwrap(DrillLibrary.rooms.first { $0.drills.contains { $0.id == drillID } })
            let drill = try XCTUnwrap(room.drills.first { $0.id == drillID })
            XCTAssertFalse(room.isLocked(drill, isMember: false))
            XCTAssertEqual(drill.kind.itemCount, 12)
        }
    }

    func testEveryExpertQuizHasAnExplicitSituationAndReasoning() throws {
        let master = try XCTUnwrap(DrillLibrary.room(id: "pro-tables"))
        for drill in master.drills {
            if case .quiz(let questions) = drill.kind {
                for question in questions {
                    XCTAssertGreaterThan(question.prompt.count, 65, question.id)
                    XCTAssertGreaterThan(question.explanation.count, 80, question.id)
                    XCTAssertEqual(question.choices.count, 3, question.id)
                    XCTAssertFalse(question.id.hasPrefix("meister-"), question.id)
                    XCTAssertFalse(question.id.hasPrefix("mehr-regel-"), question.id)
                }
            }
        }
    }

    func testValueCasesMatchIndependentOverbidAndLossCalculation() {
        XCTAssertEqual(AdvancedContent.valueCases.count, 24)
        for lesson in AdvancedContent.valueCases {
            let achievedValue = lesson.base * lesson.multiplier
            let minimumBidValue = ((lesson.bid + lesson.base - 1) / lesson.base) * lesson.base
            let expected = lesson.lost ? -2 * max(achievedValue, minimumBidValue) : achievedValue
            XCTAssertEqual(lesson.expected, expected, lesson.id)
            XCTAssertEqual(lesson.question.choices[lesson.question.answerIndex], String(expected), lesson.id)
            if !lesson.lost {
                XCTAssertGreaterThanOrEqual(achievedValue, lesson.bid, lesson.id)
            }
        }
    }

    func testAllShownCardsAreUniqueAndBelongToSkatDeck() {
        for room in DrillLibrary.rooms {
            for drill in room.drills {
                let hands: [[PlayingCard]]
                switch drill.kind {
                case .quiz(let questions): hands = questions.map(\.tiles)
                case .flashcards(let cards): hands = cards.map(\.frontTiles)
                case .handMatch(let questions): hands = questions.map(\.tiles)
                case .discard(let scenarios): hands = scenarios.map(\.deal)
                }
                for hand in hands {
                    XCTAssertEqual(Set(hand).count, hand.count, drill.id)
                    for card in hand {
                        guard case .standard(let rank, _) = card else {
                            XCTFail("\(drill.id) contains a nonstandard card")
                            continue
                        }
                        XCTAssertTrue((7...14).contains(rank), drill.id)
                    }
                }
            }
        }
    }

    func testAllDiscardExercisesStateTheirLearningObjective() {
        for room in DrillLibrary.rooms {
            for drill in room.drills {
                guard case .discard(let scenarios) = drill.kind else { continue }
                for scenario in scenarios {
                    XCTAssertTrue(scenario.situation.contains("Lehrziel:"), scenario.id)
                    XCTAssertEqual(Set(scenario.recommendedDiscard).count, 2, scenario.id)
                }
            }
        }
    }

    func testPointMaximizingDiscardGoalsHaveUniqueSolutions() {
        for index in [0, 7] {
            let scenario = AdvancedContent.discards[index]
            let protected = scenario.deal.filter {
                if index == 0 { return $0.isJack || $0.rankValue == 14 }
                return $0.isJack || $0.suit == .clubs
            }
            let candidates = scenario.deal.filter { !protected.contains($0) }
            var bestPairs: [Set<PlayingCard>] = []
            var bestPoints = -1
            for firstIndex in candidates.indices {
                for secondIndex in candidates.indices where secondIndex > firstIndex {
                    let points = candidates[firstIndex].skatValue + candidates[secondIndex].skatValue
                    if points > bestPoints {
                        bestPoints = points
                        bestPairs = []
                    }
                    if points == bestPoints {
                        bestPairs.append([candidates[firstIndex], candidates[secondIndex]])
                    }
                }
            }
            XCTAssertEqual(bestPairs, [Set(scenario.recommendedDiscard)], scenario.id)
        }
    }

    func testTrumpFirstEndgamesAgainstEveryLegalDefense() {
        let positions: [(String, Suit?, [[PlayingCard]])] = [
            ("vertieft-ende-08", .clubs, [[.c(11), .d(14)], [.c(7), .h(10)], [.c(8), .s(13)]]),
            ("vertieft-ende-09", nil, [[.c(11), .h(14)], [.s(11), .s(10)], [.h(11), .d(13)]]),
            ("vertieft-ende-10", .hearts, [[.h(14), .d(14)], [.h(10), .s(13)], [.h(13), .c(10)]])
        ]
        for (questionID, trump, hands) in positions {
            let question = AdvancedContent.endgames.first { $0.id == questionID }
            XCTAssertEqual(question?.tiles, hands[0], questionID)
            let allCards = hands.flatMap { $0 }
            XCTAssertEqual(Set(allCards).count, 6, questionID)
            let totalPoints = allCards.reduce(0) { $0 + $1.skatValue }
            let winningLead = hands[0][0]
            let losingLead = hands[0][1]
            XCTAssertEqual(pointsAfterLead(winningLead, hands: hands, trump: trump), totalPoints, questionID)
            XCTAssertLessThan(pointsAfterLead(losingLead, hands: hands, trump: trump), totalPoints, questionID)
        }
    }

    func testThreeTrickPlanningAgainstEveryLegalDefense() {
        XCTAssertEqual(AdvancedContent.planningCases.count, 8)
        for lesson in AdvancedContent.planningCases {
            XCTAssertEqual(lesson.hands.map(\.count), [3, 3, 3], lesson.id)
            let allCards = lesson.hands.flatMap { $0 }
            XCTAssertEqual(Set(allCards).count, 9, lesson.id)
            let restEyes = allCards.reduce(0) { $0 + $1.skatValue }
            XCTAssertLessThanOrEqual(lesson.priorEyes + restEyes, 120, lesson.id)
            let values = lesson.hands[0].map {
                pointsAfterLead($0, hands: lesson.hands, trump: lesson.trump)
            }
            XCTAssertEqual(values, lesson.guaranteedEyes, lesson.id)
            let winners = values.indices.filter { values[$0] + lesson.priorEyes >= 61 }
            XCTAssertEqual(winners, [lesson.question.answerIndex], lesson.id)
            XCTAssertEqual(values.max()! + lesson.priorEyes, 61, lesson.id)
            XCTAssertEqual(lesson.question.choices[lesson.question.answerIndex],
                           lesson.hands[0][winners[0]].spokenName, lesson.id)
        }
    }

    func testNullTacticsRespectTheirDifferentRankOrder() {
        let tactics: [(String, [PlayingCard], [PlayingCard], PlayingCard)] = [
            ("vertieft-null-04", [.s(7), .s(10)], [.s(9), .s(11)], .s(9)),
            ("vertieft-null-05", [.d(8), .d(12)], [.d(11), .d(13)], .d(11)),
            ("vertieft-null-12", [.c(9), .c(10)], [.c(8), .c(12)], .c(8)),
            ("vertieft-null-20", [.s(7), .s(9)], [.s(8), .s(10)], .s(8))
        ]
        for (questionID, trick, hand, answer) in tactics {
            let winningReplies = hand.filter { card in
                (trick + [card]).enumerated().max { $0.element.rankValue < $1.element.rankValue }?.offset == 1
            }
            XCTAssertEqual(winningReplies, [answer], questionID)
            let question = AdvancedContent.nullPlay.first { $0.id == questionID }
            let rankNames = [8: "Acht", 9: "Neun", 11: "Bube"]
            XCTAssertEqual(question?.choices.first, "\(answer.suit!.displayName)-\(rankNames[answer.rankValue]!)", questionID)
        }
    }

    func testEveryGeneratedCategoryUsesOnlyItsSuppliedSeed() throws {
        for category in HandGenerator.generatableCategories {
            for seed in 0..<50 {
                var firstGenerator = StableSeededGenerator(seed: "expert-release-\(seed)")
                var secondGenerator = StableSeededGenerator(seed: "expert-release-\(seed)")
                let first = try XCTUnwrap(HandGenerator.hand(for: category, using: &firstGenerator))
                let second = try XCTUnwrap(HandGenerator.hand(for: category, using: &secondGenerator))
                XCTAssertEqual(first.tiles, second.tiles)
                XCTAssertEqual(first.choices, second.choices)
                XCTAssertEqual(firstGenerator.next(), secondGenerator.next())
            }
        }
    }

    private func pointsAfterLead(_ lead: PlayingCard, hands: [[PlayingCard]], trump: Suit?) -> Int {
        var remaining = hands
        remaining[0].removeAll { $0 == lead }
        return guaranteedPoints(hands: remaining, trick: [lead], leader: 0, trump: trump)
    }

    private func guaranteedPoints(hands: [[PlayingCard]], trick: [PlayingCard], leader: Int, trump: Suit?) -> Int {
        if trick.count == 3 {
            let lead = trick[0]
            let winnerOffset = trick.indices.max {
                strength(trick[$0], lead: lead, trump: trump) < strength(trick[$1], lead: lead, trump: trump)
            }!
            let winner = (leader + winnerOffset) % 3
            let points = winner == 0 ? trick.reduce(0) { $0 + $1.skatValue } : 0
            return points + guaranteedPoints(hands: hands, trick: [], leader: winner, trump: trump)
        }
        if hands.allSatisfy(\.isEmpty) { return 0 }
        let player = (leader + trick.count) % 3
        let following = hands[player].filter { card in
            guard let lead = trick.first else { return true }
            if isTrump(lead, suit: trump) { return isTrump(card, suit: trump) }
            return !isTrump(card, suit: trump) && card.suit == lead.suit
        }
        let legal = following.isEmpty ? hands[player] : following
        let outcomes = legal.map { card in
            var remaining = hands
            remaining[player].removeAll { $0 == card }
            return guaranteedPoints(hands: remaining, trick: trick + [card], leader: leader, trump: trump)
        }
        return player == 0 ? outcomes.max()! : outcomes.min()!
    }

    private func isTrump(_ card: PlayingCard, suit: Suit?) -> Bool {
        card.isJack || (suit != nil && card.suit == suit)
    }

    private func strength(_ card: PlayingCard, lead: PlayingCard, trump: Suit?) -> Int {
        if card.isJack {
            return 200 + (4 - Suit.allCases.firstIndex(of: card.suit!)!)
        }
        let order = [7, 8, 9, 12, 13, 10, 14]
        let rank = order.firstIndex(of: card.rankValue)!
        if isTrump(card, suit: trump) { return 100 + rank }
        if card.suit == lead.suit && !isTrump(lead, suit: trump) { return 10 + rank }
        return 0
    }
}
