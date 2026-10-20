import Foundation

/// Generated questions whose answers come from `SkatRules`, not from a stored
/// key. Each builder returns the choices already ordered, with a coaching note
/// for every wrong choice.
enum PracticeGenerators {
    private static var deck: [PlayingCard] {
        Suit.allCases.flatMap { suit in PlayingCard.skatRanks.map { PlayingCard.standard(rank: $0, suit: suit) } }
    }

    private static func cardName(_ card: PlayingCard) -> String { card.spokenName }

    // MARK: - Augen zählen

    static func countingItem<R: RandomNumberGenerator>(using generator: inout R) -> QuickItem {
        let size = Int.random(in: 3...5, using: &generator)
        let cards = Array(deck.shuffled(using: &generator).prefix(size)).racked
        let total = SkatRules.points(in: cards)
        let breakdown = cards.map { "\(cardName($0)) \($0.skatValue)" }.joined(separator: " + ")

        var wrong: [Int] = []
        for offset in [1, 2, 3, 4, 10, -1, -2, -3, -4, -10].shuffled(using: &generator) {
            let value = total + offset
            if value >= 0, value != total, !wrong.contains(value) { wrong.append(value) }
            if wrong.count == 3 { break }
        }
        let values = ([total] + wrong).shuffled(using: &generator)
        let explanation = "Ass 11, Zehn 10, König 4, Dame 3, Bube 2, Neun, Acht und Sieben 0. Hier: \(breakdown) = \(total) Augen."
        let wrongNote = "Das stimmt nicht. Zähle Karte für Karte: \(breakdown) = \(total)."
        return QuickItem(
            id: PracticeSkill.counting.itemPrefix + UUID().uuidString,
            prompt: "Wie viele Augen zählen diese Karten zusammen?",
            tiles: cards,
            choices: values.map { "\($0) Augen" },
            answerIndex: values.firstIndex(of: total) ?? 0,
            explanation: explanation,
            sourceLabel: "Endlos üben",
            roomID: PracticeSkill.counting.roomID,
            choiceNotes: values.map { $0 == total ? nil : wrongNote },
            isReviewable: false
        )
    }

    // MARK: - Wer sticht?

    static func randomGame<R: RandomNumberGenerator>(using generator: inout R) -> TrickGame {
        switch Int.random(in: 0..<6, using: &generator) {
        case 0: return .grand
        case 1: return .null
        default: return .suit(Suit.allCases.randomElement(using: &generator) ?? .hearts)
        }
    }

    static func trickItem<R: RandomNumberGenerator>(using generator: inout R) -> QuickItem {
        let game = randomGame(using: &generator)
        let cards = Array(deck.shuffled(using: &generator).prefix(3))
        return trickItem(game: game, cards: cards)
    }

    /// Deterministic core, so tests can feed hand-checked tricks.
    static func trickItem(game: TrickGame, cards: [PlayingCard]) -> QuickItem {
        let winner = SkatRules.winnerIndex(of: cards, in: game)
        let ordinals = ["Erste Karte", "Zweite Karte", "Dritte Karte"]
        let lineup = zip(ordinals, cards).map { "\($0): \(cardName($1))" }.joined(separator: ". ")
        let winnerCard = cards[winner]
        let tricks = game == .null ? "" : " Der Stich bringt \(SkatRules.points(in: cards)) Augen."

        let notes: [String?] = cards.indices.map { index in
            index == winner ? nil : loserNote(
                card: cards[index], winnerCard: winnerCard, game: game, leadCard: cards[0]
            )
        }
        let explanation = "\(cardName(winnerCard)) gewinnt, \(winReason(winnerCard, cards: cards, game: game)).\(tricks)"
        return QuickItem(
            id: PracticeSkill.trickWinner.itemPrefix + UUID().uuidString,
            prompt: "\(game.title): \(game.trumpDescription). \(lineup). Wer gewinnt den Stich?",
            tiles: cards,
            choices: ordinals,
            answerIndex: winner,
            explanation: explanation,
            sourceLabel: "Endlos üben",
            roomID: PracticeSkill.trickWinner.roomID,
            choiceNotes: notes,
            isReviewable: false
        )
    }

    private static func winReason(_ winner: PlayingCard, cards: [PlayingCard], game: TrickGame) -> String {
        let family = SkatRules.family(of: winner, in: game)
        if family == .trump {
            let trumps = cards.filter { SkatRules.family(of: $0, in: game) == .trump }.count
            return trumps > 1 ? "weil es der höchste Trumpf im Stich ist" : "weil es der einzige Trumpf im Stich ist"
        }
        if let lead = cards.first, case .suit(let suit) = SkatRules.family(of: lead, in: game) {
            return "weil es die höchste Karte der angespielten Farbe \(suit.displayName) ist und niemand getrumpft hat"
        }
        return "weil es die höchste Karte ist"
    }

    private static func loserNote(card: PlayingCard, winnerCard: PlayingCard, game: TrickGame, leadCard: PlayingCard) -> String {
        let mine = SkatRules.family(of: card, in: game)
        let theirs = SkatRules.family(of: winnerCard, in: game)
        if mine == .trump && theirs == .trump {
            return "\(cardName(card)) ist Trumpf, aber \(cardName(winnerCard)) ist ein höherer Trumpf."
        }
        if theirs == .trump {
            return "\(cardName(card)) ist kein Trumpf und verliert gegen den Trumpf \(cardName(winnerCard))."
        }
        if mine == SkatRules.family(of: leadCard, in: game) {
            return "\(cardName(card)) bedient die angespielte Farbe, aber \(cardName(winnerCard)) ist höher."
        }
        return "\(cardName(card)) ist weder Trumpf noch die angespielte Farbe und kann den Stich nicht gewinnen."
    }

    // MARK: - Spitzen

    static func spitzenItem<R: RandomNumberGenerator>(using generator: inout R) -> QuickItem {
        var held = Set<Suit>()
        for suit in SkatRules.jackOrder where Bool.random(using: &generator) { held.insert(suit) }
        return spitzenItem(holding: held, using: &generator)
    }

    static func spitzenItem<R: RandomNumberGenerator>(holding held: Set<Suit>, using generator: inout R) -> QuickItem {
        let truth = SkatRules.spitzen(holding: held)
        func label(mit: Bool, count: Int) -> String {
            "\(mit ? "Mit" : "Ohne") \(count), Spiel \(count + 1)"
        }
        let answer = label(mit: truth.mit, count: truth.count)

        var options: [(mit: Bool, count: Int)] = [(truth.mit, truth.count)]
        var pool: [(mit: Bool, count: Int)] = [(!truth.mit, truth.count)]
        for delta in [-1, 1] {
            let count = truth.count + delta
            if (1...4).contains(count) { pool.append((truth.mit, count)) }
        }
        pool.append((!truth.mit, max(1, min(4, truth.count + 1))))
        for option in pool.shuffled(using: &generator) where options.count < 4 {
            if !options.contains(where: { $0.mit == option.mit && $0.count == option.count }) { options.append(option) }
        }
        let shuffled = options.shuffled(using: &generator)
        let labels = shuffled.map { label(mit: $0.mit, count: $0.count) }

        let jacks = SkatRules.jackOrder.filter { held.contains($0) }.map { PlayingCard.standard(rank: 11, suit: $0) }
        let heldText = jacks.isEmpty ? "keinen Buben" : jacks.map(cardName).joined(separator: ", ")
        let runText = SkatRules.jackOrder.prefix(truth.count).map { "\($0.displayName)-Bube" }.joined(separator: ", ")
        let explanation = truth.mit
            ? "Du hältst den Kreuz-Buben, also spielst du mit. Die Reihe Kreuz, Pik, Herz, Karo hält bei \(truth.count) Buben (\(runText)), also „mit \(truth.count)“, Spiel \(truth.count + 1)."
            : "Dir fehlt der Kreuz-Bube, also spielst du ohne. Es fehlen \(truth.count) Buben in Folge von oben (\(runText)), also „ohne \(truth.count)“, Spiel \(truth.count + 1)."
        let notes: [String?] = shuffled.map { option in
            if option.mit == truth.mit && option.count == truth.count { return nil }
            if option.mit != truth.mit {
                return truth.mit
                    ? "Du hältst den Kreuz-Buben, daher gilt „mit“, nicht „ohne“."
                    : "Dir fehlt der Kreuz-Bube, daher gilt „ohne“, nicht „mit“."
            }
            return "Zähle die Buben von oben (Kreuz, Pik, Herz, Karo) bis zur ersten Lücke. Das sind \(truth.count), nicht \(option.count)."
        }
        return QuickItem(
            id: PracticeSkill.spitzen.itemPrefix + UUID().uuidString,
            prompt: "Grand, nur die Buben zählen. Du hältst \(heldText). Wie lautet die Ansage?",
            tiles: jacks,
            choices: labels,
            answerIndex: labels.firstIndex(of: answer) ?? 0,
            explanation: explanation,
            sourceLabel: "Endlos üben",
            roomID: PracticeSkill.spitzen.roomID,
            choiceNotes: notes,
            isReviewable: false
        )
    }
}
