import Foundation

/// One normalized, single-select item inside a mixed session.
struct QuickItem: Identifiable, Sendable {
    let id: String
    let prompt: String
    let tiles: [PlayingCard]
    let choices: [String]
    let answerIndex: Int
    let explanation: String
    let sourceLabel: String
    let roomID: String
    /// The persistence row this answer contributes to. Most authored items use
    /// their own id. Procedural daily items can share one bounded rollup row.
    let trackingID: String
    /// False for one-off generated prompts that can never be scheduled back
    /// into Fix My Mistakes.
    let isReviewable: Bool

    init(
        id: String,
        prompt: String,
        tiles: [PlayingCard],
        choices: [String],
        answerIndex: Int,
        explanation: String,
        sourceLabel: String,
        roomID: String,
        trackingID: String? = nil,
        isReviewable: Bool = true
    ) {
        self.id = id
        self.prompt = prompt
        self.tiles = tiles
        self.choices = choices
        self.answerIndex = answerIndex
        self.explanation = explanation
        self.sourceLabel = sourceLabel
        self.roomID = roomID
        self.trackingID = trackingID ?? id
        self.isReviewable = isReviewable
    }
}

/// Builds the mixed session from choice-gradeable material. Plain reference
/// cards and dedicated two-card decisions stay in their own interactions.
enum SessionBuilder {
    static let sessionDrill = Drill(
        id: "quick-session",
        title: "Kurzrunde",
        subtitle: "Ein kurzer Mix für deinen nächsten Schritt",
        kind: .flashcards([])
    )

    static let reviewDrill = Drill(
        id: "review-session",
        title: "Fehler wiederholen",
        subtitle: "Fragen, die du noch nicht sicher hast",
        kind: .flashcards([])
    )

    static let gameNightPrepDrill = Drill(
        id: "game-night-prep",
        title: "Skatabend-Vorbereitung",
        subtitle: "Eine Fünf-Minuten-Mischung für deinen nächsten Tisch",
        kind: .flashcards([])
    )

    static func quickSession(count: Int = 10, seen: Set<String>, missed: Set<String>, includePro: Bool) -> [QuickItem] {
        let pool = choicePool(includePro: includePro)

        func tier(_ item: QuickItem) -> Int {
            if missed.contains(item.id) { return 0 }
            if !seen.contains(item.id) { return 1 }
            return 2
        }

        let picked = Dictionary(grouping: pool.shuffled(), by: tier)
            .sorted { $0.key < $1.key }
            .flatMap(\.value)
            .prefix(count)
        return picked.map(prepared)
    }

    static func reviewSession(ids: [String], includePro: Bool) -> [QuickItem] {
        let pool = Dictionary(choicePool(includePro: includePro).map { ($0.id, $0) }) { first, _ in first }
        return ids.compactMap { pool[$0] }.map(prepared)
    }

    /// A member's pre-game session. Due mistakes lead, then the weakest room,
    /// then unseen material. The final tier keeps the session full for a new
    /// player who has not built enough history to personalize yet.
    static func gameNightPrep(
        count: Int = 10,
        seen: Set<String>,
        missed: Set<String>,
        dueIDs: [String],
        weakestRoomID: String?
    ) -> [QuickItem] {
        let due = Set(dueIDs)
        let pool = choicePool(includePro: true)

        func tier(_ item: QuickItem) -> Int {
            if due.contains(item.id) { return 0 }
            if missed.contains(item.id) { return 1 }
            if item.roomID == weakestRoomID { return 2 }
            if !seen.contains(item.id) { return 3 }
            return 4
        }

        return Dictionary(grouping: pool.shuffled(), by: tier)
            .sorted { $0.key < $1.key }
            .flatMap(\.value)
            .prefix(count)
            .map(prepared)
    }

    /// Used by deterministic daily features to draw from a particular room
    /// without exposing locked content to callers that did not request it.
    static func choiceItems(in roomID: String, includePro: Bool) -> [QuickItem] {
        choicePool(includePro: includePro).filter { $0.roomID == roomID }
    }

    static func prepared(_ item: QuickItem) -> QuickItem {
        let shuffled = ChoiceShuffle.shuffledChoices(labels: item.choices, answerIndex: item.answerIndex, seed: item.id)
        return QuickItem(
            id: item.id,
            prompt: item.prompt,
            tiles: item.tiles,
            choices: shuffled.labels,
            answerIndex: shuffled.answerIndex,
            explanation: item.explanation,
            sourceLabel: item.sourceLabel,
            roomID: item.roomID,
            trackingID: item.trackingID,
            isReviewable: item.isReviewable
        )
    }

    private static func choicePool(includePro: Bool) -> [QuickItem] {
        var pool: [QuickItem] = []
        for room in DrillLibrary.rooms where room.isFree || includePro {
            for drill in room.drills where !room.isLocked(drill, isMember: includePro) {
                switch drill.kind {
                case .quiz(let questions):
                    pool += questions.map { question in
                        QuickItem(
                            id: question.id,
                            prompt: question.prompt,
                            tiles: question.tiles,
                            choices: question.choices,
                            answerIndex: question.answerIndex,
                            explanation: question.explanation,
                            sourceLabel: room.name,
                            roomID: room.id
                        )
                    }
                case .handMatch(let questions):
                    pool += questions.map { question in
                        let labels = question.choices.map(\.displayName)
                        let answerIndex = question.choices.firstIndex(of: question.answer) ?? 0
                        return QuickItem(
                            id: question.id,
                            prompt: "Welche Struktur fällt dir zuerst auf?",
                            tiles: question.tiles.racked,
                            choices: labels,
                            answerIndex: answerIndex,
                            explanation: question.explanation,
                            sourceLabel: room.name,
                            roomID: room.id
                        )
                    }
                case .flashcards(let cards):
                    pool += cards.compactMap { card in
                        guard let choice = card.choice else { return nil }
                        var prompt = card.frontTitle
                        if let subtitle = card.frontSubtitle { prompt += "\n\(subtitle)" }
                        return QuickItem(
                            id: card.id,
                            prompt: prompt,
                            tiles: card.frontTiles,
                            choices: choice.options,
                            answerIndex: choice.answerIndex,
                            explanation: card.backBody,
                            sourceLabel: room.name,
                            roomID: room.id
                        )
                    }
                case .discard:
                    break
                }
            }
        }
        return pool
    }
}
