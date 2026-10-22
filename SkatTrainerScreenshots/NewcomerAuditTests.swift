import XCTest

/// Walks the app as a first-time player who knows no Skat vocabulary: fresh
/// install, every onboarding page, the primer, the tour, the first Quick
/// Session, Home, a room, and a cold relaunch. Like the other capture tests it
/// never calls XCTFail; it records what it could not reach and attaches a
/// screenshot at each step.
@MainActor
final class NewcomerAuditTests: XCTestCase {
    private var app: XCUIApplication!
    private var problems: [String] = []
    private var step = 0

    private func launch(_ args: [String] = []) {
        continueAfterFailure = true
        app = XCUIApplication()
        app.launchArguments = args
        app.launch()
        _ = app.wait(for: .runningForeground, timeout: 30)
        settle(2.0)
    }

    /// A real fresh install: no flags at all.
    func testFreshInstallWalk() {
        launch()
        capture("onb0_first_screen")
        let weiter = app.buttons["Weiter"]
        if !weiter.exists { problems.append("no Weiter on first screen") }
        capture("onb0_tree", tree: true)

        // Pages 0 -> 3 (skill question)
        for page in 1...3 {
            tapButton("Weiter")
            capture("onb\(page)_page")
        }
        // The Weiter button before a choice is made.
        let blocked = app.buttons["Weiter"]
        attach("skill_weiter_enabled_before_choice", "\(blocked.isEnabled)")
        tapButton("Weiter")
        capture("onb3_weiter_tapped_without_choice")
        // Swipe forward without a choice
        app.swipeLeft()
        settle(0.8)
        capture("onb3_swipe_without_choice")

        tapLabelContaining("Ganz neu")
        capture("onb3_ganz_neu_selected")
        tapButton("Weiter")
        capture("onb4_trial_page")
        attach("onb4_tree", app.debugDescription)

        // Free exit
        tapButton("Loslegen")
        settle(1.2)
        capture("primer0")

        // Primer pages
        for page in 1...5 {
            tapButton("Weiter")
            settle(0.6)
            capture("primer\(page)")
        }
        tapButton("An den Tisch")
        settle(1.2)
        capture("tour0")

        for page in 1...3 {
            tapButton("Zeig es mir")
            settle(0.8)
            capture("tour\(page)")
        }
        tapButton("Meine erste Runde starten")
        settle(1.5)
        capture("session_q1")
        runSession()
        capture("session_end")
        let close = app.buttons["Schließen"]
        if close.exists { close.tap() } else if app.buttons["Fertig"].exists { app.buttons["Fertig"].tap() }
        settle(1.5)
        capture("home_first")
        attach("home_tree", app.debugDescription)
        attach("problems", problems.joined(separator: "\n"))
    }

    /// First Home visit after a skipped primer, then the first room and drill.
    func testHomeAndFirstRoom() {
        launch(["-progress.hasOnboarded", "YES", "-skat.skillLevel", "new",
                "-whatsnew.lastSeenVersion", ProcessInfo.processInfo.environment["SCREENSHOT_APP_VERSION"] ?? "1.2.4"])
        capture("home_skipped_primer")
        app.swipeUp()
        settle(0.8)
        capture("home_scrolled")
        app.swipeDown()
        settle(0.5)
        tapLabelContaining("Karten & Reizen")
        capture("room_cards")
        attach("room_tree", app.debugDescription)
        app.swipeUp()
        settle(0.6)
        capture("room_cards_scrolled")
        app.swipeDown()
        // First drill of the room: first button that is not navigation.
        let first = app.buttons.allElementsBoundByIndex.first { b in
            b.exists && b.isHittable && b.frame.width > 250 && b.frame.minY > 200
        }
        first?.tap()
        settle(1.5)
        capture("first_drill")
        attach("drill_tree", app.debugDescription)
        // Flashcard: tap card to flip, then swipe.
        app.swipeLeft()
        settle(0.8)
        capture("first_drill_swiped")
        app.swipeLeft()
        settle(0.8)
        capture("first_drill_swiped2")
        attach("problems", problems.joined(separator: "\n"))
    }

    /// Settings, restore, paywall exit as a free player.
    func testSettingsAndPaywall() {
        launch(["-progress.hasOnboarded", "YES", "-skat.skillLevel", "new", "-skat.hasReadPrimer", "YES",
                "-whatsnew.lastSeenVersion", ProcessInfo.processInfo.environment["SCREENSHOT_APP_VERSION"] ?? "1.2.4"])
        capture("home_free")
        app.buttons["Einstellungen"].firstMatch.tap()
        settle(1.2)
        capture("settings")
        attach("settings_tree", app.debugDescription)
        app.swipeUp()
        settle(0.6)
        capture("settings_scrolled")
        app.swipeDown()
        // dismiss sheet
        app.swipeDown()
        settle(1.0)
        // Upgrade card on Home
        app.swipeUp()
        settle(0.6)
        tapLabelContaining("entdecken")
        settle(1.5)
        capture("paywall")
        attach("paywall_tree", app.debugDescription)
        app.swipeUp()
        settle(0.6)
        capture("paywall_scrolled")
        attach("problems", problems.joined(separator: "\n"))
    }

    // MARK: - Helpers

    private func runSession() {
        for _ in 0..<12 {
            let row = app.buttons.allElementsBoundByIndex.first { b in
                b.exists && b.isHittable && !b.label.isEmpty
                    && !["Weiter", "Fertig", "Schließen", "Zurück"].contains(b.label)
                    && b.frame.width > 200 && b.frame.height >= 40 && b.frame.minY > 150
            }
            guard let row else { break }
            row.tap()
            settle(1.0)
            capture("session_answered")
            if app.buttons["Weiter"].exists {
                app.buttons["Weiter"].tap()
            } else if app.buttons["Fertig"].exists {
                app.buttons["Fertig"].tap()
                settle(1.5)
                return
            }
            settle(0.8)
        }
    }

    private func tapButton(_ label: String) {
        let b = app.buttons[label].firstMatch
        if b.waitForExistence(timeout: 6) {
            b.tap()
            settle(0.8)
        } else {
            problems.append("missing button: \(label)")
        }
    }

    private func tapLabelContaining(_ text: String) {
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        for query in [app.buttons, app.staticTexts, app.otherElements] {
            let match = query.matching(predicate).firstMatch
            if match.waitForExistence(timeout: 4) {
                match.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
                settle(0.9)
                return
            }
        }
        problems.append("could not find: \(text)")
    }

    private func settle(_ seconds: TimeInterval = 1.0) { Thread.sleep(forTimeInterval: seconds) }

    private func capture(_ name: String, tree: Bool = false) {
        step += 1
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = String(format: "%02d_%@", step, name)
        shot.lifetime = .keepAlways
        add(shot)
    }

    private func attach(_ name: String, _ text: String) {
        let note = XCTAttachment(string: text.isEmpty ? "none" : text)
        note.name = name
        note.lifetime = .keepAlways
        add(note)
    }
}
