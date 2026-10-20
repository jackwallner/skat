import XCTest

/// Drives the generated practice skills and the progress screens for the UX
/// audit. Like ScreenshotTests it never calls XCTFail; it records what it
/// could not reach and attaches screenshots either way.
@MainActor
final class AuditCaptureTests: XCTestCase {
    private var app: XCUIApplication!
    private var problems: [String] = []

    private func launch(extra: [String] = []) {
        continueAfterFailure = true
        app = XCUIApplication()
        app.launchArguments = [
            "-progress.hasOnboarded", "YES",
            "-skat.hasReadPrimer", "YES",
            "-skat.skillLevel", "some",
            "-subscription.localProOverride", "YES",
            "-whatsnew.lastSeenVersion", ProcessInfo.processInfo.environment["SCREENSHOT_APP_VERSION"] ?? "1.2.4",
        ] + extra
        app.launch()
        _ = app.wait(for: .runningForeground, timeout: 30)
        settle()
    }

    func testSkillsAndProgress() {
        launch()
        capture("home")
        let skills = ["Augen zählen", "Wer sticht?", "Spitzen zählen", "Handmuster lesen", "Stichspiel üben"]
        for (index, skill) in skills.enumerated() {
            guard open("Endlos"), open(skill) else { continue }
            capture("endless_\(index)_question")
            var sawMiss = false
            for _ in 0..<5 where !sawMiss {
                guard let answer = answerRow() else { break }
                answer.tap()
                settle(1.0)
                if app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Warum nicht")).firstMatch.exists
                    || app.otherElements.matching(NSPredicate(format: "label BEGINSWITH %@", "Warum nicht")).firstMatch.exists {
                    sawMiss = true
                    capture("endless_\(index)_miss_note")
                } else if app.buttons["Weiter"].exists {
                    if index == 0 { capture("endless_\(index)_correct") }
                    app.buttons["Weiter"].tap()
                    settle(0.8)
                }
            }
            home()
        }
        if open("Tage am Stück") {
            capture("stats")
            home()
        }
        if open("Karten & Reizen") {
            capture("room_mastery")
        }
        attach("problems", problems.joined(separator: "\n"))
    }

    func testLargeTextMissNote() {
        launch(extra: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXL"])
        capture("axxxl_home")
        if open("Endlos"), open("Wer sticht?") {
            capture("axxxl_trick_question")
            for _ in 0..<3 {
                guard let answer = answerRow() else { break }
                answer.tap()
                settle(1.0)
                capture("axxxl_trick_answered")
                if app.buttons["Weiter"].exists { app.buttons["Weiter"].tap() }
                settle(0.6)
            }
        }
        attach("problems", problems.joined(separator: "\n"))
    }

    // MARK: - Helpers

    private func answerRow() -> XCUIElement? {
        let skip = Set(["Weiter", "Fertig", "Schließen", "Zurück"])
        return app.buttons.allElementsBoundByIndex.first { button in
            button.exists && button.isHittable && !button.label.isEmpty && !skip.contains(button.label)
                && button.frame.width > 200 && button.frame.height >= 40 && button.frame.minY > 150
        }
    }

    @discardableResult
    private func open(_ label: String) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS %@", label)
        for query in [app.buttons, app.staticTexts] {
            let match = query.matching(predicate).firstMatch
            guard match.waitForExistence(timeout: 5) else { continue }
            match.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            settle()
            return true
        }
        problems.append("could not open: \(label)")
        return false
    }

    private func home() {
        for _ in 0..<4 {
            if app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "DIE R")).firstMatch.exists { return }
            let done = app.buttons["Fertig"].firstMatch
            if done.exists { done.tap(); settle(0.6); continue }
            let back = app.navigationBars.buttons.element(boundBy: 0)
            guard back.exists, back.identifier != "gearshape" else { return }
            back.tap()
            settle(0.6)
        }
    }

    private func settle(_ seconds: TimeInterval = 1.4) { Thread.sleep(forTimeInterval: seconds) }

    private func capture(_ name: String) {
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = name
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
