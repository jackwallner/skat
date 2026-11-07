import XCTest
@testable import SkatTrainer

/// Home turns the game night reminder off when a fresh customer record
/// shows no membership, which also catches a membership that ended while
/// the app was closed (review of the state machine audit 2026-11-06, gap).
@MainActor
final class LapsedReminderTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_790_000_000)

    func testAFreshRecordWithoutMembershipConfirmsTheLapse() {
        XCTAssertTrue(SubscriptionService.confirmsNoMembership(isPro: false, answeredAt: now, now: now))
        XCTAssertTrue(SubscriptionService.confirmsNoMembership(
            isPro: false, answeredAt: now.addingTimeInterval(-60), now: now))
    }

    /// RevenueCat judges a cached record more than three days old against
    /// today, so a member who renewed since reads as lapsed in it. Only the
    /// network's answer may turn their reminder off.
    func testAnOldCachedRecordConfirmsNothing() {
        XCTAssertFalse(SubscriptionService.confirmsNoMembership(
            isPro: false, answeredAt: now.addingTimeInterval(-4 * 86_400), now: now))
        XCTAssertFalse(SubscriptionService.confirmsNoMembership(
            isPro: false, answeredAt: now.addingTimeInterval(-(SubscriptionService.freshBaselineAge + 1)), now: now))
    }

    func testAMemberIsNeverConfirmedLapsed() {
        XCTAssertFalse(SubscriptionService.confirmsNoMembership(isPro: true, answeredAt: now, now: now))
    }
}
