import UserNotifications
import XCTest
@testable import SkatTrainer

/// Stands in for iOS: like the real center, it refuses `add` while
/// notifications are off for the app.
@MainActor
final class FakeReminderCenter: ReminderCenter {
    var authorized = true
    private(set) var pending: [String: UNNotificationRequest] = [:]

    func add(_ request: UNNotificationRequest) {
        guard authorized else { return }
        pending[request.identifier] = request
    }

    func removePendingRequests(withIdentifiers ids: [String]) {
        ids.forEach { pending[$0] = nil }
    }

    func requestAuthorization() async -> Bool { authorized }
    func isAuthorized() async -> Bool { authorized }

    func trigger(_ id: String) -> DateComponents? {
        (pending[id]?.trigger as? UNCalendarNotificationTrigger)?.dateComponents
    }
}

/// Reminder scheduling against a fake center (state machine audit
/// 2026-11-06, B2).
@MainActor
final class ReminderScheduleTests: XCTestCase {
    private let suite = "ReminderScheduleTests"
    private let dailyID = "skat.dailyReminder"
    private let gameNightID = "skat.gameNightReminder"
    private var defaults: UserDefaults!
    private var center: FakeReminderCenter!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        center = FakeReminderCenter()
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
        super.tearDown()
    }

    private func makeSettings(daily: Bool = true, gameNight: Bool = true) -> AppSettings {
        defaults.set(daily, forKey: "settings.reminderEnabled")
        defaults.set(gameNight, forKey: "settings.gameNightReminderEnabled")
        return AppSettings(defaults: defaults, center: center)
    }

    /// Notifications off in iOS, the player edits both reminders (iOS drops
    /// the new requests), then turns notifications back on and returns.
    func testRemindersEditedWhileNotificationsWereOffComeBack() async {
        let settings = makeSettings()
        center.authorized = false
        settings.reminderTime = settings.reminderTime.addingTimeInterval(3600)
        settings.gameNightDay = .saturday
        XCTAssertNil(center.pending[dailyID], "precondition: iOS refused the edited daily reminder")
        XCTAssertNil(center.pending[gameNightID], "precondition: iOS refused the edited game night reminder")
        XCTAssertTrue(settings.reminderEnabled && settings.gameNightReminderEnabled,
                      "precondition: both toggles still read on")

        center.authorized = true
        await settings.reconcileReminders()
        XCTAssertNotNil(center.pending[dailyID])
        XCTAssertEqual(center.trigger(gameNightID)?.weekday, AppSettings.GameNightDay.saturday.rawValue)
    }

    /// A toggle persisted on with nothing pending (restored device, dropped
    /// request) is scheduled again once the app is active and allowed.
    func testEnabledRemindersWithNothingPendingAreScheduled() async {
        let settings = makeSettings()
        XCTAssertTrue(center.pending.isEmpty, "precondition: nothing pending")
        await settings.reconcileReminders()
        XCTAssertNotNil(center.pending[dailyID])
        XCTAssertNotNil(center.pending[gameNightID])
    }

    func testDisabledRemindersStayUnscheduled() async {
        let settings = makeSettings(daily: false, gameNight: false)
        await settings.reconcileReminders()
        XCTAssertTrue(center.pending.isEmpty)
    }

    /// While iOS still says no, nothing changes: the toggle keeps the
    /// player's choice so the reminder returns with the permission.
    func testWhileNotificationsAreOffTheTogglesKeepTheirChoice() async {
        center.authorized = false
        let settings = makeSettings(gameNight: false)
        await settings.reconcileReminders()
        XCTAssertTrue(center.pending.isEmpty)
        XCTAssertTrue(settings.reminderEnabled)
        XCTAssertFalse(settings.reminderPermissionDenied)
    }
}
