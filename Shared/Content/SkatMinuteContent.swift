import Foundation

enum SkatMinuteCategory: String, CaseIterable, Codable, Identifiable, Sendable {
    case handReading
    case druecken
    case stichspiel

    var id: String { rawValue }

    var title: String {
        switch self {
        case .handReading: return "Blattlesen"
        case .druecken: return "Druecken"
        case .stichspiel: return "Stichspiel"
        }
    }

    var icon: String {
        switch self {
        case .handReading: return "rectangle.on.rectangle.angled"
        case .druecken: return "arrow.down.circle.fill"
        case .stichspiel: return "hand.point.up.left.fill"
        }
    }
}

struct SkatMinuteQuestion: Sendable {
    let category: SkatMinuteCategory
    let item: QuickItem
}

struct SkatMinuteChallenge: Identifiable, Sendable {
    let day: Date
    let dayKey: String
    let shortDate: String
    let questions: [SkatMinuteQuestion]

    var id: String { dayKey }
    var items: [QuickItem] { questions.map(\.item) }
}

/// Ein gemeinsamer Fragensatz pro Kalendertag: zwei generierte Blattlesen, eine Drueck-Entscheidung und zwei Stichspiel-Fragen. Die Blaetter entstehen prozedural aus demselben Klassifizierer, der auch die endlose Uebung bewertet; Druecken und Stichspiel stammen aus den eigenen Lehrinhalten der App. Der Tagesschluessel ist das ganze Protokoll: kein Konto, kein Server, keine Bestenliste.
enum SkatMinuteContent {
    static let questionCount = 5

    static let drill = Drill(
        id: "skat-minute",
        title: "Skat-Minute",
        subtitle: "Die taegliche Fuenf-Fragen-Runde",
        kind: .quiz([]),
        isPlus: true
    )

    static func challenge(for day: Date = Date(), calendar: Calendar = .current) -> SkatMinuteChallenge {
        let dayKey = key(for: day, calendar: calendar)
        let generated = generatedQuestions(dayKey: dayKey)
        let middle = drueckenQuestion(dayKey: dayKey).map { [$0] } ?? []
        let last = roomQuestions(dayKey: dayKey, roomID: "pegging-room", category: .stichspiel, count: 2)

        // Interleaved so the run does not read as three separate quizzes.
        var questions: [SkatMinuteQuestion] = []
        if let first = generated.first { questions.append(first) }
        questions += middle
        if let firstLast = last.first { questions.append(firstLast) }
        if generated.count > 1 { questions.append(generated[1]) }
        if last.count > 1 { questions.append(last[1]) }

        let parts = calendar.dateComponents([.month, .day], from: day)
        let shortDate = String(format: "%02d/%02d", parts.month ?? 1, parts.day ?? 1)
        return SkatMinuteChallenge(day: day, dayKey: dayKey, shortDate: shortDate, questions: questions)
    }

    static func key(for day: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: day)
        return String(
            format: "%04d-%02d-%02d",
            parts.year ?? 1970,
            parts.month ?? 1,
            parts.day ?? 1
        )
    }

    private static func generatedQuestions(dayKey: String) -> [SkatMinuteQuestion] {
        let hands = HandGenerator.batch(count: 2, seed: "skat-minute-\(dayKey)-hands")
        return hands.enumerated().map { index, hand in
            let labels = hand.choices.map(\.displayName)
            let answerIndex = hand.choices.firstIndex(of: hand.answer) ?? 0
            let item = QuickItem(
                id: PracticeSkill.handReading.itemPrefix + "minute-\(dayKey)-\(index)",
                prompt: "Welches Spiel passt zu diesem Blatt?",
                tiles: hand.tiles,
                choices: labels,
                answerIndex: answerIndex,
                explanation: hand.explanation,
                sourceLabel: "Skat-Minute: Blattlesen",
                roomID: PracticeSkill.handReading.roomID,
                trackingID: PracticeSkill.handReading.rawValue,
                isReviewable: false
            )
            return SkatMinuteQuestion(category: .handReading, item: SessionBuilder.prepared(item))
        }
    }

    /// Built straight from the authored scenarios rather than through
    /// `SessionBuilder.choiceItems`. The quick-session pool deliberately
    /// excludes these drills because picking cards out of a hand is not a
    /// uniform choice flow, so drawing the daily from the pool silently
    /// produced a four-question challenge with this skill missing entirely.
    /// The same scenario reads fine as a labelled choice of card pairs.
    private static func drueckenQuestion(dayKey: String) -> SkatMinuteQuestion? {
        let scenarios = DrillLibrary.rooms.flatMap { room in
            room.drills.flatMap { drill -> [DiscardScenario] in
                if case .discard(let values) = drill.kind { return values }
                return []
            }
        }
        guard !scenarios.isEmpty else { return nil }

        var generator = StableSeededGenerator(seed: "skat-minute-\(dayKey)-druecken")
        let scenario = scenarios[Int(generator.next() % UInt64(scenarios.count))]
        let answer = label(scenario.recommendedDiscard)
        let distractors = distractorLabels(for: scenario, dayKey: dayKey, answer: answer)
        guard distractors.count >= 2 else { return nil }

        let item = QuickItem(
            id: "skat-minute-druecken-\(dayKey)",
            prompt: "\(scenario.situation) Welche beiden Karten drueckst du?",
            tiles: scenario.deal,
            choices: [answer] + distractors,
            answerIndex: 0,
            explanation: scenario.reasoning,
            sourceLabel: "Skat-Minute: Druecken",
            roomID: "discard-room",
            trackingID: "skat-minute-druecken",
            isReviewable: false
        )
        return SkatMinuteQuestion(category: .druecken, item: SessionBuilder.prepared(item))
    }

    /// Every other pair from the same deal, so a wrong answer is always a real
    /// alternative the player could have chosen rather than an obvious dud.
    private static func distractorLabels(
        for scenario: DiscardScenario,
        dayKey: String,
        answer: String
    ) -> [String] {
        var labels: Set<String> = []
        for first in 0..<max(0, scenario.deal.count - 1) {
            for second in (first + 1)..<scenario.deal.count {
                labels.insert(label([scenario.deal[first], scenario.deal[second]]))
            }
        }
        labels.remove(answer)
        let sorted = labels.sorted()
        let order = ChoiceShuffle.permutation(count: sorted.count, seed: "skat-minute-\(dayKey)-druecken-choices")
        return order.prefix(3).map { sorted[$0] }
    }

    private static func label(_ cards: [PlayingCard]) -> String {
        cards.map(\.spokenName).joined(separator: ", ")
    }

    /// Authored questions drawn from one room, picked by a permutation of the
    /// day key so the same date always yields the same questions for everyone.
    private static func roomQuestions(
        dayKey: String,
        roomID: String,
        category: SkatMinuteCategory,
        count: Int
    ) -> [SkatMinuteQuestion] {
        let pool = SessionBuilder.choiceItems(in: roomID, includePro: true)
        guard !pool.isEmpty else { return [] }
        let indices = ChoiceShuffle.permutation(count: pool.count, seed: "skat-minute-\(dayKey)-\(roomID)")
        return indices.prefix(count).map { index in
            SkatMinuteQuestion(category: category, item: SessionBuilder.prepared(pool[index]))
        }
    }
}
