import Foundation

@MainActor
final class ProgressStore: ObservableObject {
    static let shared = ProgressStore()

    @Published private(set) var streakCount: Int
    @Published private(set) var totalSessions: Int
    @Published private(set) var completions: [String: Int]
    @Published private(set) var seenItems: Set<String>
    @Published private(set) var missedItems: Set<String>

    private let defaults: UserDefaults

    private enum Keys {
        static let streakCount = "progress.streakCount"
        static let lastActiveDay = "progress.lastActiveDay"
        static let totalSessions = "progress.totalSessions"
        static let completions = "progress.completions"
        static let hasOnboarded = "progress.hasOnboarded"
        static let reviewGateShown = "progress.reviewGateShown"
        static let seenItems = "progress.seenItems"
        static let missedItems = "progress.missedItems"
        static let lastQuickSessionDay = "progress.lastQuickSessionDay"
        static let sessionsAtOnboarding = "progress.sessionsAtOnboarding"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        streakCount = defaults.integer(forKey: Keys.streakCount)
        totalSessions = defaults.integer(forKey: Keys.totalSessions)
        completions = (defaults.dictionary(forKey: Keys.completions) as? [String: Int]) ?? [:]
        seenItems = Set(defaults.stringArray(forKey: Keys.seenItems) ?? [])
        missedItems = Set(defaults.stringArray(forKey: Keys.missedItems) ?? [])
    }

    var hasOnboarded: Bool {
        get { defaults.bool(forKey: Keys.hasOnboarded) }
        set { defaults.set(newValue, forKey: Keys.hasOnboarded) }
    }

    /// Sessions finished before onboarding ended: the tour's closing
    /// practice. Players who onboarded earlier have none stored (0).
    var sessionsAtOnboarding: Int {
        get { defaults.integer(forKey: Keys.sessionsAtOnboarding) }
        set { defaults.set(newValue, forKey: Keys.sessionsAtOnboarding) }
    }

    /// True once the player has finished a practice of their own after
    /// onboarding. Home's extras (later the challenge card) wait for it, so the
    /// first Home after the tour is the plain lobby.
    var hasPracticedSinceOnboarding: Bool { totalSessions > sessionsAtOnboarding }

    func completions(for drillID: String) -> Int {
        completions[drillID] ?? 0
    }

    func roomProgress(_ room: Room) -> Double {
        guard !room.drills.isEmpty else { return 0 }
        let done = room.drills.filter { completions(for: $0.id) > 0 }.count
        return Double(done) / Double(room.drills.count)
    }

    func recordSession(drillID: String, now: Date = Date()) {
        completions[drillID, default: 0] += 1
        totalSessions += 1
        bumpStreak(now: now)
        defaults.set(completions, forKey: Keys.completions)
        defaults.set(totalSessions, forKey: Keys.totalSessions)
    }

    /// The streak as it stands right now. `streakCount` only changes when a
    /// drill is finished, so after a missed day it still held the old number
    /// and Home showed a streak the player had already lost.
    func currentStreak(now: Date = Date()) -> Int {
        guard let last = lastActiveDayKey else { return streakCount }
        return Self.daysBetween(last, MasteryLedger.dayKey(now)) > 1 ? 0 : streakCount
    }

    /// The local calendar date of the last finished drill ("2026-11-06").
    /// It used to be a start-of-day `Date` from the zone at write time, read
    /// back in the zone at read time, so a flight across the date line made
    /// one date look like two (audit 2026-11-06, B5). Those stored dates
    /// still read: midday of the stored day lands on the same date in any
    /// zone within twelve hours of the one that wrote it.
    private var lastActiveDayKey: String? {
        let stored = defaults.object(forKey: Keys.lastActiveDay)
        if let key = stored as? String { return key }
        guard let legacy = stored as? Date else { return nil }
        return MasteryLedger.dayKey(legacy.addingTimeInterval(12 * 3600))
    }

    /// Whole days from one day key to another, counted on a fixed calendar
    /// so neither the zone nor DST changes the answer.
    private static func daysBetween(_ from: String, _ to: String) -> Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        func date(_ key: String) -> Date? {
            let parts = key.split(separator: "-").compactMap { Int($0) }
            guard parts.count == 3 else { return nil }
            return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
        }
        guard let start = date(from), let end = date(to) else { return 0 }
        return calendar.dateComponents([.day], from: start, to: end).day ?? 0
    }

    /// Streak counts consecutive calendar days with at least one finished drill.
    private func bumpStreak(now: Date) {
        let today = MasteryLedger.dayKey(now)

        if let last = lastActiveDayKey {
            let gap = Self.daysBetween(last, today)
            if gap == 1 {
                streakCount += 1
            } else if gap > 1 {
                streakCount = 1
            } else if gap < 0 {
                // The clock went backwards (travel, a manual change). Keep the
                // later day so the streak is not counted twice on the way back.
                return
            } // gap == 0: same day, streak unchanged
        } else {
            streakCount = 1
        }
        defaults.set(today, forKey: Keys.lastActiveDay)
        defaults.set(streakCount, forKey: Keys.streakCount)
    }

    /// Item-level memory that feeds the Get Started mix: anything answered wrong
    /// (or self-graded "again") comes back first; unseen items come next.
    func recordItem(id: String, correct: Bool) {
        seenItems.insert(id)
        if correct {
            missedItems.remove(id)
        } else {
            missedItems.insert(id)
        }
        defaults.set(Array(seenItems), forKey: Keys.seenItems)
        defaults.set(Array(missedItems), forKey: Keys.missedItems)
    }

    /// Whether an item is in the seen and missed sets, so a taken back
    /// answer can put both back exactly as they were.
    struct ItemMarks: Equatable {
        let seen: Bool
        let missed: Bool
    }

    func marks(forItem id: String) -> ItemMarks {
        ItemMarks(seen: seenItems.contains(id), missed: missedItems.contains(id))
    }

    func restoreMarks(_ marks: ItemMarks, forItem id: String) {
        if marks.seen { seenItems.insert(id) } else { seenItems.remove(id) }
        if marks.missed { missedItems.insert(id) } else { missedItems.remove(id) }
        defaults.set(Array(seenItems), forKey: Keys.seenItems)
        defaults.set(Array(missedItems), forKey: Keys.missedItems)
    }

    // MARK: - Daily Quick Session

    /// Get Started is a once-a-day ritual: a fresh mix each day, and once
    /// today's is done the Home card rests until tomorrow rather than handing
    /// back the same questions (repeating a question you just answered teaches
    /// nothing). Missed items still return on later days as spaced repetition.
    func quickSessionCompletedToday(now: Date = Date()) -> Bool {
        guard let last = defaults.object(forKey: Keys.lastQuickSessionDay) as? Date else { return false }
        return Calendar.current.isDate(last, inSameDayAs: now)
    }

    func markQuickSessionCompleted(now: Date = Date()) {
        defaults.set(Calendar.current.startOfDay(for: now), forKey: Keys.lastQuickSessionDay)
    }

    /// Clears every practice stat. Leaves onboarding and purchases alone.
    func resetAll() {
        streakCount = 0
        totalSessions = 0
        completions = [:]
        seenItems = []
        missedItems = []
        defaults.removeObject(forKey: Keys.streakCount)
        defaults.removeObject(forKey: Keys.lastActiveDay)
        defaults.removeObject(forKey: Keys.totalSessions)
        defaults.removeObject(forKey: Keys.completions)
        defaults.removeObject(forKey: Keys.seenItems)
        defaults.removeObject(forKey: Keys.missedItems)
        defaults.removeObject(forKey: Keys.reviewGateShown)
        defaults.removeObject(forKey: Keys.lastQuickSessionDay)
        defaults.removeObject(forKey: Keys.sessionsAtOnboarding)
    }
}
