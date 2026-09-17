import XCTest

/// Captures the App Store screenshot set from the real app, on whatever
/// destination `xcodebuild test` is pointed at. Exists because the iPad shots
/// have to be re-captured whenever a drill layout changes, and re-shooting six
/// screens by hand is how you end up shipping a stale set.
///
/// Run: scripts/capture-screenshots.sh <udid> <out-dir> [prefix]
///
/// Not part of the SkatTrainer scheme's test action — it lives on its own
/// `Screenshots` scheme so the unit-test loop stays fast.
///
/// The test never fails on a missing element. A hard XCTFail makes Xcode spend
/// ten minutes collecting simulator diagnostics before it reports anything,
/// which turns every navigation typo into a very slow question. Instead it
/// records what it could not find and attaches the element tree, so one run
/// tells you both what you got and why the rest is missing.
@MainActor
final class ScreenshotTests: XCTestCase {
    private var app: XCUIApplication!
    private var problems: [String] = []

    override func setUp() {
        continueAfterFailure = true
        app = XCUIApplication()
        // The `-key value` form lands in UserDefaults' argument domain, so the
        // app boots past onboarding without a debug hook in shipping code.
        app.launchArguments = [
            "-progress.hasOnboarded", "YES",
            "-skat.hasReadPrimer", "YES",
            "-skat.skillLevel", "some",
            "-subscription.localProOverride", "YES",
        ]
        // The What's New sheet fires on the first launch after a version bump
        // and covers Home. Marking the CURRENT version as already seen is what
        // suppresses it — any other value still counts as an upgrade — so the
        // capture script passes the real marketing version in.
        if let version = ProcessInfo.processInfo.environment["SCREENSHOT_APP_VERSION"] {
            app.launchArguments += ["-whatsnew.lastSeenVersion", version]
        }
        app.launch()
    }

    func testCaptureAppStoreSet() {
        _ = app.wait(for: .runningForeground, timeout: 30)
        settle()
        dismissWhatsNew()
        capture("05_home")
        attachTree("home")

        if open("Loslegen") {
            capture("01_quick_session")
            if answerQuick("Beim Kreuz-Buben") {
                capture("01_quick_session_answered")
                if advanceQuick(), answerQuick() {
                    capture("01_quick_session_second_answered")
                }
            }
        }
        home()

        if open("Spielarten"), open("Die Struktur lesen") {
            capture("02_struktur")
            if answerHandMatch() {
                capture("02_struktur_answered")
            }
        }
        home()

        if open("Stichspiel"), openStichDecision() {
            capture("03_stich")
            if answerStich() {
                capture("08_stich_answered")
            }
        }
        home()

        if open("Drücken"), open("Dein Skat") {
            capture("04_druecken")
            if answerDiscard() {
                capture("04_druecken_answered")
            }
        }
        home()

        if open("Karten & Reizen") {
            capture("06_karten")
        }

        if !problems.isEmpty {
            let note = XCTAttachment(string: problems.joined(separator: "\n"))
            note.name = "problems"
            note.lifetime = .keepAlways
            add(note)
        }
    }

    // MARK: - Navigation

    /// The What's New sheet fires on the first launch after a version bump and
    /// covers Home completely. Pinning `whatsnew.lastSeenVersion` from the
    /// launch arguments would mean hardcoding the marketing version here and
    /// re-breaking capture on every release, so just dismiss it.
    private func dismissWhatsNew() {
        // Belt and braces for a version the script could not resolve. Dismissing
        // does not mark the release seen, so the sheet returns every time Home
        // reappears; the launch argument above is the real fix.
        let done = app.buttons["Fertig"].firstMatch
        guard done.waitForExistence(timeout: 3) else { return }
        done.tap()
        settle()
    }

    /// Taps the first hittable element whose label starts with `label`.
    /// Home's cards are NavigationLinks with stacked title + subtitle, so the
    /// accessibility label is the whole card, not just the title.
    @discardableResult
    private func open(_ label: String) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS %@", label)
        for query in [app.buttons, app.staticTexts] {
            let match = query.matching(predicate).firstMatch
            guard match.waitForExistence(timeout: 6) else { continue }
            // Tap the centre of the frame rather than the element. SwiftUI
            // cards report isHittable false often enough that trusting it costs
            // a whole capture run, and a coordinate tap lands the same place.
            match.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            settle()
            return true
        }
        problems.append("could not open: \(label)")
        return false
    }

    @discardableResult
    private func openStichDecision() -> Bool {
        let predicate = NSPredicate(
            format: "label BEGINSWITH %@ AND NOT (label CONTAINS %@)",
            "Stich-Entscheidungen",
            "Extra-Runden"
        )
        let match = app.buttons.matching(predicate).firstMatch
        guard match.waitForExistence(timeout: 6) else {
            problems.append("could not open free Stich drill")
            return false
        }
        match.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        settle()
        return true
    }

    /// Pops back to the root, recognising Home by its Get Started card.
    ///
    /// Do NOT just tap navigation-bar button 0 until it runs out: on Home that
    /// button is the Settings gear, so the extra tap opens Settings, and every
    /// later coordinate tap then lands on the Settings sheet while the elements
    /// underneath still answer queries. That failure looks exactly like a
    /// mislabelled drill row, which is a slow thing to debug.
    private func home() {
        for _ in 0..<4 {
            if atHome { return }
            let done = app.buttons["Fertig"].firstMatch
            if done.exists {
                done.tap()
                settle(0.6)
                continue
            }
            let back = app.navigationBars.buttons.element(boundBy: 0)
            guard back.exists, back.identifier != "gearshape" else { return }
            back.tap()
            settle(0.6)
        }
    }

    @discardableResult
    private func answerStich() -> Bool {
        let choices = [
            "Herz bedienen",
            "Eine fremde Farbe spielen",
            "Frei wählen",
            "Trotzdem Herz legen",
            "Trumpf gewinnt",
            "Das Herz-Ass gewinnt immer",
        ]
        for label in choices {
            let choice = app.buttons[label].firstMatch
            guard choice.waitForExistence(timeout: 1) else { continue }
            choice.tap()
            settle()
            return true
        }
        problems.append("could not answer Stich drill")
        return false
    }

    @discardableResult
    private func answerHandMatch() -> Bool {
        let choice = app.buttons["Trumpf"].firstMatch
        guard choice.waitForExistence(timeout: 2) else {
            problems.append("could not answer hand structure")
            return false
        }
        choice.tap()
        settle()
        return true
    }

    @discardableResult
    private func answerDiscard() -> Bool {
        guard tapCard("7 Kreuz"), tapCard("8 Pik") else {
            problems.append("could not select discard cards")
            return false
        }
        let submit = app.buttons["Diese 2 drücken"].firstMatch
        guard submit.waitForExistence(timeout: 2) else {
            problems.append("could not submit discard cards")
            return false
        }
        submit.tap()
        settle()
        return true
    }

    @discardableResult
    private func answerQuick(_ preferred: String? = nil) -> Bool {
        let labels = [
            preferred,
            "Beim Kreuz-Buben",
            "Beim Karo-Buben",
            "Beim Kreuz-Ass",
            "Vorhand",
            "Mittelhand",
            "Hinterhand",
            "Ass",
            "König",
            "Dame",
            "Bube",
            "61 Augen",
            "Keinen Stich",
            "Alle vier Buben",
            "Bedienpflicht",
            "Die Bubenreihenfolge",
            "Jeder Trumpf",
            "Nur ein Ass",
            "Du darfst frei wählen",
            "Du musst passen",
            "Du musst die höchste Karte spielen",
        ].compactMap { $0 }
        for label in labels {
            let choice = app.buttons[label].firstMatch
            if choice.waitForExistence(timeout: 0.5) {
                choice.tap()
                settle()
                return true
            }
        }

        // Quick Session deliberately shuffles its pool, so a capture test
        // cannot rely on one authored label being present. The answer rows
        // are the only wide, medium-height buttons in the drill body. Pick
        // the first one when the shuffled item uses a different prompt.
        let navigationLabels = Set(["Weiter", "Fertig", "Schließen", "Zurück"])
        let answer = app.buttons.allElementsBoundByIndex.first { button in
            let frame = button.frame
            return button.exists
                && button.isHittable
                && !button.label.isEmpty
                && !navigationLabels.contains(button.label)
                && frame.width > 250
                && frame.height >= 40
                && frame.height <= 120
                && frame.minY > 120
        }
        if let answer {
            answer.tap()
            settle()
            return true
        }
        problems.append("could not answer Quick Session")
        return false
    }

    @discardableResult
    private func advanceQuick() -> Bool {
        let next = app.buttons["Weiter"].firstMatch
        guard next.waitForExistence(timeout: 2) else {
            problems.append("could not advance Quick Session")
            return false
        }
        next.tap()
        settle()
        return true
    }

    private func tapCard(_ label: String) -> Bool {
        let predicate = NSPredicate(format: "label == %@", label)
        for query in [app.staticTexts, app.otherElements, app.buttons] {
            let match = query.matching(predicate).firstMatch
            if match.waitForExistence(timeout: 2) {
                match.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
                settle(0.4)
                return true
            }
        }
        return false
    }

    private var atHome: Bool {
        app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "DIE R")).firstMatch.exists
    }

    /// Let the push transition and any entrance animation finish before the
    /// shutter: a mid-transition frame is a blurred, half-offset screenshot.
    private func settle(_ seconds: TimeInterval = 1.6) {
        Thread.sleep(forTimeInterval: seconds)
    }

    // MARK: - Capture

    private func capture(_ name: String) {
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    private func attachTree(_ name: String) {
        let tree = XCTAttachment(string: app.debugDescription)
        tree.name = "tree_\(name)"
        tree.lifetime = .keepAlways
        add(tree)
    }
}
