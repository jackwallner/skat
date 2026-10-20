import XCTest
@testable import SkatTrainer

/// The trial flow's copy is the shipped copy; only the button wording varies,
/// and only among the wordings compiled in (`TrialCTA`).
@MainActor
final class TrialCopyTests: XCTestCase {
    func testTermsAreTheShippedLines() {
        XCTAssertEqual(
            PaywallPricing.terms(amount: "6,99 € / Monat", plan: .monthly),
            "Abrechnung: 6,99 € / Monat, inklusive 7 Tagen kostenlos. Verlängert sich automatisch. Kündige mindestens 24 Stunden vor Ablauf."
        )
        XCTAssertEqual(
            PaywallPricing.terms(amount: nil, plan: .yearly),
            "Inklusive 7 Tagen kostenlos. Verlängert sich automatisch. Kündige mindestens 24 Stunden vor Ablauf."
        )
        XCTAssertEqual(
            PaywallPricing.terms(amount: "69,99 €", plan: .lifetime),
            "69,99 € einmalig. Kein Abonnement, keine automatische Verlängerung."
        )
    }

    /// The onboarding trial page keeps its own shipped line, and it must
    /// always name the plan its button buys.
    func testOnboardingTrialDisclosureIsTheShippedLine() {
        XCTAssertEqual(
            OnboardingView.trialDisclosure(amount: "6,99 € / Monat"),
            "Abrechnung: 6,99 € / Monat, inklusive 7 Tagen kostenlos. Verlängert sich automatisch, bis du kündigst."
        )
        XCTAssertEqual(
            OnboardingView.trialDisclosure(amount: nil),
            "Inklusive 7 Tagen kostenlos. Verlängert sich automatisch, bis du kündigst."
        )
    }

    func testControlIsTheShippedButton() {
        XCTAssertEqual(PaywallPlan.yearly.ctaTitle(), "7-Tage-Test starten")
        XCTAssertEqual(PaywallPlan.monthly.ctaTitle(), "7-Tage-Test starten")
        XCTAssertEqual(PaywallPlan.lifetime.ctaTitle(), "Skat+ dauerhaft freischalten")
        XCTAssertEqual(TrialCTA.sevenDay.title(.onboarding), "7 Tage kostenlos starten")
    }

    /// No metadata, a typo, or a non-string all mean the control.
    func testOfferingMetadataPicksOnlyAKnownArm() {
        XCTAssertEqual(TrialCTA.from(metadata: nil), .sevenDay)
        XCTAssertEqual(TrialCTA.from(metadata: [:]), .sevenDay)
        XCTAssertEqual(TrialCTA.from(metadata: ["trial_cta": "mine"]), .sevenDay)
        XCTAssertEqual(TrialCTA.from(metadata: ["trial_cta": 1]), .sevenDay)
        XCTAssertEqual(TrialCTA.from(metadata: ["trial_cta": "my"]), .my)
        XCTAssertEqual(TrialCTA.from(metadata: ["trial_cta": "your"]), .your)
        XCTAssertEqual(TrialCTA.from(metadata: ["trial_cta": "seven_day"]), .sevenDay)
    }

    /// Every arm names the trial, fits the button on one line and never
    /// carries a dash.
    func testEveryArmNamesTheTrialOnBothSurfaces() {
        for arm in TrialCTA.allCases {
            for surface in [TrialCTA.Surface.onboarding, .paywall] {
                let title = arm.title(surface)
                XCTAssertTrue(["Test", "Probe", "kostenlos"].contains { title.contains($0) }, title)
                XCTAssertLessThanOrEqual(title.count, 24, title)
                XCTAssertFalse(title.contains("\u{2014}"), title)
                XCTAssertFalse(title.contains("\u{2013}"), title)
            }
        }
    }

    /// Switches are on unless RevenueCat says exactly "off".
    func testSwitchesDefaultOn() {
        // The keys set in RevenueCat; renaming one would silently disarm it.
        XCTAssertEqual(RemoteSwitch.allCases.map(\.rawValue), ["att_prompt", "rating_prompt", "challenge"])
        for remoteSwitch in RemoteSwitch.allCases {
            XCTAssertTrue(RemoteConfig.isOn(remoteSwitch, in: nil))
            XCTAssertTrue(RemoteConfig.isOn(remoteSwitch, in: [remoteSwitch.rawValue: "on"]))
            XCTAssertTrue(RemoteConfig.isOn(remoteSwitch, in: [remoteSwitch.rawValue: false]))
            XCTAssertFalse(RemoteConfig.isOn(remoteSwitch, in: [remoteSwitch.rawValue: "off"]))
        }
    }
}
