import XCTest
@testable import SkatTrainer

/// Cross-checks of the teaching content and the rules engine against the
/// Internationale Skatordnung (ISkO 2022). The tables below are written out
/// separately from the arithmetic in `AdvancedContent`, so an edit to either
/// side has to be deliberate.
final class SkatRulesAuditTests: XCTestCase {
    private func card(_ rank: Int, _ suit: Suit) -> PlayingCard { .standard(rank: rank, suit: suit) }

    // MARK: - Spielwert (ISkO 2.4, 2.5, 3.6)

    /// id: (Grundwert, Spitzen mit/ohne n, Gewinnstufen on top of "Spiel").
    /// The Summe der Fälle is Spitzen + 1 (Spiel) + Stufen (ISkO 2.5.1).
    private let valueTable: [String: (base: Int, spitzen: Int, stufen: Int)] = [
        "vertieft-wert-01": (12, 2, 0), "vertieft-wert-02": (11, 3, 0),
        "vertieft-wert-03": (10, 1, 1), "vertieft-wert-04": (9, 2, 1),
        "vertieft-wert-05": (24, 2, 1), "vertieft-wert-06": (12, 1, 1),
        "vertieft-wert-07": (11, 1, 0), "vertieft-wert-08": (10, 2, 3),
        "vertieft-wert-09": (9, 1, 3), "vertieft-wert-10": (24, 4, 6),
        "vertieft-wert-11": (12, 2, 0), "vertieft-wert-12": (11, 1, 0),
        "vertieft-wert-13": (10, 2, 1), "vertieft-wert-14": (24, 1, 3),
        "vertieft-wert-15": (12, 1, 0), "vertieft-wert-16": (11, 1, 0),
        "vertieft-wert-17": (10, 1, 0), "vertieft-wert-18": (9, 1, 0),
        "vertieft-wert-19": (24, 1, 0), "vertieft-wert-20": (9, 1, 1),
        "vertieft-wert-21": (9, 1, 2), "vertieft-wert-22": (12, 5, 0),
        "vertieft-wert-23": (10, 6, 0), "vertieft-wert-24": (24, 4, 0),
    ]

    func testValueCasesMatchTheIskoTable() {
        XCTAssertEqual(AdvancedContent.valueCases.count, valueTable.count)
        for lesson in AdvancedContent.valueCases {
            let row = valueTable[lesson.id]
            XCTAssertNotNil(row, lesson.id)
            guard let row else { continue }
            let sum = row.spitzen + 1 + row.stufen
            XCTAssertEqual(lesson.base, row.base, lesson.id)
            XCTAssertEqual(lesson.multiplier, sum, lesson.id)
            // 3.6.1: an overbid game is raised by whole Grundwerte until it
            // reaches the bid; a lost game is written off at double (2.5.11).
            var value = row.base * sum
            if lesson.lost {
                while value < lesson.bid { value += row.base }
                value = -2 * value
            }
            XCTAssertEqual(lesson.expected, value, lesson.id)
        }
    }

    func testGrundwerteAndExtremeGames() {
        // 2.4: Karo 9, Herz 10, Pik 11, Kreuz 12, Grand 24.
        XCTAssertEqual([9, 10, 11, 12, 24].map { $0 * 2 }, [18, 20, 22, 24, 48])
        // 3.3.1: the highest possible game is Grand ouvert mit 4, 11 x 24.
        XCTAssertEqual(24 * 11, 264)
        // 2.5.8: Kreuz ouvert mit 2 counts Spiel, Hand, Schneider, Schneider
        // angesagt, Schwarz, Schwarz angesagt and Ouvert on top of 2 Spitzen.
        XCTAssertEqual(12 * (2 + 1 + 6), 108)
    }

    func testReizwerteComeFromTheGameValues() {
        var values = Set<Int>()
        for base in [9, 10, 11, 12, 24] {
            for factor in 2...14 { values.insert(base * factor) }
        }
        values.formUnion([23, 35, 46, 59])
        let ladder = values.sorted().prefix(16)
        XCTAssertEqual(Array(ladder), [18, 20, 22, 23, 24, 27, 30, 33, 35, 36, 40, 44, 45, 46, 48, 50])
        let flashcards: [Flashcard] = DrillLibrary.rooms.flatMap(\.drills).flatMap { drill -> [Flashcard] in
            if case .flashcards(let cards) = drill.kind { return cards }
            return []
        }
        let body = flashcards.first { $0.id == "karten-reizwerte" }?.backBody ?? ""
        XCTAssertFalse(body.isEmpty)
        for value in ladder.prefix(10) { XCTAssertTrue(body.contains(String(value)), "\(value)") }
    }

    // MARK: - Bedienpflicht and trump (ISkO 4.2)

    private func legal(_ hand: [PlayingCard], lead: PlayingCard, _ game: TrickGame) -> [PlayingCard] {
        let led = SkatRules.family(of: lead, in: game)
        let following = hand.filter { SkatRules.family(of: $0, in: game) == led }
        return following.isEmpty ? hand : following
    }

    func testBubeIsTrumpAndNotPartOfItsSuit() {
        // Grand: the Kreuz-Bube is trump, so a lead of Kreuz 7 is not followed by it.
        XCTAssertEqual(legal([card(11, .clubs), card(14, .hearts)], lead: card(7, .clubs), .grand).count, 2)
        // Herz as trump: Herz 7 is trump, a Pik-Bube must follow it, a Karo Ass need not.
        XCTAssertEqual(legal([card(11, .spades), card(14, .diamonds)], lead: card(7, .hearts), .suit(.hearts)), [card(11, .spades)])
        // Grand: leading a Bube demands a Bube, not the printed suit.
        XCTAssertEqual(legal([card(11, .hearts), card(14, .spades)], lead: card(11, .spades), .grand), [card(11, .hearts)])
        // Herz as trump, Kreuz Ass led: the Kreuz-Bube is trump and does not follow.
        XCTAssertEqual(legal([card(7, .clubs), card(11, .hearts)], lead: card(14, .clubs), .suit(.hearts)), [card(7, .clubs)])
        // Pik as trump, Karo 10 led: neither Pik 7 nor Herz 7 is Karo.
        XCTAssertEqual(legal([card(7, .spades), card(7, .hearts)], lead: card(10, .diamonds), .suit(.spades)).count, 2)
    }

    func testNullKeepsTheBubeInItsSuit() {
        XCTAssertEqual(legal([card(11, .clubs), card(7, .hearts)], lead: card(7, .clubs), .null), [card(11, .clubs)])
        // Null order: A K D B 10 9 8 7.
        let order = [14, 13, 12, 11, 10, 9, 8, 7].map { card($0, .hearts) }
        for index in 0..<(order.count - 1) {
            XCTAssertEqual(SkatRules.winnerIndex(of: [order[index + 1], order[index]], in: .null), 1)
        }
        // The Bube is no trump in Null, so a Herz Ass beats a lower Herz lead and a Kreuz Bube cannot take it.
        XCTAssertEqual(SkatRules.winnerIndex(of: [card(10, .hearts), card(11, .clubs), card(14, .hearts)], in: .null), 2)
    }

    func testSuitGameAndGrandTrickOrder() {
        // Jacks Kreuz, Pik, Herz, Karo, then A 10 K D 9 8 7 of the trump suit.
        let trumps = [card(11, .clubs), card(11, .spades), card(11, .hearts), card(11, .diamonds),
                      card(14, .hearts), card(10, .hearts), card(13, .hearts), card(12, .hearts),
                      card(9, .hearts), card(8, .hearts), card(7, .hearts)]
        for index in 0..<(trumps.count - 1) {
            XCTAssertEqual(SkatRules.winnerIndex(of: [trumps[index + 1], trumps[index]], in: .suit(.hearts)), 1)
        }
        // A trump beats the led side-suit Ass, and a plain Ass wins when nobody trumps.
        XCTAssertEqual(SkatRules.winnerIndex(of: [card(14, .clubs), card(7, .hearts)], in: .suit(.hearts)), 1)
        XCTAssertEqual(SkatRules.winnerIndex(of: [card(10, .clubs), card(14, .spades), card(14, .clubs)], in: .suit(.hearts)), 2)
        // Grand: only Buben are trump; the Ass of the trump-like suit is just a suit card.
        XCTAssertEqual(SkatRules.winnerIndex(of: [card(7, .hearts), card(14, .hearts), card(11, .diamonds)], in: .grand), 2)
        XCTAssertEqual(SkatRules.winnerIndex(of: [card(10, .hearts), card(13, .hearts), card(14, .hearts)], in: .grand), 2)
        XCTAssertEqual(SkatRules.winnerIndex(of: [card(14, .hearts), card(10, .hearts), card(13, .hearts)], in: .grand), 0)
    }

    func testSpitzenFromBubenAlone() {
        XCTAssertEqual(SkatRules.spitzen(holding: [.clubs, .spades]).count, 2)
        XCTAssertTrue(SkatRules.spitzen(holding: [.clubs, .spades]).mit)
        XCTAssertEqual(SkatRules.spitzen(holding: [.clubs, .hearts]).count, 1)
        XCTAssertEqual(SkatRules.spitzen(holding: [.spades, .hearts, .diamonds]).count, 1)
        XCTAssertFalse(SkatRules.spitzen(holding: [.spades, .hearts, .diamonds]).mit)
        XCTAssertEqual(SkatRules.spitzen(holding: []).count, 4)
        XCTAssertEqual(SkatRules.spitzen(holding: Set(Suit.allCases)).count, 4)
    }

    // MARK: - Content invariants

    func testMasterRoomSubtitlesMatchTheirItemCounts() throws {
        let master = try XCTUnwrap(DrillLibrary.room(id: "pro-tables"))
        for drill in master.drills {
            let first = drill.subtitle.split(separator: " ").first.map(String.init) ?? ""
            let stated = Int(first) ?? (first == "Acht" ? 8 : -1)
            XCTAssertEqual(stated, drill.kind.itemCount, drill.id)
        }
        XCTAssertEqual(master.drills.reduce(0) { $0 + $1.kind.itemCount }, 100)
    }

    func testStructureHandMatchesTheGeneratorRule() {
        for question in MoreContent.handReading where question.id == "mehr-struktur-1" {
            XCTAssertEqual(question.answer, .trumpf)
            XCTAssertTrue(HandGenerator.fits(question.tiles, .trumpf))
        }
    }

    func testDiscardAnswersListCardsInDealOrder() {
        for room in DrillLibrary.rooms {
            for drill in room.drills {
                guard case .discard(let scenarios) = drill.kind else { continue }
                for scenario in scenarios {
                    let inDealOrder = scenario.deal.filter { scenario.recommendedDiscard.contains($0) }
                    XCTAssertEqual(inDealOrder, scenario.recommendedDiscard, scenario.id)
                    XCTAssertEqual(scenario.recommendedDiscard.count, 2, scenario.id)
                }
            }
        }
    }

    func testTimeChallengeLastsNinetySeconds() {
        // The store text and the paywall say "90 Sekunden".
        XCTAssertEqual(PracticeRunView.challengeSeconds, 90)
    }

    func testWhatsNewCarriesThe130Release() throws {
        XCTAssertNil(WhatsNew.releases.first { $0.version == "1.2.4" })
        let release = try XCTUnwrap(WhatsNew.releases.first { $0.version == "1.3.0" })
        XCTAssertTrue(release.items.contains { $0.id == "week-gain" })
    }
}
