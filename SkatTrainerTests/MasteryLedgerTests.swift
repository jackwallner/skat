import XCTest
@testable import SkatTrainer

@MainActor
final class MasteryLedgerTests: XCTestCase {
    private var ledger: MasteryLedger!
    private let day: TimeInterval = 86_400

    override func setUp() {
        super.setUp()
        let defaults = UserDefaults(suiteName: "MasteryLedgerTests")!
        defaults.removePersistentDomain(forName: "MasteryLedgerTests")
        ledger = MasteryLedger(defaults: defaults)
    }

    private func mastery(_ known: [String: Int]) -> [RoomMastery] {
        known.map { RoomMastery(roomID: $0.key, known: $0.value, total: 40, level: .learning) }
    }

    func testNoGainWithoutABaselineDay() {
        let now = Date()
        ledger.record(mastery(["card-room": 5]), now: now)
        XCTAssertNil(ledger.weeklyGain(now: now), "the first day has nothing to measure from")
    }

    func testGainIsMeasuredFromTheOldestDayInTheWindow() {
        let now = Date()
        ledger.record(mastery(["card-room": 5]), now: now.addingTimeInterval(-6 * day))
        ledger.record(mastery(["card-room": 9]), now: now.addingTimeInterval(-3 * day))
        ledger.record(mastery(["card-room": 12, "scoring-room": 4]), now: now)
        XCTAssertEqual(ledger.weeklyGain(now: now), 11)
        XCTAssertEqual(ledger.strongestRoom(now: now)?.roomID, "card-room")
        XCTAssertEqual(ledger.strongestRoom(now: now)?.gain, 7)
    }

    func testEntriesOlderThanTheWindowAreNotTheBaseline() {
        let now = Date()
        ledger.record(mastery(["card-room": 0]), now: now.addingTimeInterval(-30 * day))
        ledger.record(mastery(["card-room": 20]), now: now.addingTimeInterval(-2 * day))
        ledger.record(mastery(["card-room": 22]), now: now)
        XCTAssertEqual(ledger.weeklyGain(now: now), 2)
    }

    func testBackwardsWeeksAreReportedAsNothing() {
        let now = Date()
        ledger.record(mastery(["card-room": 20]), now: now.addingTimeInterval(-4 * day))
        ledger.record(mastery(["card-room": 15]), now: now)
        XCTAssertNil(ledger.weeklyGain(now: now))
    }

    func testSameDayRecordsOverwrite() {
        let now = Date()
        ledger.record(mastery(["card-room": 3]), now: now.addingTimeInterval(-1 * day))
        ledger.record(mastery(["card-room": 4]), now: now)
        ledger.record(mastery(["card-room": 8]), now: now)
        XCTAssertEqual(ledger.weeklyGain(now: now), 5)
        XCTAssertEqual(ledger.days.count, 2)
    }

    func testPersistsAcrossInstances() {
        let defaults = UserDefaults(suiteName: "MasteryLedgerTests")!
        let now = Date()
        ledger.record(mastery(["card-room": 3]), now: now.addingTimeInterval(-1 * day))
        ledger.record(mastery(["card-room": 9]), now: now)
        let reloaded = MasteryLedger(defaults: defaults)
        XCTAssertEqual(reloaded.weeklyGain(now: now), 6)
    }

    // MARK: - Skat+ items count (state machine audit 2026-11-06, B4)

    private func skatPlusQuestions() throws -> (room: String, ids: [String]) {
        let room = try XCTUnwrap(DrillLibrary.rooms.first { $0.id == "card-room" })
        let drill = try XCTUnwrap(room.drills.first(where: \.isPlus), "card-room has a Skat+ drill")
        guard case .quiz(let questions) = drill.kind else {
            throw XCTSkip("card-room's Skat+ drill is not a quiz")
        }
        let ids = Array(questions.prefix(5).map(\.id))
        XCTAssertEqual(ids.count, 5, "precondition: five Skat+ questions")
        return (room.id, ids)
    }

    /// Practice still shows as gain, Skat+ items included.
    func testAnsweringStillCountsAsGain() throws {
        let (room, ids) = try skatPlusQuestions()
        let now = Date()
        let suite = "MasteryLedgerTests.records"
        let recordDefaults = UserDefaults(suiteName: suite)!
        recordDefaults.removePersistentDomain(forName: suite)
        defer { recordDefaults.removePersistentDomain(forName: suite) }
        let records = PracticeRecordStore(defaults: recordDefaults)
        ledger.record(from: records, now: now.addingTimeInterval(-3 * day))
        for id in ids {
            records.record(itemID: id, roomID: room, correct: true, now: now.addingTimeInterval(-1 * day))
            records.record(itemID: id, roomID: room, correct: true, now: now)
        }
        ledger.record(from: records, now: now)
        XCTAssertEqual(ledger.weeklyGain(now: now), 5)
    }
}
