import XCTest
@testable import SkatTrainer

final class DisplayLocaleTests: XCTestCase {
    private func fivePM() -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar.date(from: DateComponents(year: 2026, month: 10, day: 23, hour: 17))!
    }

    func testTimesUseTheTwentyFourHourClock() {
        let style = Date.FormatStyle(date: .omitted, time: .shortened, locale: .skat, timeZone: TimeZone(secondsFromGMT: 0)!)
        let text = fivePM().formatted(style)

        XCTAssertEqual(text, "17:00")
        XCTAssertFalse(text.contains("PM"))
    }

    func testWeekdaysAreGerman() {
        var style = Date.FormatStyle.dateTime.weekday(.wide).locale(.skat)
        style.timeZone = TimeZone(secondsFromGMT: 0)!

        XCTAssertEqual(fivePM().formatted(style), "Freitag")
    }
}
