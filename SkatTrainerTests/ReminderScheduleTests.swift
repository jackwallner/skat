import UserNotifications
import XCTest
@testable import SkatTrainer

/// Stands in for iOS: like the real center, it refuses `add` while
/// notifications are off for the app.
@MainActor
final class FakeReminderCenter: ReminderCenter {
    var status: UNAuthorizationStatus = .authorized
    /// What the player answers when iOS asks.
    var grantsWhenAsked = true
    private(set) var timesAsked = 0
    private(set) var pending: [String: UNNotificationRequest] = [:]

    var authorized: Bool {
        get { status == .authorized }
        set { status = newValue ? .authorized : .denied }
    }

    func add(_ request: UNNotificationRequest) {
        guard authorized else { return }
        pending[request.identifier] = request
    }

    func removePendingRequests(withIdentifiers ids: [String]) {
        ids.forEach { pending[$0] = nil }
    }

    func requestAuthorization() async -> Bool {
        if status == .notDetermined {
            timesAsked += 1
            status = grantsWhenAsked ? .authorized : .denied
        }
        return authorized
    }

    func authorizationStatus() async -> UNAuthorizationStatus { status }

    func trigger(_ id: String) -> DateComponents? {
        (pending[id]?.trigger as? UNCalendarNotificationTrigger)?.dateComponents
    }
}

/// Reminder scheduling against a fake center (state machine audit
/// 2026-11-06, B2 and B3).
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

    /// Restored from a backup onto a new phone: the toggles came back, iOS's
    /// permission and pending requests did not. iOS is asked once, and the
    /// reminders are scheduled when the player allows them.
    func testARestoredPhoneAsksAgainAndSchedules() async {
        center.status = .notDetermined
        let settings = makeSettings()
        await settings.reconcileReminders()
        XCTAssertEqual(center.timesAsked, 1)
        XCTAssertNotNil(center.pending[dailyID])
        XCTAssertNotNil(center.pending[gameNightID])
    }

    /// Refusing that question keeps the player's choice, so the reminders
    /// come back if notifications are allowed later in iOS Settings.
    func testARefusalOnARestoredPhoneKeepsTheToggles() async {
        center.status = .notDetermined
        center.grantsWhenAsked = false
        let settings = makeSettings()
        await settings.reconcileReminders()
        XCTAssertTrue(center.pending.isEmpty)
        XCTAssertTrue(settings.reminderEnabled && settings.gameNightReminderEnabled)

        center.authorized = true
        await settings.reconcileReminders()
        XCTAssertNotNil(center.pending[dailyID])
        XCTAssertEqual(center.timesAsked, 1)
    }

    func testDisabledRemindersStayUnscheduledAndNeverAsk() async {
        center.status = .notDetermined
        let settings = makeSettings(daily: false, gameNight: false)
        await settings.reconcileReminders()
        XCTAssertTrue(center.pending.isEmpty)
        XCTAssertEqual(center.timesAsked, 0)
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
        await settings.reconcileReminders()
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
