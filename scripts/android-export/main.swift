import Foundation

// Exports the iOS content and generator fixtures for the Android port.
// Run through scripts/sync-android-content.sh, never by hand.
//
//   content.json  every authored drill, the primer, the scoring categories and
//                 the What's New notes, read by the app at runtime.
//   parity.json   classifier results, seeded generator output and the daily
//                 challenge, read only by the Android unit tests to prove the
//                 Kotlin engine classifies and deals exactly what iOS does.

func code(_ card: PlayingCard) -> String {
    switch card {
    case .standard(let rank, let suit): return "\(suit.rawValue.prefix(1).uppercased())\(rank)"
    case .joker: return "JK"
    }
}
func codes(_ cards: [PlayingCard]) -> [String] { cards.map(code) }

func flashcard(_ card: Flashcard) -> [String: Any] {
    var json: [String: Any] = [
        "id": card.id,
        "frontTitle": card.frontTitle,
        "frontTiles": codes(card.frontTiles),
        "backTitle": card.backTitle,
        "backBody": card.backBody,
    ]
    if let subtitle = card.frontSubtitle { json["frontSubtitle"] = subtitle }
    if let choice = card.choice {
        json["choice"] = ["options": choice.options, "answerIndex": choice.answerIndex]
    }
    return json
}

func quiz(_ question: QuizQuestion) -> [String: Any] {
    [
        "id": question.id,
        "prompt": question.prompt,
        "tiles": codes(question.tiles),
        "choices": question.choices,
        "answerIndex": question.answerIndex,
        "explanation": question.explanation,
    ]
}

func handMatch(_ question: HandMatchQuestion) -> [String: Any] {
    [
        "id": question.id,
        "tiles": codes(question.tiles),
        "choices": question.choices.map(\.rawValue),
        "answer": question.answer.rawValue,
        "explanation": question.explanation,
    ]
}

func discard(_ scenario: DiscardScenario) -> [String: Any] {
    [
        "id": scenario.id,
        "situation": scenario.situation,
        "deal": codes(scenario.deal),
        "recommendedDiscard": codes(scenario.recommendedDiscard),
        "reasoning": scenario.reasoning,
        "tip": scenario.tip,
    ]
}

func drill(_ drill: Drill) -> [String: Any] {
    var json: [String: Any] = [
        "id": drill.id,
        "title": drill.title,
        "subtitle": drill.subtitle,
        "isPlus": drill.isPlus,
    ]
    switch drill.kind {
    case .flashcards(let cards): json["kind"] = "flashcards"; json["items"] = cards.map(flashcard)
    case .quiz(let questions): json["kind"] = "quiz"; json["items"] = questions.map(quiz)
    case .handMatch(let questions): json["kind"] = "handMatch"; json["items"] = questions.map(handMatch)
    case .discard(let scenarios): json["kind"] = "discard"; json["items"] = scenarios.map(discard)
    }
    return json
}

func content() -> [String: Any] {
    let rooms: [[String: Any]] = DrillLibrary.rooms.map { room in
        [
            "id": room.id,
            "name": room.name,
            "tagline": room.tagline,
            "icon": room.icon,
            "isFree": room.isFree,
            "drills": room.drills.map(drill),
        ]
    }
    let categories: [[String: Any]] = HandCategory.allCases.map { category in
        [
            "id": category.rawValue,
            "displayName": category.displayName,
            "shortName": category.shortName,
            "howToSpot": category.howToSpot,
        ]
    }
    let primer: [[String: Any]] = HowToPlayContent.pages.map { page in
        var json: [String: Any] = [
            "id": page.id, "icon": page.icon, "title": page.title, "body": page.body, "tiles": codes(page.tiles),
        ]
        if let tip = page.tip { json["tip"] = tip }
        return json
    }
    // The iPad line is Apple-only; Android has no iPad layout to announce.
    let whatsNew: [[String: Any]] = WhatsNew.releases.map { release in
        [
            "version": release.version,
            "headline": release.headline,
            "items": release.items.filter { $0.id != "ipad" }.map { item in
                ["id": item.id, "icon": item.icon, "title": item.title, "body": item.body, "isPlus": item.isPlus]
            },
        ]
    }
    return [
        "rooms": rooms,
        "categories": categories,
        "primer": primer,
        "whatsNew": whatsNew,
    ]
}

// MARK: - Parity fixtures

func quickItem(_ item: QuickItem) -> [String: Any] {
    [
        "id": item.id,
        "prompt": item.prompt,
        "tiles": codes(item.tiles),
        "choices": item.choices,
        "answerIndex": item.answerIndex,
        "explanation": item.explanation,
        "sourceLabel": item.sourceLabel,
        "roomID": item.roomID,
        "trackingID": item.trackingID,
        "isReviewable": item.isReviewable,
    ]
}

func parity() -> [String: Any] {
    let seeds = ["alpha", "skat-minute-2026-09-30-hands", "card-quiz-3", "", "Grand"]
    var streams: [String: [String]] = [:]
    for seed in seeds {
        var generator = StableSeededGenerator(seed: seed)
        streams[seed] = (0..<8).map { _ in String(generator.next()) }
    }
    var permutations: [String: [Int]] = [:]
    for seed in seeds {
        for count in [2, 3, 4, 7, 13] {
            permutations["\(seed)|\(count)"] = ChoiceShuffle.permutation(count: count, seed: seed)
        }
    }

    var hands: [String: Any] = [:]
    for seed in ["h1", "h2", "daily-2026-10-01", "skat-minute-2026-10-16-hands"] {
        hands[seed] = HandGenerator.batch(count: 7, seed: seed).map { hand in
            [
                "tiles": codes(hand.tiles),
                "answer": hand.answer.rawValue,
                "choices": hand.choices.map(\.rawValue),
                "explanation": hand.explanation,
            ] as [String: Any]
        }
    }

    // Seeded random five-card layouts from the 32-card deck, classified by
    // the teaching rules, so the Kotlin classifier is held to the Swift one.
    let skatDeck: [PlayingCard] = Suit.allCases.flatMap { suit in PlayingCard.skatRanks.map { PlayingCard.standard(rank: $0, suit: suit) } }
    var classifications: [[String: Any]] = []
    var dealer = StableSeededGenerator(seed: "classifier-parity")
    for _ in 0..<400 {
        let cards = Array(skatDeck.shuffled(using: &dealer).prefix(5))
        var row: [String: Any] = [
            "cards": codes(cards),
            "fits": HandGenerator.generatableCategories.filter { HandGenerator.fits(cards, $0) }.map(\.rawValue),
        ]
        if let category = HandGenerator.category(for: cards) { row["category"] = category.rawValue }
        classifications.append(row)
    }
    var bools: [String: [Bool]] = [:]
    for seed in seeds {
        var generator = StableSeededGenerator(seed: seed)
        bools[seed] = (0..<16).map { _ in Bool.random(using: &generator) }
    }
    let valueCases: [[String: Any]] = AdvancedContent.valueCases.map { lesson in
        ["id": lesson.id, "base": lesson.base, "multiplier": lesson.multiplier, "bid": lesson.bid, "lost": lesson.lost, "expected": lesson.expected]
    }
    let planningCases: [[String: Any]] = AdvancedContent.planningCases.map { lesson in
        var row: [String: Any] = [
            "id": lesson.id,
            "hands": lesson.hands.map(codes),
            "priorEyes": lesson.priorEyes,
            "guaranteedEyes": lesson.guaranteedEyes,
        ]
        if let trump = lesson.trump { row["trump"] = trump.rawValue }
        return row
    }
    let cardFacts: [[String: Any]] = skatDeck.map { card in
        ["code": code(card), "short": card.shortLabel, "spoken": card.spokenName, "value": card.skatValue, "sortKey": card.sortKey]
    }

    var utc = Calendar(identifier: .gregorian)
    utc.timeZone = TimeZone(identifier: "UTC")!
    var minutes: [String: Any] = [:]
    for day in ["2026-09-30", "2026-10-01", "2027-01-15", "2026-02-28", "2026-10-16"] {
        let parts = day.split(separator: "-").map { Int($0)! }
        let date = utc.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2], hour: 12))!
        let challenge = SkatMinuteContent.challenge(for: date, calendar: utc)
        minutes[day] = [
            "shortDate": challenge.shortDate,
            "questions": challenge.questions.map { ["category": $0.category.rawValue, "item": quickItem($0.item)] },
        ]
    }

    let roomIDs = DrillLibrary.rooms.map(\.id)
    let memberPool = roomIDs.flatMap { SessionBuilder.choiceItems(in: $0, includePro: true) }
    let freePool = roomIDs.flatMap { SessionBuilder.choiceItems(in: $0, includePro: false) }

    return [
        "streams": streams,
        "permutations": permutations,
        "hands": hands,
        "classifications": classifications,
        "bools": bools,
        "cardFacts": cardFacts,
        "valueCases": valueCases,
        "planningCases": planningCases,
        "minutes": minutes,
        "memberPool": memberPool.map { quickItem(SessionBuilder.prepared($0)) },
        "freePoolIDs": freePool.map(\.id),
        "drillCounts": Dictionary(uniqueKeysWithValues: DrillLibrary.rooms.flatMap(\.drills).map { ($0.id, $0.kind.itemCount) }),
        "lockedDrillCount": DrillLibrary.rooms.reduce(0) { $0 + $1.plusDrillCount },
    ]
}

func write(_ object: Any, to path: String) throws {
    let data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
    try data.write(to: URL(fileURLWithPath: path))
}

let arguments = CommandLine.arguments
guard arguments.count == 3 else {
    FileHandle.standardError.write("usage: export <content.json> <parity.json>\n".data(using: .utf8)!)
    exit(2)
}
try write(content(), to: arguments[1])
try write(parity(), to: arguments[2])
