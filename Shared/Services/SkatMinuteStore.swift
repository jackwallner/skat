import Foundation

struct SkatMinuteResult: Codable, Identifiable, Sendable {
    let dayKey: String
    let shortDate: String
    let completedAt: Date
    let answers: [Bool]
    let correctByCategory: [String: Int]
    let totalByCategory: [String: Int]

    var id: String { dayKey }
    var score: Int { answers.filter { $0 }.count }
    var total: Int { answers.count }

    func correct(in category: SkatMinuteCategory) -> Int {
        correctByCategory[category.rawValue, default: 0]
    }

    func total(in category: SkatMinuteCategory) -> Int {
        totalByCategory[category.rawValue, default: 0]
    }

    var shareText: String {
        let grid = answers.map { $0 ? "🟩" : "⬜️" }.joined()
        return "Skat-Minute \(shortDate): \(score)/\(total)\n\(grid)\nSchaffst du mehr? \(AppStoreLinks.productURL.absoluteString)"
    }
}

@MainActor
final class SkatMinuteStore: ObservableObject {
    static let shared = SkatMinuteStore()

    @Published private(set) var results: [String: SkatMinuteResult]

    private let defaults: UserDefaults
    private static let resultsKey = "skatMinute.results"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.resultsKey),
           let decoded = try? JSONDecoder().decode([String: SkatMinuteResult].self, from: data) {
            results = decoded
        } else {
            results = [:]
        }
    }

    func result(for day: Date, calendar: Calendar = .current) -> SkatMinuteResult? {
        results[SkatMinuteContent.key(for: day, calendar: calendar)]
    }

    @discardableResult
    func record(
        challenge: SkatMinuteChallenge,
        answers: [Bool],
        now: Date = Date()
    ) -> SkatMinuteResult {
        if let existing = results[challenge.dayKey] { return existing }

        var correctByCategory: [String: Int] = [:]
        var totalByCategory: [String: Int] = [:]
        for (question, correct) in zip(challenge.questions, answers) {
            totalByCategory[question.category.rawValue, default: 0] += 1
            if correct { correctByCategory[question.category.rawValue, default: 0] += 1 }
        }
        let result = SkatMinuteResult(
            dayKey: challenge.dayKey,
            shortDate: challenge.shortDate,
            completedAt: now,
            answers: answers,
            correctByCategory: correctByCategory,
            totalByCategory: totalByCategory
        )
        results[challenge.dayKey] = result
        persist()
        return result
    }

    func completedThisWeek(now: Date = Date(), calendar: Calendar = .current) -> Int {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: now) else { return 0 }
        return results.values.filter { interval.contains($0.completedAt) }.count
    }

    func archiveDates(
        before day: Date = Date(),
        count: Int = 30,
        calendar: Calendar = .current
    ) -> [Date] {
        (1...count).compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: day)
        }
    }

    func resetAll() {
        results = [:]
        defaults.removeObject(forKey: Self.resultsKey)
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(results) else { return }
        defaults.set(data, forKey: Self.resultsKey)
    }
}
