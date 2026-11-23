import XCTest
@testable import SkatTrainer

/// Das Glossar wird mitten im Spiel gelesen, also wird jede genannte Zahl und
/// Reihenfolge gegen `SkatRules` geprüft, nach denen die Übungen werten.
final class ReferenceContentTests: XCTestCase {

    private func definition(_ id: String) -> String {
        ReferenceContent.glossary.first { $0.id == id }?.definition ?? ""
    }

    private let deck: [PlayingCard] = Suit.allCases.flatMap { suit in
        (7...14).map { PlayingCard.standard(rank: $0, suit: suit) }
    }

    func testIDsAreUniqueAndEveryGroupHasEntries() {
        let ids = ReferenceContent.glossary.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
        for group in GlossaryGroup.allCases {
            XCTAssertFalse(ReferenceContent.terms(in: group).isEmpty, group.title)
        }
    }

    func testNoEmDashes() {
        for term in ReferenceContent.glossary {
            XCTAssertFalse(term.term.contains("—") || term.definition.contains("—"), term.id)
        }
    }

    func testSearchFindsOtherNames() {
        XCTAssertTrue(ReferenceContent.terms(in: .value, matching: "matador").contains { $0.id == "g-spitzen" })
        XCTAssertTrue(ReferenceContent.terms(in: .play, matching: "Farbzwang").contains { $0.id == "g-bedienen" })
        XCTAssertTrue(GlossaryGroup.allCases.allSatisfy { ReferenceContent.terms(in: $0, matching: "zzzz").isEmpty })
    }

    func testAugenAddUpTo120() {
        XCTAssertEqual(deck.count, 32)
        XCTAssertEqual(SkatRules.points(in: deck), 120)
        XCTAssertTrue(definition("g-augen").contains("120 Augen"))
        for (rank, value) in [(14, 11), (10, 10), (13, 4), (12, 3), (11, 2), (9, 0), (8, 0), (7, 0)] {
            XCTAssertEqual(PlayingCard.standard(rank: rank, suit: .hearts).skatValue, value)
        }
    }

    func testQuotedOrdersMatchTheRules() {
        XCTAssertEqual(SkatRules.jackOrder, [.clubs, .spades, .hearts, .diamonds])
        XCTAssertTrue(definition("g-buben").contains("Kreuz, Pik, Herz, Karo"))
        XCTAssertEqual(SkatRules.suitRankOrder, [14, 10, 13, 12, 9, 8, 7])
        XCTAssertEqual(SkatRules.nullRankOrder, [14, 13, 12, 11, 10, 9, 8, 7])
        XCTAssertTrue(definition("g-reihenfolge").contains("Ass, Zehn, König, Dame, Neun, Acht, Sieben"))
        XCTAssertTrue(definition("g-reihenfolge").contains("Ass, König, Dame, Bube, Zehn, Neun, Acht, Sieben"))
    }

    func testElevenTrumpsInASuitGame() {
        let trumps = deck.filter { SkatRules.family(of: $0, in: .suit(.hearts)) == .trump }
        XCTAssertEqual(trumps.count, 11)
        XCTAssertTrue(definition("g-trumpf").contains("elf Karten"))
        XCTAssertEqual(deck.filter { SkatRules.family(of: $0, in: .grand) == .trump }.count, 4)
        XCTAssertTrue(deck.allSatisfy { SkatRules.family(of: $0, in: .null) != .trump })
    }

    func testReizwerteAreRealGameValues() {
        // Grundwert mal Stufen, from mit/ohne 1 and Spiel (2) upward.
        var values = Set<Int>()
        for base in [9, 10, 11, 12, 24] {
            for multiplier in 2...18 { values.insert(base * multiplier) }
        }
        values.formUnion([23, 35, 46, 59])
        let quoted = [18, 20, 22, 23, 24, 27, 30, 33, 35, 36, 40, 44]
        XCTAssertEqual(values.sorted().prefix(quoted.count).map { $0 }, quoted)
        XCTAssertTrue(definition("g-reizwerte").contains(quoted.map(String.init).joined(separator: ", ")))
    }
}
