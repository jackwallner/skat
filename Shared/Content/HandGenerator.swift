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

    private static let fullDeck: [PlayingCard] = Suit.allCases.flatMap { suit in
        PlayingCard.skatRanks.map { PlayingCard.standard(rank: $0, suit: suit) }
    }

    /// Open-ended deals for unseeded practice. The legacy deals above give
    /// Null and Stich a single hand each, which made Endless repeat itself.
    /// Rejection sampling keeps every hand inside the same `fits` rules.
    private static func variedDeal<R: RandomNumberGenerator>(
        _ target: HandCategory,
        using generator: inout R
    ) -> [PlayingCard]? {
        switch target {
        case .nullspiel, .stich:
            for _ in 0..<400 {
                let cards = Array(fullDeck.shuffled(using: &generator).prefix(5))
                if category(for: cards) == target { return cards }
            }
            return nil
        case .farbe:
            let suit = Suit.allCases.randomElement(using: &generator) ?? .hearts
            let plain = PlayingCard.skatRanks.filter { $0 != 11 }
            let size = Int.random(in: 4...5, using: &generator)
            var cards = plain.shuffled(using: &generator).prefix(size).map { PlayingCard.standard(rank: $0, suit: suit) }
            if size == 4 {
                let other = fullDeck.filter { $0.suit != suit && !$0.isJack }.randomElement(using: &generator)
                cards += other.map { [$0] } ?? []
            }
            return cards
        case .trumpf:
            let suit = Suit.allCases.randomElement(using: &generator) ?? .hearts
            let jacks = SkatRules.jackOrder.shuffled(using: &generator).prefix(2).map { PlayingCard.standard(rank: 11, suit: $0) }
            let plain = PlayingCard.skatRanks.filter { $0 != 11 }.shuffled(using: &generator).prefix(3)
            return jacks + plain.map { PlayingCard.standard(rank: $0, suit: suit) }
        case .grand:
            let extra = fullDeck.filter { !$0.isJack }.randomElement(using: &generator)
            return SkatRules.jackOrder.map { PlayingCard.standard(rank: 11, suit: $0) } + (extra.map { [$0] } ?? [])
        default:
            return nil
        }
    }

    private static func deal<R: RandomNumberGenerator>(
        _ target: HandCategory,
        varied: Bool,
        using generator: inout R
    ) -> [PlayingCard]? {
        if varied, let cards = variedDeal(target, using: &generator), category(for: cards) == target {
            return cards
        }
        return legacyDeal(target, using: &generator)
    }

    private static func legacyDeal<R: RandomNumberGenerator>(
        _ target: HandCategory,
        using generator: inout R
    ) -> [PlayingCard]? {
        let cards: [PlayingCard]
        switch target {
        case .grand:
            cards = [.c(11), .s(11), .h(11), .d(11), .c([7, 8, 9, 10, 12, 13, 14].randomElement(using: &generator) ?? 7)]
        case .trumpf:
            let suit: Suit = Bool.random(using: &generator) ? .hearts : .diamonds
            cards = [
                .c(11), .s(11),
                .standard(rank: 7, suit: suit),
                .standard(rank: 10, suit: suit),
                .standard(rank: 14, suit: suit)
            ]
        case .farbe:
            let suit = Suit.allCases.randomElement(using: &generator) ?? .hearts
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
        return hand(for: target, attempts: attempts, varied: true, using: &generator)
    }

    /// The seeded variant. A dated challenge has to deal the SAME original hand
    /// on every device, so every source of randomness inside has to come from
    /// the caller's generator, not from the system one.
    static func hand<R: RandomNumberGenerator>(
        for target: HandCategory,
        attempts: Int = 120,
        varied: Bool = false,
        using generator: inout R
    ) -> GeneratedHand? {
        for _ in 0..<attempts {
            guard let cards = deal(target, varied: varied, using: &generator), category(for: cards) == target else { continue }
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
        return batch(count: count, varied: true, using: &generator)
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
        varied: Bool = false,
        using generator: inout R
    ) -> [GeneratedHand] {
        var targets: [HandCategory] = []
        while targets.count < count { targets += generatableCategories.shuffled(using: &generator) }
        return targets.prefix(count).compactMap { hand(for: $0, varied: varied, using: &generator) }.shuffled(using: &generator)
    }

    /// Why a wrong read does not fit this hand, naming the actual counts so the
    /// note teaches the rule rather than restating the answer.
    static func missNote(for cards: [PlayingCard], picked: HandCategory) -> String {
        let jacks = jackCount(cards)
        let suitCount = maximumSuitCount(cards)
        let aces = ranks(cards).filter { $0 == 14 }.count
        let jackText = jacks == 1 ? "1 Buben" : "\(jacks) Buben"
        switch picked {
        case .grand:
            return "Für Grand braucht das Muster mindestens drei Buben. Hier sind es \(jackText)."
        case .trumpf:
            if jacks != 2 { return "Das Trumpfmuster hat genau zwei Buben. Hier sind es \(jackText)." }
            return "Das Trumpfmuster braucht mindestens drei Karten einer Farbe. Die längste Farbe hat hier \(suitCount)."
        case .farbe:
            if jacks > 0 { return "Das Farbmuster hat keinen Buben, denn Buben sind eigene Trümpfe. Hier sind es \(jackText)." }
            return "Das Farbmuster braucht mindestens vier Karten einer Farbe. Die längste Farbe hat hier \(suitCount)."
        case .nullspiel:
            if jacks > 0 { return "Das Nullmuster hat keinen Buben. Hier sind es \(jackText)." }
            if ranks(cards).contains(where: { $0 > 10 }) { return "Das Nullmuster hat nur Karten bis zur Zehn. Hier liegt eine höhere Karte." }
            return "Das Nullmuster verteilt sich auf mehrere Farben, höchstens drei pro Farbe. Hier sind es \(suitCount)."
        case .stich:
            if aces < 2 { return "Das Stichmuster braucht mindestens zwei Asse. Hier \(aces == 1 ? "liegt eines" : "liegt keines")." }
            if jacks >= 3 { return "Mit drei oder mehr Buben liest du zuerst Grand, nicht Stich." }
            if suitCount >= 4 { return "Vier Karten einer Farbe lesen sich zuerst als Farbmuster, nicht als Stichmuster." }
            return "Zwei Buben und mehrere Karten einer Farbe lesen sich zuerst als Trumpfmuster."
        default:
            return picked.howToSpot
        }
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
