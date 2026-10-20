import XCTest
@testable import SkatTrainer

/// Generated answers are checked against a second, independent statement of
/// the Skat card order (explicit ranked lists of short codes), never against
/// the same helpers the generator uses.
final class GeneratedPracticeTests: XCTestCase {
    // MARK: - Independent oracle

    private func code(_ card: PlayingCard) -> String {
        guard case .standard(let rank, let suit) = card else { return "?" }
        let s = ["clubs": "C", "spades": "S", "hearts": "H", "diamonds": "D"][suit.rawValue] ?? "?"
        let r = [7: "7", 8: "8", 9: "9", 10: "T", 11: "J", 12: "Q", 13: "K", 14: "A"][rank] ?? "?"
        return r + s
    }

    /// Trump cards, highest first.
    private func trumpList(_ game: TrickGame) -> [String] {
        let jacks = ["JC", "JS", "JH", "JD"]
        switch game {
        case .null: return []
        case .grand: return jacks
        case .suit(let suit):
            let s = ["clubs": "C", "spades": "S", "hearts": "H", "diamonds": "D"][suit.rawValue] ?? "?"
            return jacks + ["A", "T", "K", "Q", "9", "8", "7"].map { $0 + s }
        }
    }

    private func sideList(_ game: TrickGame, suitCode: String) -> [String] {
        let ranks = game == .null ? ["A", "K", "Q", "J", "T", "9", "8", "7"] : ["A", "T", "K", "Q", "9", "8", "7"]
        return ranks.map { $0 + suitCode }
    }

    private func oracleWinner(_ trick: [PlayingCard], _ game: TrickGame) -> Int {
        let codes = trick.map(code)
        let trumps = trumpList(game)
        let played = codes.enumerated().filter { trumps.contains($0.element) }
        if let best = played.min(by: { trumps.firstIndex(of: $0.element)! < trumps.firstIndex(of: $1.element)! }) {
            return best.offset
        }
        let ledSuit = String(codes[0].suffix(1))
        let side = sideList(game, suitCode: ledSuit)
        return codes.enumerated().filter { side.contains($0.element) }
            .min(by: { side.firstIndex(of: $0.element)! < side.firstIndex(of: $1.element)! })!.offset
    }

    private var games: [TrickGame] { [.grand, .null] + Suit.allCases.map { TrickGame.suit($0) } }

    // MARK: - Trick resolution

    func testHandCheckedTricks() {
        XCTAssertEqual(SkatRules.winnerIndex(of: [.s(14), .h(7), .c(9)], in: .suit(.hearts)), 1, "Herz 7 is trump and beats Pik Ass")
        XCTAssertEqual(SkatRules.winnerIndex(of: [.d(11), .h(14), .c(11)], in: .suit(.hearts)), 2, "Kreuz-Bube is the top trump")
        XCTAssertEqual(SkatRules.winnerIndex(of: [.h(14), .h(10), .d(11)], in: .grand), 2, "Buben are trump in Grand")
        XCTAssertEqual(SkatRules.winnerIndex(of: [.h(10), .h(14), .s(14)], in: .grand), 1, "Pik Ass is off suit")
        XCTAssertEqual(SkatRules.winnerIndex(of: [.h(11), .h(10), .h(12)], in: .null), 2, "Null: Dame beats Bube beats Zehn")
        XCTAssertEqual(SkatRules.winnerIndex(of: [.h(10), .h(11), .s(14)], in: .null), 1, "Null: Bube beats Zehn, off-suit Ass loses")
        XCTAssertEqual(SkatRules.winnerIndex(of: [.s(13), .s(10), .s(12)], in: .suit(.hearts)), 1, "Zehn beats König")
        XCTAssertEqual(SkatRules.winnerIndex(of: [.s(13), .c(14), .d(14)], in: .suit(.hearts)), 0, "Nobody follows or trumps")
        XCTAssertEqual(SkatRules.winnerIndex(of: [.h(14), .s(11), .h(10)], in: .suit(.diamonds)), 1, "A Bube trumps a Herz lead in a Karo game")
    }

    func testWinnerMatchesIndependentOracleForEveryTrickShape() {
        var generator = StableSeededGenerator(seed: "oracle-tricks")
        let deck = Suit.allCases.flatMap { suit in PlayingCard.skatRanks.map { PlayingCard.standard(rank: $0, suit: suit) } }
        for game in games {
            for _ in 0..<600 {
                let trick = Array(deck.shuffled(using: &generator).prefix(3))
                XCTAssertEqual(SkatRules.winnerIndex(of: trick, in: game), oracleWinner(trick, game),
                               "\(game.title): \(trick.map(code))")
            }
        }
    }

    // MARK: - Generated items

    func testGeneratedTrickItemsAgreeWithOracleAndCoachEveryMiss() {
        var generator = StableSeededGenerator(seed: "trick-items")
        for _ in 0..<400 {
            let item = PracticeGenerators.trickItem(using: &generator)
            XCTAssertEqual(item.tiles.count, 3)
            XCTAssertEqual(Set(item.tiles).count, 3, "A card cannot be played twice")
            XCTAssertEqual(item.choices.count, 3)
            XCTAssertEqual(item.choiceNotes.count, 3)
            let announced = games.first { item.prompt.hasPrefix($0.title) }
            XCTAssertNotNil(announced)
            if let announced { XCTAssertEqual(item.answerIndex, oracleWinner(item.tiles, announced)) }
            for (index, note) in item.choiceNotes.enumerated() {
                XCTAssertEqual(note == nil, index == item.answerIndex)
            }
            assertTextClean(item)
        }
    }

    func testTrickItemUsesTheGameItAnnounces() {
        for game in games {
            let item = PracticeGenerators.trickItem(game: game, cards: [.h(14), .s(11), .c(9)])
            XCTAssertTrue(item.prompt.hasPrefix(game.title))
            XCTAssertEqual(item.answerIndex, oracleWinner(item.tiles, game))
        }
    }

    func testCountingMatchesCardValueTable() {
        let table = [7: 0, 8: 0, 9: 0, 10: 10, 11: 2, 12: 3, 13: 4, 14: 11]
        for _ in 0..<300 {
            var generator = SystemRandomNumberGenerator()
            let item = PracticeGenerators.countingItem(using: &generator)
            let expected = item.tiles.reduce(0) { $0 + (table[$1.rankValue] ?? -1000) }
            XCTAssertEqual(item.choices[item.answerIndex], "\(expected) Augen")
            XCTAssertEqual(Set(item.choices).count, item.choices.count)
            XCTAssertEqual(Set(item.tiles).count, item.tiles.count)
            XCTAssertTrue((3...5).contains(item.tiles.count))
            XCTAssertTrue(item.choices.allSatisfy { !$0.hasPrefix("-") })
            assertTextClean(item)
        }
        XCTAssertEqual(table.values.reduce(0, +) * 4, 120, "A full deck holds 120 Augen")
    }

    func testSpitzenHandCheckedCases() {
        func result(_ suits: Set<Suit>) -> String {
            let r = SkatRules.spitzen(holding: suits)
            return "\(r.mit ? "mit" : "ohne") \(r.count)"
        }
        XCTAssertEqual(result([.clubs, .spades]), "mit 2")
        XCTAssertEqual(result([.clubs, .hearts]), "mit 1")
        XCTAssertEqual(result([.spades, .hearts, .diamonds]), "ohne 1")
        XCTAssertEqual(result([.hearts, .diamonds]), "ohne 2")
        XCTAssertEqual(result([.diamonds]), "ohne 3")
        XCTAssertEqual(result([]), "ohne 4")
        XCTAssertEqual(result(Set(Suit.allCases)), "mit 4")
        XCTAssertEqual(result([.clubs, .spades, .hearts]), "mit 3")
    }

    func testGeneratedSpitzenItemsHaveExactlyOneCorrectChoice() {
        var generator = StableSeededGenerator(seed: "spitzen")
        for _ in 0..<300 {
            let item = PracticeGenerators.spitzenItem(using: &generator)
            let held = Set(item.tiles.compactMap(\.suit))
            let truth = SkatRules.spitzen(holding: held)
            let correct = item.choices.filter { $0.hasPrefix(truth.mit ? "Mit \(truth.count)," : "Ohne \(truth.count),") }
            XCTAssertEqual(correct.count, 1)
            XCTAssertEqual(item.choices[item.answerIndex], correct.first)
            XCTAssertEqual(Set(item.choices).count, item.choices.count)
            XCTAssertGreaterThanOrEqual(item.choices.count, 3)
            XCTAssertTrue(item.choices[item.answerIndex].hasSuffix("Spiel \(truth.count + 1)"))
            XCTAssertTrue(item.tiles.allSatisfy(\.isJack))
            assertTextClean(item)
        }
    }

    // MARK: - Hand reads

    func testVariedHandsNoLongerRepeatForNullAndStich() {
        for target in [HandCategory.nullspiel, .stich, .farbe, .trumpf] {
            var seen = Set<[PlayingCard]>()
            for _ in 0..<80 {
                guard let hand = HandGenerator.hand(for: target) else { return XCTFail("no hand for \(target)") }
                XCTAssertEqual(HandGenerator.category(for: hand.tiles), target)
                seen.insert(hand.tiles)
            }
            XCTAssertGreaterThan(seen.count, 15, "\(target.displayName) should vary")
        }
    }

    func testSeededHandsStayReproducible() {
        let first = HandGenerator.batch(count: 6, seed: "skat-minute-2026-10-20-hands")
        let second = HandGenerator.batch(count: 6, seed: "skat-minute-2026-10-20-hands")
        XCTAssertEqual(first.map(\.tiles), second.map(\.tiles))
        XCTAssertEqual(first.map(\.choices), second.map(\.choices))
    }

    func testHandMissNotesNameTheRealCount() {
        for _ in 0..<150 {
            guard let hand = HandGenerator.batch(count: 1).first else { continue }
            let jacks = hand.tiles.filter(\.isJack).count
            for choice in hand.choices where choice != hand.answer {
                let note = HandGenerator.missNote(for: hand.tiles, picked: choice)
                XCTAssertFalse(note.isEmpty)
                XCTAssertFalse(note.contains("\u{2014}"))
                if choice == .grand {
                    XCTAssertTrue(note.contains(jacks == 1 ? "1 Buben" : "\(jacks) Buben"), note)
                }
            }
        }
    }

    // MARK: - Plumbing

    func testChoiceNotesTravelWithTheirChoicesWhenShuffled() {
        let item = QuickItem(
            id: "note-order", prompt: "p", tiles: [],
            choices: ["a", "b", "c", "d"], answerIndex: 0, explanation: "e",
            sourceLabel: "s", roomID: "card-room",
            choiceNotes: [nil, "note-b", "note-c", "note-d"]
        )
        let prepared = SessionBuilder.prepared(item)
        XCTAssertEqual(prepared.choiceNotes.count, 4)
        for (index, label) in prepared.choices.enumerated() {
            XCTAssertEqual(prepared.choiceNotes[index], label == "a" ? nil : "note-\(label)")
        }
    }

    func testEverySkillGeneratesAndKeepsItsRoomAndPrefix() {
        for skill in PracticeSkill.allCases {
            XCTAssertNotNil(DrillLibrary.room(id: skill.roomID))
            let items = EndlessPractice.items(for: skill, count: 12)
            XCTAssertEqual(items.count, 12)
            for item in items {
                XCTAssertEqual(PracticeSkill.skill(forItemID: item.id), skill)
                XCTAssertEqual(item.roomID, skill.roomID)
                XCTAssertTrue((0..<item.choices.count).contains(item.answerIndex))
                XCTAssertEqual(item.choiceNotes.count, item.choices.count, "\(skill.rawValue) must coach every miss")
            }
        }
    }

    func testTimedMixCoversNewSkillsToo() {
        let items = EndlessPractice.mixedItems(count: 120)
        XCTAssertEqual(Set(items.compactMap { PracticeSkill.skill(forItemID: $0.id) }), Set(PracticeSkill.allCases))
    }

    // MARK: - Mastery

    @MainActor
    func testMasteryNeedsTwoInARowAndIgnoresLockedSets() {
        let defaults = UserDefaults(suiteName: "MasteryTests")!
        defaults.removePersistentDomain(forName: "MasteryTests")
        defer { defaults.removePersistentDomain(forName: "MasteryTests") }
        let store = PracticeRecordStore(defaults: defaults)
        let room = DrillLibrary.rooms[0]
        let free = PracticeRecordStore.trackableItemIDs(in: room, isMember: false)
        let member = PracticeRecordStore.trackableItemIDs(in: room, isMember: true)
        XCTAssertFalse(free.isEmpty)
        XCTAssertGreaterThanOrEqual(member.count, free.count)

        let id = free[0]
        store.record(itemID: id, roomID: room.id, correct: true)
        XCTAssertEqual(store.mastery(for: room, isMember: false).known, 0, "One right answer is not mastery")
        XCTAssertEqual(store.mastery(for: room, isMember: false).level, .learning)
        store.record(itemID: id, roomID: room.id, correct: true)
        XCTAssertEqual(store.mastery(for: room, isMember: false).known, 1)
        store.record(itemID: id, roomID: room.id, correct: false)
        XCTAssertEqual(store.mastery(for: room, isMember: false).known, 0, "A miss breaks the streak")
    }

    func testMasteryLevelThresholds() {
        XCTAssertEqual(MasteryLevel.level(known: 0, total: 10), .untouched)
        XCTAssertEqual(MasteryLevel.level(known: 0, total: 10, attempted: 2), .learning)
        XCTAssertEqual(MasteryLevel.level(known: 3, total: 10), .learning)
        XCTAssertEqual(MasteryLevel.level(known: 4, total: 10), .solid)
        XCTAssertEqual(MasteryLevel.level(known: 9, total: 10), .sharp)
    }

    func testKnownItemLapsesOnlyAFullIntervalPastDue() {
        var record = PracticeRecord()
        record.streak = 2
        record.intervalDays = 3
        record.dueDate = Date(timeIntervalSince1970: 0)
        XCTAssertTrue(record.isKnown(now: Date(timeIntervalSince1970: 86_400 * 2)))
        XCTAssertFalse(record.isKnown(now: Date(timeIntervalSince1970: 86_400 * 4)))
    }

    // MARK: - Helpers

    private func assertTextClean(_ item: QuickItem, file: StaticString = #filePath, line: UInt = #line) {
        let all = ([item.prompt, item.explanation] + item.choices + item.choiceNotes.compactMap { $0 }).joined()
        XCTAssertFalse(all.contains("\u{2014}"), "No em dash in visible text", file: file, line: line)
        XCTAssertFalse(item.explanation.isEmpty, file: file, line: line)
    }
}
