import Combine
import Foundation
import UIKit

/// The current date for views that show "today". A view that reads `Date()`
/// inside `body` only learns about midnight when something else makes it
/// redraw, so an app left resident overnight kept showing yesterday's round.
/// `now` is republished when the app becomes active or iOS reports a
/// significant time change (midnight, a zone or clock change), and only when
/// the calendar day actually differs.
@MainActor
final class DayClock: ObservableObject {
    @Published private(set) var now: Date

    private let provider: () -> Date
    private let calendar: Calendar
    private var subscriptions = Set<AnyCancellable>()

    init(
        center: NotificationCenter = .default,
        calendar: Calendar = .current,
        provider: @escaping () -> Date = Date.init
    ) {
        self.provider = provider
        self.calendar = calendar
        now = provider()
        for name in [UIApplication.significantTimeChangeNotification, UIApplication.didBecomeActiveNotification] {
            center.publisher(for: name)
                .sink { [weak self] _ in MainActor.assumeIsolated { self?.refresh() } }
                .store(in: &subscriptions)
        }
    }

    func refresh() {
        let current = provider()
        guard !calendar.isDate(now, inSameDayAs: current) else { return }
        now = current
    }
}
