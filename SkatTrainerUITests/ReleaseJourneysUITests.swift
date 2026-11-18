import XCTest

/// The release gate's journeys (`qa-gate run`, `~/ios/qa/README.md`). They run
/// once per persona, the unfolded iPhone Duo and the iPad included, so controls
/// are found by their German label (the app has no identifiers except
/// `stats.answers`) and Home is scrolled to rather than assumed on screen.
/// They assert reachability; the FleetQA oracles judge each screen. The core
/// loop also asserts what it counted.
@MainActor
final class ReleaseJourneysUITests: XCTestCase {
    private let bundleID = "com.jackwallner.skat"

    /// Past onboarding and the primer, no What's New sheet.
    private let onboarded = [
        "-progress.hasOnboarded", "YES",
        "-skat.hasReadPrimer", "YES",
        "-skat.skillLevel", "played",
        "-skat.suppressWhatsNew", "YES",
        "-whatsnew.lastSeenVersion", "1.3.1",
    ]

    override func setUp() {
        continueAfterFailure = false
    }

    // MARK: - Journeys

    func test1FirstRunThroughOnboardingToHome() {
        let app = XCUIApplication(bundleIdentifier: bundleID)
        QA.launch(app, arguments: [
            "-progress.hasOnboarded", "NO",
            "-skat.skillLevel", "",
            "-skat.suppressWhatsNew", "YES",
        ])
        XCTAssertTrue(app.buttons["Weiter"].waitForExistence(timeout: 20))
        QA.checkpoint(app, "onboarding-welcome")
        for page in 1...2 {
            app.buttons["Weiter"].tap()
            XCTAssertTrue(app.buttons["Weiter"].waitForExistence(timeout: 5))
            QA.checkpoint(app, "onboarding-page-\(page)")
        }
        app.buttons["Weiter"].tap()
        let skill = label("Schon gespielt", in: app.buttons)
        XCTAssertTrue(skill.waitForExistence(timeout: 10))
        QA.checkpoint(app, "onboarding-skill")
        skill.tap()
        app.buttons["Weiter"].tap()
        let exit = app.buttons["Loslegen"]
        XCTAssertTrue(exit.waitForExistence(timeout: 10))
        requirePrice(in: app, "the trial page shows the billed price")
        QA.checkpoint(app, "onboarding-trial-offer", paywall: true)
        exit.tap()
        let skipTour = label("Tour überspringen", in: app.buttons)
        XCTAssertTrue(skipTour.waitForExistence(timeout: 10))
        QA.checkpoint(app, "onboarding-tour")
        skipTour.tap()
        homeShown(app)
        QA.checkpoint(app, "home-first-run")
    }

    func test2ReturnVisitInterruptedAndRelaunched() {
        let app = launchOnboarded()
        QA.checkpoint(app, "home-return")
        open("Karten & Reizen", in: app)
        XCTAssertTrue(label("Die Karten kennenlernen", in: app.buttons).waitForExistence(timeout: 10))
        QA.checkpoint(app, "room-cards")
        QA.interrupt(app)
        QA.checkpoint(app, "room-after-background")
        QA.relaunch(app)
        homeShown(app)
        QA.checkpoint(app, "home-after-relaunch")
    }

    func test3PaywallShownAndDismissed() {
        let app = launchOnboarded()
        app.buttons["Einstellungen"].tap()
        let discover = label("Skat+ entdecken", in: app.buttons)
        scroll(until: discover, in: app)
        QA.checkpoint(app, "settings")
        discover.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        if !app.buttons["Schließen"].waitForExistence(timeout: 15) { attach("no-paywall-tree", app.debugDescription) }
        XCTAssertTrue(app.buttons["Schließen"].exists, "the paywall opened")
        requirePrice(in: app, "the paywall shows the billed price")
        QA.checkpoint(app, "paywall", paywall: true)
        app.buttons["Schließen"].tap()
        XCTAssertTrue(app.buttons["Fertig"].waitForExistence(timeout: 10))
        QA.checkpoint(app, "paywall-dismissed")
        app.buttons["Fertig"].tap()
        homeShown(app)
        QA.checkpoint(app, "home-after-paywall")
    }

    /// The one job: play a real Stichspiel hand, and the answer is counted on
    /// Dein Fortschritt and is still counted after the app is killed.
    func testCoreLoopStichspielAnswerCountsAndSurvivesRelaunch() {
        let app = launchOnboarded()
        let before = answerCount(in: app)
        QA.checkpoint(app, "core-start")

        open("Stichspiel", in: app)
        open("Stich-Entscheidungen", in: app)
        let pick = app.buttons["Herz bedienen"].firstMatch
        XCTAssertTrue(pick.waitForExistence(timeout: 10))
        QA.checkpoint(app, "core-hand")
        pick.tap()
        let next = app.buttons["Weiter"].firstMatch
        XCTAssertTrue(next.waitForExistence(timeout: 10))
        QA.checkpoint(app, "core-hand-answered")
        next.tap()
        XCTAssertTrue(app.buttons["Frei wählen"].waitForExistence(timeout: 10), "the next hand is dealt")
        goHome(app)

        XCTAssertEqual(answerCount(in: app), before + 1, "the answer is counted")
        QA.checkpoint(app, "core-counted")

        QA.relaunch(app)
        homeShown(app)
        XCTAssertEqual(answerCount(in: app), before + 1, "the count survives a relaunch")
        QA.checkpoint(app, "core-after-relaunch")
    }

    // MARK: - Steps

    private func launchOnboarded(journey: String = #function) -> XCUIApplication {
        let app = XCUIApplication(bundleIdentifier: bundleID)
        QA.launch(app, arguments: onboarded, journey: journey)
        homeShown(app)
        return app
    }

    private func homeShown(_ app: XCUIApplication) {
        XCTAssertTrue(app.buttons["Einstellungen"].waitForExistence(timeout: 20), "Home never rendered")
    }

    private var homeMarker: NSPredicate { NSPredicate(format: "label BEGINSWITH %@", "DIE R") }

    private func atHome(_ app: XCUIApplication) -> Bool {
        app.staticTexts.matching(homeMarker).firstMatch.exists
    }

    /// Pops back to Home. On Home the first navigation-bar button is the
    /// Settings gear, so a back tap only happens while Home is not showing.
    private func goHome(_ app: XCUIApplication) {
        for _ in 0..<5 {
            if atHome(app) { return }
            let back = app.buttons["BackButton"].exists ? app.buttons["BackButton"] : app.navigationBars.buttons.firstMatch
            guard back.exists else { return }
            back.tap()
            Thread.sleep(forTimeInterval: 0.8)
        }
    }

    /// A control whose label contains `text` (Home's cards label the whole card).
    private func label(_ text: String, in query: XCUIElementQuery) -> XCUIElement {
        query.matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
    }

    /// Scrolls Home or a list until the control can be tapped, then taps it.
    private func open(_ text: String, in app: XCUIApplication) {
        let button = label(text, in: app.buttons)
        let title = label(text, in: app.staticTexts)
        _ = button.waitForExistence(timeout: 5)
        for _ in 0..<8 {
            if (button.exists && button.isHittable) || (title.exists && title.isHittable) { break }
            QA.swipe(app.windows.firstMatch, .up)
            Thread.sleep(forTimeInterval: 0.5)
        }
        let target = button.exists ? button : title
        XCTAssertTrue(target.waitForExistence(timeout: 10), "could not find \(text)")
        target.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        Thread.sleep(forTimeInterval: 1.2)
    }

    private func requirePrice(in app: XCUIApplication, _ message: String) {
        // Whatever currency the storefront gives: an amount like 6,99 or 6.99.
        let price = app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", ".*[0-9][.,][0-9]{2}.*")).firstMatch
        if !price.waitForExistence(timeout: 30) { attach("no-price-tree", app.debugDescription) }
        XCTAssertTrue(price.exists, message)
    }

    private func attach(_ name: String, _ text: String) {
        let item = XCTAttachment(string: text)
        item.name = name
        item.lifetime = .keepAlways
        add(item)
    }

    private func scroll(until target: XCUIElement, in app: XCUIApplication) {
        // The sheet is still sliding in; swiping now would scroll past the row.
        _ = target.waitForExistence(timeout: 10)
        for _ in 0..<10 {
            if target.exists, target.isHittable { return }
            QA.swipe(app.windows.firstMatch, .up)
            Thread.sleep(forTimeInterval: 0.5)
        }
        XCTAssertTrue(target.exists, "never scrolled to \(target)")
    }

    /// The answers shown on Dein Fortschritt, 0 while it shows its empty
    /// state. Returns to Home.
    private func answerCount(in app: XCUIApplication, journey: String = #function) -> Int {
        goHome(app)
        open("Tage am Stück", in: app)
        defer { goHome(app) }
        let value = app.descendants(matching: .any)["stats.answers"].firstMatch
        if value.waitForExistence(timeout: 8) {
            QA.checkpoint(app, "progress", journey: journey)
            return Int(value.label) ?? -1
        }
        attach("progress-tree", app.debugDescription)
        XCTAssertTrue(app.staticTexts["Noch keine Übung"].exists, "Dein Fortschritt shows neither a count nor its empty state")
        QA.checkpoint(app, "progress-empty", journey: journey)
        return 0
    }
}
