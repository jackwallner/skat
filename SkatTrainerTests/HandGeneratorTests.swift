import XCTest
@testable import SkatTrainer

final class HandGeneratorTests: XCTestCase {
    func testReadsAGrandPattern() {
        let cards: [PlayingCard] = [.c(11), .s(11), .h(11), .d(11), .c(14)]
        XCTAssertEqual(HandGenerator.category(for: cards), .grand)
    }

    func testReadsATrumpfPattern() {
        let cards: [PlayingCard] = [.c(11), .s(11), .h(7), .h(10), .h(14)]
        XCTAssertEqual(HandGenerator.category(for: cards), .trumpf)
        XCTAssertFalse(HandGenerator.fits(cards, .grand))
    }

    func testReadsAFarbePattern() {
        let cards: [PlayingCard] = [.c(7), .c(8), .c(9), .c(10), .c(14)]
        XCTAssertEqual(HandGenerator.category(for: cards), .farbe)
    }

    func testReadsANullPattern() {
        let cards: [PlayingCard] = [.c(7), .d(8), .h(9), .s(10), .c(8)]
        XCTAssertEqual(HandGenerator.category(for: cards), .nullspiel)
    }

    func testReadsAStichPattern() {
        let cards: [PlayingCard] = [.c(14), .d(14), .h(13), .s(12), .c(10)]
        XCTAssertEqual(HandGenerator.category(for: cards), .stich)
    }

    func testGeneratedHandsAreLegalAndUnambiguous() {
        for target in HandGenerator.generatableCategories {
            for _ in 0..<20 {
                guard let hand = HandGenerator.hand(for: target) else {
                    XCTFail("Could not deal a hand for \(target.displayName)")
                    continue
                }
                XCTAssertEqual(hand.tiles.count, 5)
                XCTAssertEqual(Set(hand.tiles).count, hand.tiles.count)
                XCTAssertEqual(HandGenerator.category(for: hand.tiles), target)
                XCTAssertTrue(hand.choices.contains(target))
                XCTAssertGreaterThanOrEqual(hand.choices.count, 3)
                XCTAssertEqual(Set(hand.choices).count, hand.choices.count)
                for choice in hand.choices where choice != target {
                    XCTAssertFalse(HandGenerator.fits(hand.tiles, choice), "\(choice.displayName) is also a correct answer")
                }
                XCTAssertFalse(hand.explanation.isEmpty)
                XCTAssertFalse(hand.explanation.contains("\u{2014}"))
            }
        }
    }

    func testBatchCoversEverySkill() {
        let hands = HandGenerator.batch(count: 60)
        XCTAssertGreaterThan(hands.count, 40)
        XCTAssertEqual(Set(hands.map(\.answer)).count, HandGenerator.generatableCategories.count)
    }

    func testTrickItemsDescribeLegalChoices() {
        let items = EndlessPractice.items(for: .trickPlay, count: 40)
        for item in items {
            guard case .standard(let rank, _) = item.tiles[0] else {
                XCTFail("Generated trick item must show a standard card")
                continue
            }
            XCTAssertTrue((7...14).contains(rank))
            XCTAssertTrue(item.prompt.contains("Angespielte Farbe"))
        }
    }

    func testMixedItemsDrawFromEverySkill() {
        let items = EndlessPractice.mixedItems(count: 40)
        XCTAssertEqual(items.count, 40)
        XCTAssertEqual(Set(items.compactMap { PracticeSkill.skill(forItemID: $0.id) }).count,
                       PracticeSkill.allCases.count)
    }
}
