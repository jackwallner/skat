import SwiftUI
import UserNotifications

/// The parts of `UNUserNotificationCenter` the reminders use, so a test can
/// stand in for iOS.
@MainActor
protocol ReminderCenter {
    func add(_ request: UNNotificationRequest)
    func removePendingRequests(withIdentifiers ids: [String])
    func requestAuthorization() async -> Bool
    func isAuthorized() async -> Bool
}

struct SystemReminderCenter: ReminderCenter {
    func add(_ request: UNNotificationRequest) {
        UNUserNotificationCenter.current().add(request)
    }

    func removePendingRequests(withIdentifiers ids: [String]) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
    }

    func isAuthorized() async -> Bool {
        let status: UNAuthorizationStatus = await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                continuation.resume(returning: settings.authorizationStatus)
            }
        }
        return status == .authorized || status == .provisional || status == .ephemeral
    }
}

/// User-configurable app settings, persisted in UserDefaults.
/// Appearance defaults to the warm light theme regardless of the device style.
@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    enum Appearance: String, CaseIterable, Identifiable {
        case light, dark, system

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .light: return "Hell"
            case .dark: return "Dunkel"
            case .system: return "Geräteeinstellung"
            }
        }

        var colorScheme: ColorScheme? {
            switch self {
            case .light: return .light
            case .dark: return .dark
            case .system: return nil
            }
        }
    }

    enum GameNightDay: Int, CaseIterable, Identifiable {
        case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

        var id: Int { rawValue }

        var displayName: String {
            switch self {
            case .sunday: return "Sonntag"
            case .monday: return "Montag"
            case .tuesday: return "Dienstag"
            case .wednesday: return "Mittwoch"
            case .thursday: return "Donnerstag"
            case .friday: return "Freitag"
            case .saturday: return "Samstag"
            }
        }
    }

    private enum Keys {
        static let appearance = "settings.appearance"
        static let haptics = "settings.haptics"
        static let sound = "settings.sound"
        static let reminderEnabled = "settings.reminderEnabled"
        static let reminderHour = "settings.reminderHour"
        static let reminderMinute = "settings.reminderMinute"
        static let gameNightReminderEnabled = "settings.gameNightReminderEnabled"
        static let gameNightDay = "settings.gameNightDay"
        static let gameNightHour = "settings.gameNightHour"
        static let gameNightMinute = "settings.gameNightMinute"
    }

    private static let reminderID = "skat.dailyReminder"
    private static let gameNightReminderID = "skat.gameNightReminder"

    @Published var appearance: Appearance {
        didSet { defaults.set(appearance.rawValue, forKey: Keys.appearance) }
    }

    @Published var hapticsEnabled: Bool {
        didSet { defaults.set(hapticsEnabled, forKey: Keys.haptics) }
    }

    @Published var soundEnabled: Bool {
        didSet { defaults.set(soundEnabled, forKey: Keys.sound) }
    }

    @Published var reminderEnabled: Bool {
        didSet {
            defaults.set(reminderEnabled, forKey: Keys.reminderEnabled)
            if reminderEnabled {
                requestPermissionAndSchedule()
            } else {
                cancelReminder()
            }
        }
    }

    /// True when the player asked for a reminder but iOS notifications are off
    /// for the app. Without this the toggle just silently flips back, which
    /// looks like the app is broken.
    @Published var reminderPermissionDenied = false

    /// Built from the stored hour and minute each time it is read. A `Date`
    /// kept from launch was 1 January of year 1 in the launch zone, so a zone
    /// change while the app stayed in memory moved the shown time (Berlin
    /// 17:00 read 11:10 in New York) and every reschedule after it.
    var reminderTime: Date {
        get { Self.today(hour: reminderHour, minute: reminderMinute) }
        set {
            objectWillChange.send()
            let parts = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            defaults.set(parts.hour ?? 9, forKey: Keys.reminderHour)
            defaults.set(parts.minute ?? 0, forKey: Keys.reminderMinute)
            if reminderEnabled { scheduleReminder() }
        }
    }

    private var reminderHour: Int { defaults.object(forKey: Keys.reminderHour) as? Int ?? 9 }
    private var reminderMinute: Int { defaults.object(forKey: Keys.reminderMinute) as? Int ?? 0 }

    @Published var gameNightReminderEnabled: Bool {
        didSet {
            defaults.set(gameNightReminderEnabled, forKey: Keys.gameNightReminderEnabled)
            if gameNightReminderEnabled {
                requestPermissionAndScheduleGameNight()
            } else {
                cancelGameNightReminder()
            }
        }
    }

    @Published var gameNightDay: GameNightDay {
        didSet {
            defaults.set(gameNightDay.rawValue, forKey: Keys.gameNightDay)
            if gameNightReminderEnabled { scheduleGameNightReminder() }
        }
    }

    /// Read fresh from the stored hour and minute, like `reminderTime`.
    var gameNightReminderTime: Date {
        get { Self.today(hour: gameNightHour, minute: gameNightMinute) }
        set {
            objectWillChange.send()
            let parts = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            defaults.set(parts.hour ?? 17, forKey: Keys.gameNightHour)
            defaults.set(parts.minute ?? 0, forKey: Keys.gameNightMinute)
            if gameNightReminderEnabled { scheduleGameNightReminder() }
        }
    }

    private var gameNightHour: Int { defaults.object(forKey: Keys.gameNightHour) as? Int ?? 17 }
    private var gameNightMinute: Int { defaults.object(forKey: Keys.gameNightMinute) as? Int ?? 0 }

    private static func today(hour: Int, minute: Int) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
    }

    private let defaults: UserDefaults
    private let center: any ReminderCenter

    init(defaults: UserDefaults = .standard, center: any ReminderCenter = SystemReminderCenter()) {
        self.defaults = defaults
        self.center = center
        appearance = Appearance(rawValue: defaults.string(forKey: Keys.appearance) ?? "") ?? .light
        hapticsEnabled = defaults.object(forKey: Keys.haptics) as? Bool ?? true
        soundEnabled = defaults.object(forKey: Keys.sound) as? Bool ?? true
        reminderEnabled = defaults.bool(forKey: Keys.reminderEnabled)
        gameNightReminderEnabled = defaults.bool(forKey: Keys.gameNightReminderEnabled)
        let savedDay = defaults.integer(forKey: Keys.gameNightDay)
        gameNightDay = GameNightDay(rawValue: savedDay) ?? .thursday
    }

    // MARK: - Reminder copy

    /// Generic on purpose. A repeating notification is static text, so any
    /// number in it goes stale for exactly the player who stops opening the
    /// app. Progress counts live on Home and Your Progress, where they are
    /// always current.
    static let dailyReminderBody = "Fünf Minuten Übung machen Drücken und Stichplanung sicherer."
    static let gameNightReminderBody = "Fünf persönliche Minuten jetzt, und der Tisch fühlt sich später ruhiger an."

    // MARK: - Reconciling with iOS

    /// iOS refuses `add` while notifications are off for the app, so a
    /// reminder edited then (time, weekday) was dropped while its toggle still
    /// read on, and stayed dead after notifications came back. Runs whenever
    /// the app becomes active: while iOS allows it, every enabled reminder is
    /// put back. Re-adding replaces a pending one with the same identifier.
    func reconcileReminders() async {
        guard reminderEnabled || gameNightReminderEnabled else { return }
        guard await center.isAuthorized() else { return }
        if reminderEnabled { scheduleReminder() }
        if gameNightReminderEnabled { scheduleGameNightReminder() }
    }

    // MARK: - Daily reminder

    private func requestPermissionAndSchedule() {
        Task {
            if await center.requestAuthorization() {
                scheduleReminder()
            } else {
                reminderEnabled = false
                reminderPermissionDenied = true
            }
        }
    }

    private func scheduleReminder() {
        center.removePendingRequests(withIdentifiers: [Self.reminderID])

        let content = UNMutableNotificationContent()
        content.title = "Zeit für eine kurze Runde"
        content.body = Self.dailyReminderBody
        content.sound = .default

        let parts = DateComponents(hour: reminderHour, minute: reminderMinute, second: 0)
        let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: true)
        center.add(UNNotificationRequest(identifier: Self.reminderID, content: content, trigger: trigger))
    }

    private func cancelReminder() {
        center.removePendingRequests(withIdentifiers: [Self.reminderID])
    }

    // MARK: - Game night reminder

    private func requestPermissionAndScheduleGameNight() {
        Task {
            if await center.requestAuthorization() {
                scheduleGameNightReminder()
            } else {
                gameNightReminderEnabled = false
                reminderPermissionDenied = true
            }
        }
    }

    private func scheduleGameNightReminder() {
        center.removePendingRequests(withIdentifiers: [Self.gameNightReminderID])

        let content = UNMutableNotificationContent()
        content.title = "Deine Skatabend-Vorbereitung steht bereit"
        content.body = Self.gameNightReminderBody
        content.sound = .default
        content.userInfo = [AppNotification.routeKey: AppNotification.gameNightPrepValue]

        let parts = DateComponents(
            hour: gameNightHour, minute: gameNightMinute, second: 0, weekday: gameNightDay.rawValue
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: true)
        center.add(UNNotificationRequest(identifier: Self.gameNightReminderID, content: content, trigger: trigger))
    }

    func cancelGameNightReminder() {
        center.removePendingRequests(withIdentifiers: [Self.gameNightReminderID])
    }
}
