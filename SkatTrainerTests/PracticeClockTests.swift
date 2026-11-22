import XCTest
@testable import SkatTrainer

/// Die Zeitchallenge endet zu einer festen Uhrzeit, nicht nach neunzig
/// Schlafphasen: Zeit in einer anderen App zählt mit.
final class PracticeClockTests: XCTestCase {
    func testSecondsLeftRoundsUpAndStopsAtZero() {
        let start = Date(timeIntervalSince1970: 1_000_000)
        let deadline = start.addingTimeInterval(90)
        XCTAssertEqual(PracticeRunView.secondsLeft(until: deadline, now: start), 90)
        XCTAssertEqual(PracticeRunView.secondsLeft(until: deadline, now: start.addingTimeInterval(0.4)), 90)
        XCTAssertEqual(PracticeRunView.secondsLeft(until: deadline, now: start.addingTimeInterval(50)), 40)
        XCTAssertEqual(PracticeRunView.secondsLeft(until: deadline, now: start.addingTimeInterval(89.5)), 1)
        XCTAssertEqual(PracticeRunView.secondsLeft(until: deadline, now: deadline), 0)
        XCTAssertEqual(PracticeRunView.secondsLeft(until: deadline, now: start.addingTimeInterval(600)), 0)
    }
}
