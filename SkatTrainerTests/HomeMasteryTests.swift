import XCTest
@testable import SkatTrainer

/// Home's ledger write, driven through a real membership change (state
/// machine audit 2026-11-06, B4). Fails if Home goes back to counting in
/// the membership's scope or to skipping the write.
@MainActor
final class HomeMasteryTests: XCTestCase {
    private let day: TimeInterval = 86_400
    private let overrideKey = "subscription.localProOverride"
    private var savedOverride: Any?
    private var ledgerDefaults: UserDefaults!
    private var recordDefaults: UserDefaults!
    private var ledger: MasteryLedger!
    private var records: PracticeRecordStore!
    private var subscriptions: SubscriptionService { SubscriptionService.shared }

    override func setUp() {
        super.setUp()
        savedOverride = UserDefaults.standard.object(forKey: overrideKey)
        ledgerDefaults = UserDefaults(suiteName: "HomeMasteryTests.ledger")!
        ledgerDefaults.removePersistentDomain(forName: "HomeMasteryTests.ledger")
        recordDefaults = UserDefaults(suiteName: "HomeMasteryTests.records")!
        recordDefaults.removePersistentDomain(forName: "HomeMasteryTests.records")
        ledger = MasteryLedger(defaults: ledgerDefaults)
        records = PracticeRecordStore(defaults: recordDefaults)
    }

    override func tearDown() {
        subscriptions.setLocalOverride(isPro: (savedOverride as? Bool) ?? false)
        if savedOverride == nil { UserDefaults.standard.removeObject(forKey: overrideKey) }
        ledgerDefaults.removePersistentDomain(forName: "HomeMasteryTests.ledger")
        recordDefaults.removePersistentDomain(forName: "HomeMasteryTests.records")
        super.tearDown()
    }

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

    private func homeRecords(at date: Date) {
        HomeView.recordMastery(records: records, subscriptions: subscriptions, ledger: ledger, now: date)
    }

    /// Five Skat+ questions known as a member. The member lapses and opens
    /// Home three days ago, re-subscribes and opens Home today, with nothing
    /// answered in between: no gain.
    func testALapseAndReturnInventsNoGain() throws {
        let (room, ids) = try skatPlusQuestions()
        let now = Date()
        for offset in [-20.0, -19.0, -16.0, -8.0] {
            for id in ids {
                records.record(itemID: id, roomID: room, correct: true, now: now.addingTimeInterval(offset * day))
            }
        }
        XCTAssertEqual(records.masteryByRoom(isMember: true, now: now).reduce(0) { $0 + $1.known }, 5,
                       "precondition: the five count as known for a member")
        XCTAssertEqual(records.masteryByRoom(isMember: false, now: now).reduce(0) { $0 + $1.known }, 0,
                       "precondition: the free scope leaves them out")

        subscriptions.setLocalOverride(isPro: false)
        XCTAssertFalse(subscriptions.isPro, "precondition: lapsed")
        homeRecords(at: now.addingTimeInterval(-3 * day))
        subscriptions.setLocalOverride(isPro: true)
        XCTAssertTrue(subscriptions.isPro, "precondition: back as a member")
        homeRecords(at: now)

        XCTAssertNil(ledger.weeklyGain(now: now))
    }

    /// Answering still shows as gain, Skat+ items included.
    func testAnsweringStillCountsAsGain() throws {
        let (room, ids) = try skatPlusQuestions()
        let now = Date()
        subscriptions.setLocalOverride(isPro: true)
        homeRecords(at: now.addingTimeInterval(-3 * day))
        for id in ids {
            records.record(itemID: id, roomID: room, correct: true, now: now.addingTimeInterval(-1 * day))
            records.record(itemID: id, roomID: room, correct: true, now: now)
        }
        homeRecords(at: now)
        XCTAssertEqual(ledger.weeklyGain(now: now), 5)
    }
}
