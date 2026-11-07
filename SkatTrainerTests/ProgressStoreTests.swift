import XCTest
@testable import SkatTrainer

@MainActor
final class ProgressStoreTests: XCTestCase {
    private var defaults: UserDefaults!
    private var store: ProgressStore!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "ProgressStoreTests")
        defaults.removePersistentDomain(forName: "ProgressStoreTests")
        store = ProgressStore(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: "ProgressStoreTests")
        super.tearDown()
    }

    func testRecordSessionIncrementsCounts() {
        store.recordSession(drillID: "meet-tiles")
        store.recordSession(drillID: "meet-tiles")
        XCTAssertEqual(store.completions(for: "meet-tiles"), 2)
        XCTAssertEqual(store.totalSessions, 2)
    }

    /// The tour's closing practice is recorded before onboarding ends, so
    /// Home's extras wait for a practice the player starts after it.
    func testTourPracticeDoesNotCountTowardHomeExtras() {
        XCTAssertFalse(store.hasPracticedSinceOnboarding)
        store.recordSession(drillID: "quick-session")
        store.sessionsAtOnboarding = store.totalSessions
        XCTAssertFalse(store.hasPracticedSinceOnboarding)
        store.recordSession(drillID: "meet-cards")
        XCTAssertTrue(store.hasPracticedSinceOnboarding)
    }

    /// Players who onboarded before this mark existed have none stored, so any
    /// finished practice counts, as before.
    func testUpgradersCountEveryPractice() {
        store.recordSession(drillID: "meet-cards")
        XCTAssertTrue(store.hasPracticedSinceOnboarding)
    }

    func testStreakStartsAtOne() {
        store.recordSession(drillID: "a")
        XCTAssertEqual(store.streakCount, 1)
    }

    func testSameDaySessionsKeepStreak() {
        let day1 = Date(timeIntervalSince1970: 1_750_000_000)
        store.recordSession(drillID: "a", now: day1)
        store.recordSession(drillID: "b", now: day1.addingTimeInterval(3600))
        XCTAssertEqual(store.streakCount, 1)
    }

    func testConsecutiveDaysGrowStreak() {
        let day1 = Date(timeIntervalSince1970: 1_750_000_000)
        store.recordSession(drillID: "a", now: day1)
        store.recordSession(drillID: "a", now: day1.addingTimeInterval(86_400))
        XCTAssertEqual(store.streakCount, 2)
    }

    func testGapResetsStreakToOne() {
        let day1 = Date(timeIntervalSince1970: 1_750_000_000)
        store.recordSession(drillID: "a", now: day1)
        store.recordSession(drillID: "a", now: day1.addingTimeInterval(86_400 * 3))
        XCTAssertEqual(store.streakCount, 1)
    }

    func testCurrentStreakHoldsThroughTheNextDay() {
        let day1 = Date(timeIntervalSince1970: 1_750_000_000)
        store.recordSession(drillID: "a", now: day1)
        store.recordSession(drillID: "a", now: day1.addingTimeInterval(86_400))
        XCTAssertEqual(store.currentStreak(now: day1.addingTimeInterval(86_400 * 2)), 2)
    }

    func testCurrentStreakDropsToZeroAfterAMissedDay() {
        let day1 = Date(timeIntervalSince1970: 1_750_000_000)
        store.recordSession(drillID: "a", now: day1)
        store.recordSession(drillID: "a", now: day1.addingTimeInterval(86_400))
        XCTAssertEqual(store.currentStreak(now: day1.addingTimeInterval(86_400 * 5)), 0)
    }

    func testClockGoingBackwardsDoesNotRewindTheLastDay() {
        let day1 = Date(timeIntervalSince1970: 1_750_000_000)
        store.recordSession(drillID: "a", now: day1)
        store.recordSession(drillID: "a", now: day1.addingTimeInterval(86_400))
        store.recordSession(drillID: "a", now: day1)
        store.recordSession(drillID: "a", now: day1.addingTimeInterval(86_400))
        XCTAssertEqual(store.streakCount, 2, "Returning to the real date must not count the same day twice")
    }

    func testRoomProgress() {
        guard let room = DrillLibrary.rooms.first else { return XCTFail("no rooms") }
        XCTAssertEqual(store.roomProgress(room), 0)
        store.recordSession(drillID: room.drills[0].id)
        XCTAssertEqual(store.roomProgress(room), 1 / Double(room.drills.count), accuracy: 0.001)
    }

    func testRecordItemTracksSeenAndMissed() {
        store.recordItem(id: "q1", correct: false)
        XCTAssertTrue(store.seenItems.contains("q1"))
        XCTAssertTrue(store.missedItems.contains("q1"))
        store.recordItem(id: "q1", correct: true)
        XCTAssertTrue(store.seenItems.contains("q1"))
        XCTAssertFalse(store.missedItems.contains("q1"), "A correct answer clears the miss")
    }

    func testItemTrackingPersists() {
        store.recordItem(id: "q1", correct: false)
        let reloaded = ProgressStore(defaults: defaults)
        XCTAssertTrue(reloaded.seenItems.contains("q1"))
        XCTAssertTrue(reloaded.missedItems.contains("q1"))
    }

    func testResetAllClearsEverythingButOnboarding() {
        store.hasOnboarded = true
        store.recordSession(drillID: "a")
        store.recordItem(id: "q1", correct: false)
        store.resetAll()
        XCTAssertEqual(store.streakCount, 0)
        XCTAssertEqual(store.totalSessions, 0)
        XCTAssertEqual(store.completions(for: "a"), 0)
        XCTAssertTrue(store.seenItems.isEmpty)
        XCTAssertTrue(store.missedItems.isEmpty)
        XCTAssertTrue(store.hasOnboarded, "Reset must not re-trigger onboarding")
    }

    // MARK: - Streak across zones (state machine audit 2026-11-06, B5)

    private func utc(_ iso: String) -> Date {
        ISO8601DateFormatter().date(from: iso)!
    }

    private func withZone(_ id: String, _ body: () -> Void) {
        let saved = NSTimeZone.default
        NSTimeZone.default = TimeZone(identifier: id)!
        defer { NSTimeZone.default = saved }
        body()
    }

    /// 6 Nov in Tokyo, then 6 Nov again in Los Angeles: one calendar date.
    func testTwoSessionsOnOneDateAcrossZonesKeepTheStreak() {
        withZone("Asia/Tokyo") { store.recordSession(drillID: "a", now: utc("2026-11-06T01:00:00Z")) }
        XCTAssertEqual(store.streakCount, 1, "precondition: the first session starts a streak")
        withZone("America/Los_Angeles") {
            store.recordSession(drillID: "b", now: utc("2026-11-06T17:00:00Z"))
            XCTAssertEqual(store.streakCount, 1)
            XCTAssertEqual(store.currentStreak(now: utc("2026-11-06T18:00:00Z")), 1)
            store.recordSession(drillID: "c", now: utc("2026-11-07T17:00:00Z"))
            XCTAssertEqual(store.streakCount, 2, "the next local date still grows it")
        }
    }

    /// Players updating from a build that stored the day as a start-of-day
    /// Date keep their streak, in the same zone and a few hours either side.
    func testAStreakStoredAsADateStillCounts() {
        for zone in ["Europe/Berlin", "Europe/London", "Asia/Dubai"] {
            defaults.removePersistentDomain(forName: "ProgressStoreTests")
            var berlin = Calendar(identifier: .gregorian)
            berlin.timeZone = TimeZone(identifier: "Europe/Berlin")!
            let lastDay = berlin.startOfDay(for: utc("2026-11-05T12:00:00Z"))
            defaults.set(lastDay, forKey: "progress.lastActiveDay")
            defaults.set(4, forKey: "progress.streakCount")
            withZone(zone) {
                let upgraded = ProgressStore(defaults: defaults)
                XCTAssertEqual(upgraded.currentStreak(now: utc("2026-11-06T12:00:00Z")), 4, zone)
                upgraded.recordSession(drillID: "a", now: utc("2026-11-05T15:00:00Z"))
                XCTAssertEqual(upgraded.streakCount, 4, "same day: \(zone)")
                upgraded.recordSession(drillID: "a", now: utc("2026-11-06T12:00:00Z"))
                XCTAssertEqual(upgraded.streakCount, 5, "next day: \(zone)")
            }
        }
    }

    func testAStreakSpanningADaylightSavingChangeGrows() {
        withZone("Europe/Berlin") {
            store.recordSession(drillID: "a", now: utc("2026-10-24T20:00:00Z"))
            store.recordSession(drillID: "a", now: utc("2026-10-25T20:00:00Z"))
            store.recordSession(drillID: "a", now: utc("2026-10-26T20:00:00Z"))
            XCTAssertEqual(store.streakCount, 3)
        }
    }

    // Rating-ask rules live in ReviewPromptTracker; see ReviewPromptTrackerTests.
}
