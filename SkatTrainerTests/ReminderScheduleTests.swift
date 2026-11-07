import UserNotifications
import XCTest
@testable import SkatTrainer

/// Stands in for iOS, with notifications allowed.
@MainActor
final class FakeReminderCenter: ReminderCenter {
    private(set) var pending: [String: UNNotificationRequest] = [:]

    func add(_ request: UNNotificationRequest) {
        pending[request.identifier] = request
    }

    func removePendingRequests(withIdentifiers ids: [String]) {
        ids.forEach { pending[$0] = nil }
    }

    func requestAuthorization() async -> Bool { true }

    func trigger(_ id: String) -> DateComponents? {
        (pending[id]?.trigger as? UNCalendarNotificationTrigger)?.dateComponents
    }
}

/// Reminder scheduling against a fake center (state machine audit
/// 2026-11-06, B3).
@MainActor
final class ReminderScheduleTests: XCTestCase {
    private let suite = "ReminderScheduleTests"
    private let dailyID = "skat.dailyReminder"
    private let gameNightID = "skat.gameNightReminder"
    private var defaults: UserDefaults!
    private var center: FakeReminderCenter!
    private var savedZone: TimeZone!

    override func setUp() {
        super.setUp()
        savedZone = NSTimeZone.default
        defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        center = FakeReminderCenter()
    }

    override func tearDown() {
        NSTimeZone.default = savedZone
        defaults.removePersistentDomain(forName: suite)
        super.tearDown()
    }

    private func makeSettings(daily: Bool = true, gameNight: Bool = true) -> AppSettings {
        defaults.set(daily, forKey: "settings.reminderEnabled")
        defaults.set(gameNight, forKey: "settings.gameNightReminderEnabled")
        return AppSettings(defaults: defaults, center: center)
    }

    // MARK: - B3: the chosen wall-clock time survives a zone change

    private func hourAndMinute(_ date: Date) -> [Int?] {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
        return [parts.hour, parts.minute]
    }

    /// Berlin 17:00 must still read and fire at 17:00 after the phone lands
    /// in New York with the app kept in memory (it read 11:10 before).
    func testChosenTimesSurviveAZoneChangeWhileTheAppIsResident() async {
        NSTimeZone.default = TimeZone(identifier: "Europe/Berlin")!
        defaults.set(17, forKey: "settings.gameNightHour")
        defaults.set(0, forKey: "settings.gameNightMinute")
        defaults.set(7, forKey: "settings.reminderHour")
        defaults.set(45, forKey: "settings.reminderMinute")
        let settings = makeSettings()
        XCTAssertEqual(hourAndMinute(settings.gameNightReminderTime), [17, 0], "precondition: Berlin reads 17:00")

        NSTimeZone.default = TimeZone(identifier: "America/New_York")!
        XCTAssertEqual(Calendar.current.timeZone.identifier, "America/New_York", "precondition: zone changed")
        XCTAssertEqual(hourAndMinute(settings.gameNightReminderTime), [17, 0])
        XCTAssertEqual(hourAndMinute(settings.reminderTime), [7, 45])

        settings.gameNightDay = .saturday
        let game = center.trigger(gameNightID)
        XCTAssertEqual([game?.hour, game?.minute, game?.weekday], [17, 0, 7])
        settings.reminderEnabled = false
        settings.reminderEnabled = true
        for _ in 0..<100 where center.pending[dailyID] == nil { await Task.yield() }
        let daily = center.trigger(dailyID)
        XCTAssertEqual([daily?.hour, daily?.minute], [7, 45])
    }

    /// Existing players keep the hour and minute they stored, and a picked
    /// time is stored as picked.
    func testStoredTimesReadBackAndEditsAreStored() {
        defaults.set(18, forKey: "settings.gameNightHour")
        defaults.set(30, forKey: "settings.gameNightMinute")
        let settings = makeSettings()
        XCTAssertEqual(hourAndMinute(settings.gameNightReminderTime), [18, 30])
        XCTAssertEqual(hourAndMinute(settings.reminderTime), [9, 0], "default daily time")

        settings.reminderTime = Calendar.current.date(bySettingHour: 20, minute: 15, second: 0, of: Date())!
        XCTAssertEqual(defaults.integer(forKey: "settings.reminderHour"), 20)
        XCTAssertEqual(defaults.integer(forKey: "settings.reminderMinute"), 15)
        XCTAssertEqual(center.trigger(dailyID)?.hour, 20)
        XCTAssertEqual(hourAndMinute(AppSettings(defaults: defaults, center: center).reminderTime), [20, 15])
    }
}
