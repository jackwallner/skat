import Foundation

/// Generated practice skills. Both skills become the same QuickItem shape as
/// authored choice drills, so the runner can stay simple.
enum PracticeSkill: String, CaseIterable, Identifiable, Sendable {
    case handReading
    case trickPlay
    case counting
    case trickWinner
    case spitzen

    var id: String { rawValue }

    var title: String {
        switch self {
        case .handReading: return "Handmuster lesen"
        case .trickPlay: return "Stichspiel üben"
        case .counting: return "Augen zählen"
        case .trickWinner: return "Wer sticht?"
        case .spitzen: return "Spitzen zählen"
        }
    }

    var subtitle: String {
        switch self {
        case .handReading: return "Frische Kartenmuster, unbegrenzt"
        case .trickPlay: return "Bedienpflicht und Stichentscheidung"
        case .counting: return "Zähle Karte für Karte, wie am Tisch"
        case .trickWinner: return "Trumpf, Farbe und Null im Dreierstich"
        case .spitzen: return "Mit oder ohne, Spiel eins bis fünf"
        }
    }

    var icon: String {
        switch self {
        case .handReading: return "rectangle.portrait.on.rectangle.portrait.angled"
        case .trickPlay: return "arrow.up.right.circle.fill"
        case .counting: return "plus.forwardslash.minus"
        case .trickWinner: return "rosette"
        case .spitzen: return "crown.fill"
        }
    }

    var roomID: String {
        switch self {
        case .handReading: return "scoring-room"
        case .trickPlay, .trickWinner: return "pegging-room"
        case .counting: return "card-room"
        case .spitzen: return "scoring-room"
        }
    }

    var itemPrefix: String { "gen-\(rawValue)-" }

    static func skill(forItemID id: String) -> PracticeSkill? {
        allCases.first { id.hasPrefix($0.itemPrefix) }
    }
}

enum EndlessPractice {
    static func drill(for skill: PracticeSkill) -> Drill {
        Drill(id: "endless-\(skill.rawValue)", title: skill.title, subtitle: skill.subtitle, kind: .quiz([]))
    }

    static let challengeDrill = Drill(
        id: "timed-challenge",
        title: "Zeitprüfung",
        subtitle: "90 Sekunden, so viele sichere Entscheidungen wie möglich",
        kind: .quiz([])
    )

    static func items(for skill: PracticeSkill, count: Int) -> [QuickItem] {
        switch skill {
        case .handReading: return handItems(count: count)
        case .trickPlay: return trickItems(count: count)
        case .counting: return generated(count) { PracticeGenerators.countingItem(using: &$0) }
        case .trickWinner: return generated(count) { PracticeGenerators.trickItem(using: &$0) }
        case .spitzen: return generated(count) { PracticeGenerators.spitzenItem(using: &$0) }
        }
    }

    static func mixedItems(count: Int) -> [QuickItem] {
        let skills = PracticeSkill.allCases
        let perSkill = max(1, count / skills.count + 1)
        return skills.flatMap { items(for: $0, count: perSkill) }.shuffled().prefix(count).map { $0 }
    }

    private static func generated(_ count: Int, _ make: (inout SystemRandomNumberGenerator) -> QuickItem) -> [QuickItem] {
        var generator = SystemRandomNumberGenerator()
        return (0..<count).map { _ in make(&generator) }
    }

    private static func handItems(count: Int) -> [QuickItem] {
        HandGenerator.batch(count: count).map { hand in
            let labels = hand.choices.map(\.displayName)
            let answerIndex = hand.choices.firstIndex(of: hand.answer) ?? 0
            return QuickItem(
                id: PracticeSkill.handReading.itemPrefix + UUID().uuidString,
                prompt: "Welche Struktur fällt dir zuerst auf?",
                tiles: hand.tiles,
                choices: labels,
                answerIndex: answerIndex,
                explanation: hand.explanation,
                sourceLabel: "Endlos üben",
                roomID: PracticeSkill.handReading.roomID,
                choiceNotes: hand.choices.map { $0 == hand.answer ? nil : HandGenerator.missNote(for: hand.tiles, picked: $0) },
                isReviewable: false
            )
        }
    }

    private static func trickItems(count: Int) -> [QuickItem] {
        var items: [QuickItem] = []
        while items.count < count {
            let lead = Suit.allCases.randomElement() ?? .hearts
            // Never deal a Bube here. This drill decides Bedienpflicht purely
            // by comparing printed suits, and in a Farbspiel or Grand a Bube is
            // TRUMP, not a member of the suit printed on it. Holding only the
            // Herz-Bube when Herz is led means you cannot follow Herz at all,
            // which is the exact opposite of what a printed-suit comparison
            // would conclude. Excluding Buben keeps every generated question
            // true in a Farbspiel, a Grand and a Null alike.
            let card = PlayingCard.standard(
                rank: PlayingCard.skatRanks.filter { $0 != 11 }.randomElement() ?? 10,
                suit: Suit.allCases.randomElement() ?? .clubs
            )
            let follows = card.suit == lead
            let choices: [String]
            let answerIndex: Int
            let explanation: String
            if follows {
                choices = ["Die angespielte Farbe bedienen", "Eine andere Farbe spielen", "Ohne Grund trumpfen"]
                answerIndex = 0
                explanation = "Du hältst \(card.spokenName), also eine Karte der angespielten Farbe \(lead.displayName). Die Bedienpflicht geht vor."
            } else {
                choices = ["Eine Karte deiner Wahl spielen", "Die angespielte Farbe bedienen", "Den Stich neu geben lassen"]
                answerIndex = 0
                explanation = "\(card.spokenName) gehört nicht zur angespielten Farbe \(lead.displayName). Wenn du die Farbe nicht bedienen kannst, darfst du frei wählen."
            }
            // Written answer-first, so shuffle or the right row is always the top one.
            items.append(SessionBuilder.prepared(QuickItem(
                id: PracticeSkill.trickPlay.itemPrefix + UUID().uuidString,
                prompt: "Angespielte Farbe: \(lead.displayName). Du hältst \(card.spokenName). Was ist richtig?",
                tiles: [card],
                choices: choices,
                answerIndex: answerIndex,
                explanation: explanation,
                sourceLabel: "Endlos üben",
                roomID: PracticeSkill.trickPlay.roomID,
                choiceNotes: choices.indices.map { $0 == answerIndex ? nil : trickMissNote(follows: follows, lead: lead, card: card) },
                isReviewable: false
            )))
        }
        return items
    }

    private static func trickMissNote(follows: Bool, lead: Suit, card: PlayingCard) -> String {
        if follows {
            return "Du hältst \(card.spokenName) und kannst \(lead.displayName) bedienen. Dann darfst du keine andere Farbe wählen."
        }
        return "Du hältst keine \(lead.displayName)-Karte, also gibt es nichts zu bedienen. Du darfst jede Karte spielen."
    }
}
