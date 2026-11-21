import XCTest
@testable import SkatTrainer
import UIKit

/// Catalog B3 (2026-11-20): Home and the Skat-Minute screen read `Date()` in
/// body and never noticed midnight while the app stayed resident.
@MainActor
final class DayClockTests: XCTestCase {
    private var calendar = Calendar(identifier: .gregorian)
    private var current = Date(timeIntervalSince1970: 1_750_000_000)

    override func setUp() {
        super.setUp()
        calendar.timeZone = TimeZone(identifier: "UTC")!
    }

    private func makeClock(center: NotificationCenter) -> DayClock {
        DayClock(center: center, calendar: calendar, provider: { [unowned self] in current })
    }

    func testNewDayIsPublishedWhenTheAppBecomesActive() {
        let center = NotificationCenter()
        let clock = makeClock(center: center)
        let first = clock.now
        current = first.addingTimeInterval(11 * 3600)
        center.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        XCTAssertFalse(calendar.isDate(clock.now, inSameDayAs: first))
        XCTAssertEqual(clock.now, current)
    }

    func testSignificantTimeChangeRollsTheDayOver() {
        let center = NotificationCenter()
        let clock = makeClock(center: center)
        let first = clock.now
        current = first.addingTimeInterval(86_400)
        center.post(name: UIApplication.significantTimeChangeNotification, object: nil)
        XCTAssertEqual(clock.now, current)
    }

    func testSameDayDoesNotRepublish() {
        let center = NotificationCenter()
        let clock = makeClock(center: center)
        let first = clock.now
        var published = 0
        let token = clock.objectWillChange.sink { published += 1 }
        current = first.addingTimeInterval(60)
        center.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        XCTAssertEqual(clock.now, first)
        XCTAssertEqual(published, 0)
        token.cancel()
    }
}
