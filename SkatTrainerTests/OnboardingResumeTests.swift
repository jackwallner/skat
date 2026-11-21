import XCTest
@testable import SkatTrainer

@MainActor
final class OnboardingResumeTests: XCTestCase {
    private var defaults: UserDefaults!
    private var store: ProgressStore!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "OnboardingResumeTests")
        defaults.removePersistentDomain(forName: "OnboardingResumeTests")
        store = ProgressStore(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: "OnboardingResumeTests")
        super.tearDown()
    }

    /// Catalog B1: a member who quits in the primer or tour resumes there.
    func testOnboardingResumeStagePersistsUntilCleared() {
        XCTAssertNil(store.onboardingResumeStage)
        store.onboardingResumeStage = "tour"
        XCTAssertEqual(ProgressStore(defaults: defaults).onboardingResumeStage, "tour")
        store.resetAll()
        XCTAssertEqual(store.onboardingResumeStage, "tour", "Reset keeps onboarding state, like hasOnboarded")
        store.onboardingResumeStage = nil
        XCTAssertNil(ProgressStore(defaults: defaults).onboardingResumeStage)
    }
}
