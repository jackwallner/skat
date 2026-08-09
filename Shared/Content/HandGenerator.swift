import Foundation

/// Deals original five-card teaching patterns for generated Skat practice.
/// These are recognition exercises, not complete hands or copied card content.
enum HandGenerator {
    static let generatableCategories: [HandCategory] = [.grand, .trumpf, .farbe, .nullspiel, .stich]

    private static func ranks(_ cards: [PlayingCard]) -> [Int] {
        cards.compactMap { card in
            if case .standard(let rank, _) = card { return rank }
            return nil
        }
    }

    private static func suits(_ cards: [PlayingCard]) -> [Suit] {
        cards.compactMap(\.suit)
    }

    private static func jackCount(_ cards: [PlayingCard]) -> Int {
        cards.filter(\.isJack).count
    }

    private static func maximumSuitCount(_ cards: [PlayingCard]) -> Int {
        Dictionary(grouping: suits(cards), by: { $0 })
            .values
            .map(\.count)
            .max() ?? 0
    }

    private static func hasLowNullShape(_ cards: [PlayingCard]) -> Bool {
        jackCount(cards) == 0 && ranks(cards).allSatisfy { $0 <= 10 } && maximumSuitCount(cards) < 4
    }

    /// The checks intentionally describe mutually exclusive teaching reads.
    static func fits(_ cards: [PlayingCard], _ category: HandCategory) -> Bool {
        guard cards.count == 5, cards.allSatisfy({ $0.suit != nil }) else { return false }
        let jacks = jackCount(cards)
        let aces = ranks(cards).filter { $0 == 14 }.count
        let suitCount = maximumSuitCount(cards)

        switch category {
        case .grand:
            return jacks >= 3
        case .trumpf:
            return jacks == 2 && suitCount >= 3
        case .farbe:
            return jacks == 0 && suitCount >= 4
        case .nullspiel:
            return hasLowNullShape(cards)
        case .stich:
            return aces >= 2 && jacks < 3 && suitCount < 4 && !hasLowNullShape(cards) && !fits(cards, .trumpf)
        default:
            return false
        }
    }

    static func category(for cards: [PlayingCard]) -> HandCategory? {
        let matches = generatableCategories.filter { fits(cards, $0) }
        return matches.count == 1 ? matches[0] : nil
    }

    struct GeneratedHand {
        let tiles: [PlayingCard]
        let answer: HandCategory
        let choices: [HandCategory]
        let explanation: String
    }

    private static func deal<R: RandomNumberGenerator>(
        _ target: HandCategory,
        using generator: inout R
    ) -> [PlayingCard]? {
        let cards: [PlayingCard]
        switch target {
        case .grand:
            cards = [.c(11), .s(11), .h(11), .d(11), .c([7, 8, 9, 10, 12, 13, 14].randomElement() ?? 7)]
        case .trumpf:
            let suit: Suit = Bool.random() ? .hearts : .diamonds
            cards = [
                .c(11), .s(11),
                .standard(rank: 7, suit: suit),
                .standard(rank: 10, suit: suit),
                .standard(rank: 14, suit: suit)
            ]
        case .farbe:
            let suit = Suit.allCases.randomElement() ?? .hearts
            cards = [7, 8, 9, 10, 14].map { .standard(rank: $0, suit: suit) }
        case .nullspiel:
            cards = [.c(7), .d(8), .h(9), .s(10), .c(8)]
        case .stich:
            cards = [.c(14), .d(14), .h(13), .s(12), .c(10)]
        default:
            return nil
        }
        return category(for: cards) == target ? cards : nil
    }

    static func hand(for target: HandCategory, attempts: Int = 120) -> GeneratedHand? {
        var generator = SystemRandomNumberGenerator()
        return hand(for: target, attempts: attempts, using: &generator)
    }

    /// The seeded variant. A dated challenge has to deal the SAME original hand
    /// on every device, so every source of randomness inside has to come from
    /// the caller's generator, not from the system one.
    static func hand<R: RandomNumberGenerator>(
        for target: HandCategory,
        attempts: Int = 120,
        using generator: inout R
    ) -> GeneratedHand? {
        for _ in 0..<attempts {
            guard let cards = deal(target, using: &generator), category(for: cards) == target else { continue }
            let distractors = generatableCategories
                .filter { $0 != target && !fits(cards, $0) }
                .shuffled(using: &generator)
                .prefix(3)
            guard distractors.count >= 2 else { continue }
            return GeneratedHand(
                tiles: cards.racked,
                answer: target,
                choices: ([target] + distractors).shuffled(using: &generator),
                explanation: explain(cards, answer: target)
            )
        }
        return nil
    }

    static func batch(count: Int) -> [GeneratedHand] {
        var generator = SystemRandomNumberGenerator()
        return batch(count: count, using: &generator)
    }

    /// A reproducible batch for a dated shared challenge. The same app build
    /// and seed produce the same original hands on every device, which is what
    /// lets every member answer the same daily challenge without a server.
    static func batch(count: Int, seed: String) -> [GeneratedHand] {
        var generator = StableSeededGenerator(seed: seed)
        return batch(count: count, using: &generator)
    }

    private static func batch<R: RandomNumberGenerator>(
        count: Int,
        using generator: inout R
    ) -> [GeneratedHand] {
        var targets: [HandCategory] = []
        while targets.count < count { targets += generatableCategories.shuffled(using: &generator) }
        return targets.prefix(count).compactMap { hand(for: $0, using: &generator) }.shuffled(using: &generator)
    }

    static func explain(_ cards: [PlayingCard], answer: HandCategory) -> String {
        let labels = cards.racked.map(\.shortLabel).joined(separator: ", ")
        switch answer {
        case .grand:
            return "In diesem Muster liegen mindestens drei Buben: \(labels). Die vier Buben sind im Grand die einzigen Trümpfe."
        case .trumpf:
            return "Zwei Buben und mehrere Karten derselben Farbe geben hier eine klare Trumpfstruktur: \(labels). Im Farbspiel zählen die Buben zusätzlich als Trumpf."
        case .farbe:
            return "Vier oder mehr Karten gehören zu derselben Farbe: \(labels). Das ist ein starkes Farbgefühl, auch wenn die konkrete Spielansage noch fehlt."
        case .nullspiel:
            return "Die Karten sind niedrig, enthalten keinen Buben und verteilen sich auf mehrere Farben: \(labels). Das passt zu einer Null-Idee."
        case .stich:
            return "Zwei Asse und hohe Beikarten bilden eine sichere Stichstruktur: \(labels). Den konkreten Stichwert prüfst du danach im Spielkontext."
        default:
            return answer.howToSpot
        }
    }
}
