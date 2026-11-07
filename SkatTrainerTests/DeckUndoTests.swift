import XCTest
@testable import SkatTrainer

/// The deck's undo button ("Letzte Antwort zurücknehmen") takes the answer
/// back, not only the card (state machine audit 2026-11-06, B1 and P8).
/// The deck takes an `AnswerSnapshot` before each answer and restores it on
/// undo; these tests run that pair against injected stores.
@MainActor
final class DeckUndoTests: XCTestCase {
    private let suite = "DeckUndoTests"
    private var defaults: UserDefaults!
    private var progress: ProgressStore!
    private var records: PracticeRecordStore!
    private let room = "card-room"
    private let card = "deck-card"

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        progress = ProgressStore(defaults: defaults)
        records = PracticeRecordStore(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
        super.tearDown()
    }

    /// What the deck does for one graded card: snapshot, then record.
    private func answer(_ correct: Bool, now: Date = Date()) -> AnswerSnapshot {
        let snapshot = AnswerSnapshot(itemID: card, progress: progress, records: records)
        progress.recordItem(id: card, correct: correct)
        records.record(itemID: card, roomID: room, correct: correct, now: now)
        return snapshot
    }

    private func undo(_ snapshot: AnswerSnapshot) {
        snapshot.restore(progress: progress, records: records)
    }

    func testUndoingAFirstAnswerLeavesNoTrace() {
        undo(answer(false))
        XCTAssertNil(records.records[card])
        XCTAssertEqual(records.totalAttempts, 0)
        XCTAssertFalse(progress.seenItems.contains(card))
        XCTAssertFalse(progress.missedItems.contains(card))
    }

    /// Left swipe, undo, right swipe: one right answer, nothing missed.
    func testUndoneMissThenRightCountsOnlyTheRightAnswer() {
        undo(answer(false))
        _ = answer(true)
        let record = try? XCTUnwrap(records.records[card])
        XCTAssertEqual(record?.attempts, 1)
        XCTAssertEqual(record?.correct, 1)
        XCTAssertEqual(record?.needsReview, false)
        XCTAssertFalse(progress.missedItems.contains(card))
    }

    /// Right swipe, undo, right swipe: still one look, so not known yet.
    func testUndoneRightThenRightIsOneAnswerNotKnown() {
        undo(answer(true))
        _ = answer(true)
        let record = try? XCTUnwrap(records.records[card])
        XCTAssertEqual(record?.attempts, 1)
        XCTAssertEqual(record?.streak, 1)
        XCTAssertEqual(record?.isKnown(), false)
    }

    /// Undo restores earlier history exactly, not to empty.
    func testUndoRestoresThePreviousRecord() {
        let start = Date(timeIntervalSince1970: 1_780_000_000)
        _ = answer(true, now: start)
        _ = answer(true, now: start.addingTimeInterval(86_400))
        let before = try? XCTUnwrap(records.records[card])
        undo(answer(false, now: start.addingTimeInterval(4 * 86_400)))
        let after = try? XCTUnwrap(records.records[card])
        XCTAssertEqual(after?.attempts, before?.attempts)
        XCTAssertEqual(after?.correct, before?.correct)
        XCTAssertEqual(after?.streak, before?.streak)
        XCTAssertEqual(after?.dueDate, before?.dueDate)
        XCTAssertEqual(after?.intervalDays, before?.intervalDays)
        XCTAssertEqual(after?.ease, before?.ease)
        XCTAssertTrue(progress.seenItems.contains(card))
        XCTAssertFalse(progress.missedItems.contains(card))
    }

    /// A choice card is graded at pick time. After undo the pick opens again,
    /// so the second pick must be the only answer recorded (P8).
    func testChoiceCardPickedAgainAfterUndoIsGradedOnce() {
        undo(answer(false))
        _ = answer(true)
        XCTAssertEqual(records.totalAttempts, 1)
    }

    /// A card answered twice (missed, then back in front and picked again)
    /// ends where it started when both are taken back, newest first.
    func testNewestFirstRestoresTheStartingState() {
        let first = answer(false)
        let second = answer(true)
        undo(second)
        undo(first)
        XCTAssertNil(records.records[card])
        XCTAssertFalse(progress.seenItems.contains(card))
    }

    func testRestoredMarksPersist() {
        undo(answer(false))
        let reloaded = ProgressStore(defaults: defaults)
        XCTAssertFalse(reloaded.seenItems.contains(card))
        XCTAssertFalse(reloaded.missedItems.contains(card))
        XCTAssertNil(PracticeRecordStore(defaults: defaults).records[card])
    }
}
