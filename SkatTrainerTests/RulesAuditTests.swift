import XCTest
@testable import SkatTrainer

final class RulesAuditTests: XCTestCase {
    private func card(_ code: String) -> PlayingCard {
        let suits: [Character: Suit] = ["C": .clubs, "D": .diamonds, "H": .hearts, "S": .spades]
        return .standard(rank: Int(code.dropFirst())!, suit: suits[code.first!]!)
    }
    private func reference() throws -> [String: Any] {
        let url = Bundle(for: Self.self).url(forResource: "rules-reference", withExtension: "json")
            ?? URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("Resources/rules-reference.json")
        return try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
    }
    func testCardValuesAndTrumpCounts() {
        for (rank, value) in [(7, 0), (8, 0), (9, 0), (10, 10), (11, 2), (12, 3), (13, 4), (14, 11)] {
            for suit in Suit.allCases { XCTAssertEqual(card("\(suit.rawValue.prefix(1).uppercased())\(rank)").skatValue, value) }
        }
        let deck = Suit.allCases.flatMap { suit in (7...14).map { PlayingCard.standard(rank: $0, suit: suit) } }
        XCTAssertEqual(deck.reduce(0) { $0 + $1.skatValue }, 120)
        for suit in Suit.allCases { XCTAssertEqual(deck.filter { SkatRuleReference.isTrump($0, trump: suit) }.count, 11) }
        XCTAssertEqual(deck.filter { SkatRuleReference.isTrump($0, trump: nil) }.count, 4)
        XCTAssertEqual(deck.filter { SkatRuleReference.isTrump($0, trump: nil, null: true) }.count, 0)
    }
    func testFollowingAndTrickAnswersUseDisplayedCards() throws {
        let drills = DrillLibrary.rooms.flatMap(\.drills)
        let flashcards = drills.flatMap { if case .flashcards(let c) = $0.kind { return c }; return [Flashcard]() }
        let quizzes = drills.flatMap { if case .quiz(let q) = $0.kind { return q }; return [QuizQuestion]() }
        let data = try reference()
        for r in data["legal"] as! [[String: Any]] {
            let id = r["id"] as! String
            let hand = (r["hand"] as! [String]).map(card)
            let shown = quizzes.first { $0.id == id }?.tiles ?? flashcards.first { $0.id == id }!.frontTiles
            XCTAssertEqual(shown, hand, id)
            let trump = (r["trump"] as? String).flatMap(Suit.init(rawValue:))
            XCTAssertEqual(SkatRuleReference.legal(shown, led: card(r["led"] as! String), trump: trump, null: r["null"] as! Bool), (r["expected"] as! [String]).map(card), id)
        }
        for r in data["tricks"] as! [[String: Any]] {
            let q = try XCTUnwrap(quizzes.first { $0.id == r["id"] as? String })
            XCTAssertEqual(q.tiles, (r["cards"] as! [String]).map(card))
            let winner = SkatRuleReference.winner(q.tiles, trump: (r["trump"] as? String).flatMap(Suit.init(rawValue:)), null: r["null"] as! Bool)
            XCTAssertEqual(winner, r["winner"] as? Int)
            let game: TrickGame = (r["null"] as! Bool) ? .null : ((r["trump"] as? String).flatMap(Suit.init(rawValue:)).map(TrickGame.suit) ?? .grand)
            XCTAssertEqual(SkatRules.winnerIndex(of: q.tiles, in: game), winner)
            // The correct choice names the winning card, not the first card.
            let winningCard = q.tiles[winner!]
            let rankName = [10: "Zehn", 11: "Bube", 13: "König", 14: "Ass"][winningCard.rankValue]!
            XCTAssertEqual(q.choices[q.answerIndex], "\(winningCard.suit!.displayName)-\(rankName)")
        }
    }
    func testMatadorsIncludeSkatAndContinueBeyondJacks() throws {
        for r in try reference()["matadors"] as! [[String: Any]] {
            XCTAssertEqual(SkatRuleReference.matadors((r["cards"] as! [String]).map(card), trump: (r["trump"] as? String).flatMap(Suit.init(rawValue:))), r["expected"] as! Int)
        }
    }
    func testIskoScoringThresholdsAnnouncementsAndOverbids() throws {
        for r in try reference()["scores"] as! [[String: Any]] {
            let actual = SkatRuleReference.score(base: r["base"] as! Int, matadors: r["matadors"] as! Int,
                hand: r["hand"] as! Bool, points: r["points"] as! Int, tricks: r["tricks"] as! Int,
                bid: r["bid"] as! Int, schneider: r["schneider"] as! Bool, schwarz: r["schwarz"] as! Bool, ouvert: r["ouvert"] as! Bool)
            XCTAssertEqual(actual, r["expected"] as? Int, r["id"] as! String)
            if let lesson = AdvancedContent.valueCases.first(where: { $0.id == r["id"] as? String }) {
                XCTAssertEqual(lesson.question.choices[lesson.question.answerIndex], String(actual!))
            }
        }
        for (hand, ouvert, expected) in [(false, false, 23), (true, false, 35), (false, true, 46), (true, true, 59)] {
            XCTAssertEqual(SkatRuleReference.nullScore(hand: hand, ouvert: ouvert, tricks: 0, bid: 18), expected)
            XCTAssertEqual(SkatRuleReference.nullScore(hand: hand, ouvert: ouvert, tricks: 1, bid: 18), -2 * expected)
        }
        XCTAssertNil(SkatRuleReference.score(base: 24, matadors: 4, points: 120, tricks: 10, bid: 18, ouvert: true))
        XCTAssertTrue(HowToPlayContent.pages.first(where: { $0.id == "primer-reizen" })!.body.contains("Wenn alle passen"))
        XCTAssertTrue(HowToPlayContent.pages.first(where: { $0.id == "primer-reizen" })!.body.contains("nächste Geber"))
    }
}
