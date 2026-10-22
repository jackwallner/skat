import XCTest

/// Walks the app as a player who knows Skat and returns to repeat the core
/// tasks: endless practice, the 90 second run, Fehler wiederholen after a
/// relaunch, the Skat-Minute, the Meistertisch, the progress page and
/// Settings. Like the other capture tests it never calls XCTFail; it records
/// what it could not reach and attaches a screenshot at each step.
@MainActor
final class ExperiencedAuditTests: XCTestCase {
    private var app: XCUIApplication!
    private var problems: [String] = []
    private var notes: [String] = []
    private var step = 0

    private var version: String {
        ProcessInfo.processInfo.environment["SCREENSHOT_APP_VERSION"] ?? "1.2.4"
    }

    private func launch(member: Bool, extra: [String] = [], fresh: Bool = true) {
        continueAfterFailure = true
        app = XCUIApplication()
        var args = [
            "-progress.hasOnboarded", "YES",
            "-skat.skillLevel", "played",
            "-skat.hasReadPrimer", "YES",
            "-whatsnew.lastSeenVersion", version,
            "-skat.suppressWhatsNew",
        ]
        if member { args += ["-subscription.localProOverride", "YES"] }
        app.launchArguments = args + extra
        app.launch()
        _ = app.wait(for: .runningForeground, timeout: 30)
        settle(2.0)
    }

    private func relaunch() {
        app.terminate()
        settle(1.0)
        app.launch()
        _ = app.wait(for: .runningForeground, timeout: 30)
        settle(2.0)
    }

    // MARK: - Tests

    /// Endless practice as a repeat task: pick a skill, answer, miss on
    /// purpose, finish, come back, and see what the app remembers.
    func testEndlessThenReturnVisit() {
        launch(member: true)
        capture("home_member")
        attach("home_tree", app.debugDescription)
        scrollTrainingRow()
        capture("home_training_row_scrolled")

        guard open("Endlos") else { return finishNotes() }
        capture("endless_picker")
        guard open("Wer sticht?") else { return finishNotes() }
        capture("endless_q1")
        attach("endless_q1_tree", app.debugDescription)

        var taps = 0
        let started = Date()
        for i in 0..<8 {
            guard let answer = answerRow(last: i % 3 == 2) else { problems.append("no answer row at q\(i + 1)"); break }
            answer.tap(); taps += 1
            settle(0.9)
            if i == 1 || i == 2 { capture("endless_answered_\(i + 1)") }
            guard tapIfExists("Weiter") else { problems.append("no Weiter after q\(i + 1)"); break }
            taps += 1
            settle(0.7)
        }
        notes.append("8 endless questions: \(taps) taps, \(Int(Date().timeIntervalSince(started))) s including settle waits")
        capture("endless_after8")

        // Quit via Fertig.
        let done = app.buttons["Fertig"].firstMatch
        if done.exists { done.tap() } else { problems.append("no Fertig in an endless run") }
        settle(1.5)
        capture("endless_complete")
        attach("endless_complete_tree", app.debugDescription)
        // Does the completion screen offer "again"? Record every button.
        notes.append("complete buttons: " + app.buttons.allElementsBoundByIndex.map { $0.label }.joined(separator: " | "))
        tapIfExists("Fertig")
        settle(1.0)
        capture("endless_picker_after")
        goHome()
        capture("home_after_run")

        // Return visit: cold relaunch with the same data.
        relaunch()
        capture("return_home")
        attach("return_home_tree", app.debugDescription)
        scrollTrainingRow()
        capture("return_training_row")
        if open("Fehler wiederholen") {
            capture("review_q1")
            for i in 0..<3 {
                guard let answer = answerRow(last: false) else { break }
                answer.tap()
                settle(0.8)
                if i == 0 { capture("review_answered") }
                tapIfExists("Weiter")
                tapIfExists("Fertig")
                settle(0.6)
            }
            capture("review_state")
            tapIfExists("Schließen")
            settle(1.2)
            capture("review_complete")
            tapIfExists("Fertig")
            settle(0.8)
        } else {
            problems.append("Fehler wiederholen tile not found after relaunch")
        }
        goHome()
        if open("Tage am Stück") {
            capture("stats")
            attach("stats_tree", app.debugDescription)
            app.swipeUp()
            settle(0.6)
            capture("stats_scrolled")
        }
        finishNotes()
    }

    /// The 90 second run: leaving early, and running out the clock.
    func testTimedRun() {
        launch(member: true)
        scrollTrainingRow()
        guard open("90") else { return finishNotes() }
        capture("timed_q1")
        attach("timed_tree", app.debugDescription)
        for _ in 0..<2 {
            answerRow(last: false)?.tap()
            settle(0.8)
            tapIfExists("Weiter")
            settle(0.6)
        }
        capture("timed_midrun")
        // Is there any way out other than the back button?
        notes.append("timed nav bar buttons: " + app.navigationBars.buttons.allElementsBoundByIndex.map { "\($0.label)/\($0.identifier)" }.joined(separator: " | "))
        let back = app.navigationBars.buttons.element(boundBy: 0)
        if back.exists {
            back.tap()
            settle(1.0)
            capture("timed_after_back")
        }
        scrollTrainingRow()
        capture("timed_home_after_back")
        // Second go: run the clock out.
        if open("90") {
            answerRow(last: false)?.tap()
            settle(0.8)
            tapIfExists("Weiter")
            settle(85)
            capture("timed_near_end")
            settle(10)
            capture("timed_end")
            attach("timed_end_tree", app.debugDescription)
            tapIfExists("Fertig")
            settle(1.0)
            scrollTrainingRow()
            capture("timed_home_after_end")
        }
        finishNotes()
    }

    /// The daily Skat-Minute, its result and the archive.
    func testSkatMinute() {
        launch(member: true)
        scrollTrainingRow()
        guard open("Minute") else { return finishNotes() }
        capture("minute_hub")
        attach("minute_hub_tree", app.debugDescription)
        guard open("Heutige Runde starten") else { return finishNotes() }
        capture("minute_q1")
        var answered = 0
        for i in 0..<6 {
            guard let answer = answerRow(last: i == 1) else { break }
            answer.tap(); answered += 1
            settle(0.8)
            if i == 0 { capture("minute_answered") }
            if !tapIfExists("Weiter") { tapIfExists("Fertig") }
            settle(0.8)
        }
        notes.append("minute answered \(answered)")
        capture("minute_result")
        attach("minute_result_tree", app.debugDescription)
        app.swipeUp()
        settle(0.6)
        capture("minute_result_scrolled")
        notes.append("result buttons: " + app.buttons.allElementsBoundByIndex.map { $0.label }.joined(separator: " | "))
        tapIfExists("Fertig")
        settle(1.0)
        capture("minute_hub_after")
        app.swipeUp()
        settle(0.6)
        capture("minute_archive")
        // Re-open yesterday from the archive.
        let rows = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Spielen"))
        if rows.count > 0 {
            rows.element(boundBy: 0).tap()
            settle(1.0)
            capture("minute_archive_day")
        } else {
            problems.append("no playable archive row")
        }
        finishNotes()
    }

    /// Meistertisch and a few drills of each kind as a member.
    func testMemberRoomsAndDrills() {
        launch(member: true)
        app.swipeUp()
        settle(0.6)
        capture("home_rooms")
        guard open("Der Meistertisch") else { return finishNotes() }
        capture("master_room")
        attach("master_tree", app.debugDescription)
        app.swipeUp()
        settle(0.6)
        capture("master_room_scrolled")
        app.swipeDown()
        if let first = firstDrillButton() {
            first.tap()
            settle(1.5)
            capture("master_drill_1")
            attach("master_drill_tree", app.debugDescription)
            for i in 0..<3 {
                if let answer = answerRow(last: false) {
                    answer.tap()
                    settle(0.8)
                    if i == 0 { capture("master_drill_answered") }
                    tapIfExists("Weiter")
                    tapIfExists("Fertig")
                } else {
                    app.swipeLeft()
                }
                settle(0.7)
            }
            capture("master_drill_state")
        } else {
            problems.append("no drill button in Meistertisch")
        }
        goHome()
        if open("Drücken") {
            capture("discard_room")
            if let first = firstDrillButton() {
                first.tap()
                settle(1.5)
                capture("discard_drill")
                attach("discard_drill_tree", app.debugDescription)
            }
        }
        finishNotes()
    }

    /// An experienced player on the free tier: which repeat tasks are gated.
    func testFreeTier() {
        launch(member: false)
        capture("free_home")
        scrollTrainingRow()
        capture("free_training_row")
        notes.append("free tiles: " + app.buttons.allElementsBoundByIndex.map { $0.label }.joined(separator: " | "))
        if open("Endlos") {
            capture("free_endless_paywall")
            attach("free_paywall_tree", app.debugDescription)
        }
        if !tapIfExists("Schließen") { app.swipeDown() }
        settle(1.2)
        capture("free_after_paywall")
        app.swipeUp()
        settle(0.6)
        if open("Karten & Reizen") {
            capture("free_room")
            app.swipeUp()
            settle(0.6)
            capture("free_room_scrolled")
        }
        finishNotes()
    }

    /// Settings as a member, including the Skatabend page and reset dialog.
    func testMemberSettings() {
        launch(member: true)
        app.buttons["Einstellungen"].firstMatch.tap()
        settle(1.2)
        capture("settings_member")
        attach("settings_tree", app.debugDescription)
        app.swipeUp()
        settle(0.6)
        capture("settings_member_scrolled")
        app.swipeDown()
        settle(0.4)
        if open("Skatabend-Vorbereitung") {
            capture("gamenight")
            attach("gamenight_tree", app.debugDescription)
            app.swipeUp()
            settle(0.6)
            capture("gamenight_scrolled")
            let back = app.navigationBars.buttons.element(boundBy: 0)
            if back.exists { back.tap() }
            settle(0.6)
        }
        if open("Fortschritt zurücksetzen") {
            capture("reset_alert")
            tapIfExists("Abbrechen")
        }
        finishNotes()
    }

    /// Large text on the screens a returning player lives in.
    /// The post-update note a returning player meets after a version bump.
    func testReturnAfterUpdateWhatsNew() {
        continueAfterFailure = true
        app = XCUIApplication()
        app.launchArguments = ["-progress.hasOnboarded", "YES", "-skat.skillLevel", "played",
                               "-skat.hasReadPrimer", "YES", "-whatsnew.lastSeenVersion", "1.0.0"]
        app.launch()
        settle(3.0)
        capture("whatsnew_sheet")
        attach("whatsnew_tree", app.debugDescription)
        app.swipeUp()
        settle(0.6)
        capture("whatsnew_scrolled")
        finishNotes()
    }

    func testLargeTextRepeatTasks() {
        launch(member: true, extra: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXL"])
        capture("axl_home")
        app.swipeUp()
        settle(0.6)
        capture("axl_home_scrolled")
        app.swipeDown()
        if open("Endlos") {
            capture("axl_picker")
            if open("Spitzen zählen") {
                capture("axl_question")
                answerRow(last: false)?.tap()
                settle(0.9)
                capture("axl_answered")
            }
        }
        finishNotes()
    }

    // MARK: - Helpers

    private func finishNotes() {
        attach("problems", problems.joined(separator: "\n"))
        attach("notes", notes.joined(separator: "\n"))
    }

    private func scrollTrainingRow() {
        // The tile row scrolls sideways; swipe at the height of the tiles.
        let tile = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Endlos")).firstMatch
        if tile.exists {
            tile.swipeLeft()
            settle(0.6)
        }
    }

    private func firstDrillButton() -> XCUIElement? {
        app.buttons.allElementsBoundByIndex.first { b in
            b.exists && b.isHittable && b.frame.width > 250 && b.frame.minY > 200 && !b.label.isEmpty
        }
    }

    @discardableResult
    private func answerRow(last: Bool) -> XCUIElement? {
        let skip = Set(["Weiter", "Fertig", "Schließen", "Zurück"])
        let rows = app.buttons.allElementsBoundByIndex.filter { button in
            button.exists && button.isHittable && !button.label.isEmpty && !skip.contains(button.label)
                && button.frame.width > 200 && button.frame.height >= 40 && button.frame.minY > 150
        }
        return last ? rows.last : rows.first
    }

    @discardableResult
    private func tapIfExists(_ label: String) -> Bool {
        let b = app.buttons[label].firstMatch
        guard b.exists, b.isHittable else { return false }
        b.tap()
        settle(0.6)
        return true
    }

    @discardableResult
    private func open(_ label: String) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS %@", label)
        for query in [app.buttons, app.staticTexts] {
            let match = query.matching(predicate).firstMatch
            guard match.waitForExistence(timeout: 5) else { continue }
            match.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            settle(1.2)
            return true
        }
        problems.append("could not open: \(label)")
        return false
    }

    private func goHome() {
        for _ in 0..<5 {
            if app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "DIE R")).firstMatch.exists { return }
            if app.buttons["Fertig"].firstMatch.exists { app.buttons["Fertig"].firstMatch.tap(); settle(0.6); continue }
            let back = app.navigationBars.buttons.element(boundBy: 0)
            guard back.exists, back.identifier != "gearshape" else { return }
            back.tap()
            settle(0.6)
        }
    }

    private func settle(_ seconds: TimeInterval = 1.0) { Thread.sleep(forTimeInterval: seconds) }

    private func capture(_ name: String) {
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
