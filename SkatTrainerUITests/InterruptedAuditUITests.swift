import XCTest

/// UX audit probes for the persona "a tired, busy player who is interrupted
/// mid-task and returns later, expecting state and context to survive".
///
/// Two kinds of interruption are driven on purpose, because they behave
/// differently: backgrounding (Home button, then reactivate; the process lives)
/// and a kill (terminate, then launch; iOS does this to backgrounded apps all
/// the time, and it is what "returns later" usually means).
///
/// Like the screenshot tests these never fail on a missing element: they record
/// what they saw as `observations` and attach screenshots either way, so one run
/// shows what survived and what did not. Tests are lettered so the first-run
/// flow runs before any test that passes `-progress.hasOnboarded`.
@MainActor
final class InterruptedAuditUITests: XCTestCase {
    private var app: XCUIApplication!
    private var observations: [String] = []

    private static let bundleID = "com.jackwallner.skat"

    /// Past onboarding. The What's New sheet and Apple's rating prompt are held
    /// back so neither covers the screen being probed. The valueless flag goes
    /// last so it cannot swallow the next argument.
    private func onboarded(pro: Bool = false, whatsNew: Bool = false) -> [String] {
        var args = [
            "-progress.hasOnboarded", "YES",
            "-skat.hasReadPrimer", "YES",
            "-skat.skillLevel", "some",
            "-skat.rc.rating_prompt", "off",
        ]
        if pro { args += ["-subscription.localProOverride", "YES"] }
        if whatsNew {
            args += ["-whatsnew.lastSeenVersion", "1.0.0"]
        } else {
            args += ["-whatsnew.lastSeenVersion", "1.3.1", "-skat.suppressWhatsNew"]
        }
        return args
    }

    // MARK: - A: onboarding interrupted

    func testA_OnboardingInterruption() {
        defer { flush("A_onboarding") }
        launch([])
        capture("A01_first_launch")
        note("A01 first launch lands on: \(onboardingPage())")
        attach("A01_small_targets", smallTargets())

        // Three value pages, then the skill question.
        for _ in 0..<3 { tap("Weiter") }
        note("A02 after three Weiter taps: \(onboardingPage())")
        tap("Ganz neu")
        capture("A02_skill_selected")
        tap("Weiter")
        capture("A03_trial_page")
        note("A03 reached: \(onboardingPage())")
        attach("A03_buttons", buttonDump())
        attach("A03_small_targets", smallTargets())
        attach("A03_tree", app.debugDescription)

        // Backgrounded: the process lives.
        backgroundAndReturn(seconds: 5)
        capture("A04_after_background")
        note("A04 after 5 s in the background: \(onboardingPage())")

        // Killed: iOS does this to a backgrounded app.
        killAndRelaunch()
        capture("A05_after_kill_on_trial_page")
        note("A05 after kill while on the trial page: \(onboardingPage())")

        for _ in 0..<3 { tap("Weiter") }
        capture("A06_skill_page_after_relaunch")
        let ganzNeu = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Ganz neu")).firstMatch
        note("A06 skill page after relaunch: \(onboardingPage()); 'Ganz neu' still selected: \(ganzNeu.exists && ganzNeu.isSelected)")

        // Trial decision made ("Loslegen"), then the primer for a new player.
        tap("Weiter")
        tap("Loslegen")
        capture("A07_primer_page_one")
        note("A07 after the free exit: primer visible: \(app.buttons["Für später überspringen"].exists)")
        tap("Weiter")
        capture("A08_primer_page_two")
        killAndRelaunch()
        capture("A09_after_kill_inside_primer")
        note("A09 after kill inside the primer: \(onboardingPage())")

        // Experienced player: skill question, free exit, straight to the tour.
        for _ in 0..<3 { tap("Weiter") }
        tap("Schon gespielt")
        tap("Weiter")
        tap("Loslegen")
        capture("A10_tour_page_one")
        note("A10 tour visible: \(app.buttons["Zeig es mir"].exists)")
        tap("Zeig es mir")
        capture("A11_tour_page_two")
        killAndRelaunch()
        capture("A12_after_kill_inside_tour")
        note("A12 after kill inside the tour: \(onboardingPage())")
    }

    // MARK: - B: flashcard deck interrupted

    func testB_FlashcardDeckInterruption() {
        defer { flush("B_deck") }
        launch(onboarded())
        capture("B00_home_before")
        attach("B00_home_small_targets", smallTargets())
        attach("B00_home_tree", app.debugDescription)
        note("B00 home statistics before: \(chipLabels())")

        guard openRoomDrill(room: "Karten & Reizen", drill: "Die Karten kennenlernen") else { return }
        capture("B01_deck_start")
        note("B01 deck progress: \(deckProgress())")
        attach("B01_small_targets", smallTargets())
        attach("B01_tree", app.debugDescription)
        for _ in 0..<3 { swipeCardRight() }
        capture("B02_deck_after_three_cards")
        note("B02 deck progress after three cards: \(deckProgress())")

        backgroundAndReturn(seconds: 6)
        capture("B03_deck_after_background")
        note("B03 deck progress after 6 s in the background: \(deckProgress())")

        killAndRelaunch()
        capture("B04_home_after_kill")
        note("B04 home after kill: \(chipLabels())")
        guard openRoomDrill(room: "Karten & Reizen", drill: "Die Karten kennenlernen", screenshotRoom: "B05_room_after_kill") else { return }
        capture("B06_deck_after_kill")
        note("B06 deck progress after kill and reopen: \(deckProgress())")
    }

    // MARK: - C: Loslegen (daily quick session) interrupted

    func testC_QuickSessionInterruption() {
        defer { flush("C_quick") }
        launch(onboarded())
        guard tap("Eine kurze Runde") else { return }
        capture("C01_session_start")
        let firstBefore = questionTexts()
        note("C01 progress: \(sessionProgress()); question text: \(firstBefore)")
        attach("C01_small_targets", smallTargets())
        attach("C01_tree", app.debugDescription)
        for _ in 0..<3 { answerAndAdvance() }
        capture("C02_session_after_three")
        note("C02 progress after three answers: \(sessionProgress())")

        backgroundAndReturn(seconds: 6)
        capture("C03_after_background")
        note("C03 progress after 6 s in the background: \(sessionProgress())")

        killAndRelaunch()
        capture("C04_home_after_kill")
        note("C04 Loslegen card offered again: \(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Eine kurze Runde")).firstMatch.exists); \(chipLabels())")
        guard tap("Eine kurze Runde") else { return }
        capture("C05_session_after_kill")
        let firstAfter = questionTexts()
        note("C05 progress after kill and reopen: \(sessionProgress()); question text: \(firstAfter)")
        note("C05 same first question as before the kill: \(firstBefore == firstAfter)")
    }

    // MARK: - D: all ten answered, interrupted before the last tap

    func testD_QuickSessionFinishLine() {
        defer { flush("D_finish_line") }
        launch(onboarded())
        note("D00 home before: \(chipLabels())")
        guard tap("Eine kurze Runde") else { return }
        for number in 1...10 {
            guard answerAndAdvance(advance: number < 10) else { break }
        }
        capture("D01_ten_answered_not_finished")
        note("D01 last answer graded; Fertig button on screen: \(app.buttons["Fertig"].exists)")
        killAndRelaunch()
        capture("D02_home_after_kill")
        note("D02 after the kill, Loslegen card offered again: \(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Eine kurze Runde")).firstMatch.exists); done card shown: \(has("heutige Runde ist geschafft")); \(chipLabels())")
    }

    // MARK: - E: a finished deck survives (positive control)

    func testE_CompletedDeckSurvives() {
        defer { flush("E_completed") }
        launch(onboarded())
        guard openRoomDrill(room: "Karten & Reizen", drill: "Die Karten kennenlernen") else { return }
        var swipes = 0
        while swipes < 16, !has("Stapel geschafft") {
            swipeCardRight()
            swipes += 1
        }
        settle(1)
        capture("E01_deck_complete")
        note("E01 completion screen after \(swipes) swipes: \(has("Stapel geschafft"))")
        tap("Fertig")
        capture("E02_room_after_complete")
        let back = app.navigationBars.buttons.element(boundBy: 0)
        if back.exists { back.tap(); settle(1.2) }
        capture("E03_home_after_complete")
        note("E03 home after finishing the deck: \(chipLabels())")
        killAndRelaunch()
        capture("E04_home_after_kill")
        note("E04 home after kill: \(chipLabels())")
    }

    // MARK: - F: half-written feedback

    func testF_FeedbackDraft() {
        defer { flush("F_feedback") }
        launch(onboarded())
        guard tap("Einstellungen") else { return }
        capture("F01_settings")
        attach("F01_small_targets", smallTargets())
        guard tap("Feedback senden", scroll: true) else { return }
        let editor = app.textViews.firstMatch
        guard editor.waitForExistence(timeout: 6) else {
            note("F02 feedback editor not found")
            return
        }
        editor.tap()
        editor.typeText("Der Entwurf ist mir wichtig. Weiter schreibe ich nach dem Anruf.")
        capture("F02_draft_typed")
        note("F02 draft typed: \(editor.value as? String ?? "nil")")
        attach("F02_small_targets", smallTargets())

        backgroundAndReturn(seconds: 6)
        capture("F03_draft_after_background")
        note("F03 draft after 6 s in the background: \(app.textViews.firstMatch.value as? String ?? "nil")")

        // "Später" reads as "keep this for later".
        tap("Später")
        capture("F04_after_spaeter")
        tap("Feedback senden", scroll: true)
        let again = app.textViews.firstMatch
        _ = again.waitForExistence(timeout: 6)
        capture("F05_reopened")
        note("F05 reopened after 'Später': \(again.value as? String ?? "nil")")
    }

    // MARK: - G: Skat Minute interrupted (member)

    func testG_SkatMinuteInterruption() {
        defer { flush("G_minute") }
        launch(onboarded(pro: true))
        capture("G00_home_member")
        attach("G00_tree", app.debugDescription)
        guard tap("Skat Minute"), tap("Heutige Runde starten") else { return }
        let before = questionTexts()
        capture("G01_minute_start")
        note("G01 Minute progress: \(sessionProgress()); question text: \(before)")
        answerAndAdvance()
        answerAndAdvance()
        capture("G02_minute_after_two")
        note("G02 Minute progress after two answers: \(sessionProgress())")
        killAndRelaunch()
        guard tap("Skat Minute"), tap("Heutige Runde starten") else {
            note("G03 could not reopen the Minute after the kill")
            return
        }
        capture("G03_minute_after_kill")
        let after = questionTexts()
        note("G03 Minute progress after kill: \(sessionProgress()); question text: \(after)")
        note("G03 same first question as before the kill: \(before == after)")
    }

    // MARK: - H: timed challenge interrupted (member)

    func testH_TimedChallengeInterruption() {
        defer { flush("H_timed") }
        launch(onboarded(pro: true))
        revealTrainingTile("Sekunden")
        capture("H00_training_row")
        guard tap("Sekunden") else { return }
        capture("H01_timed_start")
        let t0 = timerSeconds()
        note("H01 timer at start: \(describe(t0))")
        attach("H01_nav_buttons", navDump())
        attach("H01_small_targets", smallTargets())
        settle(3)
        let t1 = timerSeconds()
        note("H02 timer after about 3 s untouched: \(describe(t1))")

        backgroundAndReturn(seconds: 20)
        let t2 = timerSeconds()
        capture("H03_timer_after_20s_away")
        let wallClock = (t1 ?? 0) - 20
        note("H03 timer after 20 s in the background: \(describe(t2)) (a wall clock would read about \(wallClock), a paused one about \(describe(t1)))")

        // Leave mid-run with the system back control.
        let back = app.navigationBars.buttons.element(boundBy: 0)
        guard back.exists else {
            note("H04 no back control found")
            return
        }
        back.tap()
        settle(1.5)
        capture("H04_after_leaving_timed_run")
        note("H04 left the run with no confirmation; Home tile now: \(tileLabel(containing: "Sekunden"))")
    }

    // MARK: - I: returning after an update

    func testI_ReturnAfterUpdate() {
        defer { flush("I_update") }
        launch(onboarded(whatsNew: true))
        settle(2.5)
        capture("I01_home_after_update")
        note("I01 What's New sheet over Home: \(app.buttons["Fertig"].exists || has("Neu in dieser Version"))")
        attach("I01_buttons", buttonDump())
        attach("I01_small_targets", smallTargets())
    }

    // MARK: - J: paywall opened and interrupted (free player)

    func testJ_PaywallInterruption() {
        defer { flush("J_paywall") }
        launch(onboarded())
        guard tap("entdecken", scroll: true) else { return }
        settle(1.5)
        capture("J01_paywall")
        attach("J01_buttons", buttonDump())
        attach("J01_small_targets", smallTargets())
        note("J01 restore reachable: \(app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "wiederherstellen")).firstMatch.exists)")
        backgroundAndReturn(seconds: 6)
        capture("J02_paywall_after_background")
        note("J02 paywall still up after background: \(app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "wiederherstellen")).firstMatch.exists)")
        killAndRelaunch()
        capture("J03_home_after_kill")
    }

    // MARK: - Interruptions

    private func launch(_ arguments: [String]) {
        continueAfterFailure = true
        observations = []
        app = XCUIApplication(bundleIdentifier: Self.bundleID)
        app.launchArguments = arguments
        app.launch()
        _ = app.wait(for: .runningForeground, timeout: 30)
        settle(2)
    }

    /// Home button, a pause, then back: the process survives.
    private func backgroundAndReturn(seconds: TimeInterval) {
        XCUIDevice.shared.press(.home)
        Thread.sleep(forTimeInterval: seconds)
        app.activate()
        _ = app.wait(for: .runningForeground, timeout: 20)
        settle(1.5)
    }

    /// What iOS does to a backgrounded app under memory pressure, or what a
    /// swipe-up in the app switcher does.
    private func killAndRelaunch() {
        app.terminate()
        settle(1)
        app.launch()
        _ = app.wait(for: .runningForeground, timeout: 30)
        settle(2)
    }

    // MARK: - Reading the screen

    private func onboardingPage() -> String {
        let marks: [(String, String)] = [
            ("Zwischen den Runden", "page 1 of 5 (first value page)"),
            ("Üben ohne Druck", "page 2 of 5"),
            ("Sicher an den Tisch", "page 3 of 5"),
            ("Wo startest du?", "page 4 of 5 (skill question)"),
            ("freischalten", "page 5 of 5 (trial page)"),
        ]
        for (needle, name) in marks {
            let match = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", needle)).firstMatch
            if match.exists { return name }
        }
        if app.buttons["Für später überspringen"].exists { return "primer (How to Play)" }
        if app.buttons["Zeig es mir"].exists || app.buttons["Tour überspringen"].exists { return "feature tour" }
        if app.buttons["Einstellungen"].exists { return "Home" }
        return "unrecognised"
    }

    private func has(_ text: String) -> Bool {
        app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch.exists
    }

    private func deckProgress() -> String {
        let label = app.staticTexts.matching(NSPredicate(format: "label ENDSWITH %@", "geschafft")).firstMatch
        return label.exists ? label.label : "n/a"
    }

    private func sessionProgress() -> String {
        let label = app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "^[0-9]+ von [0-9]+$")).firstMatch
        return label.exists ? label.label : "n/a"
    }

    private func timerSeconds() -> Int? {
        let label = app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "^[0-9]+ s$")).firstMatch
        guard label.exists else { return nil }
        return Int(label.label.replacingOccurrences(of: " s", with: ""))
    }

    private func describe(_ seconds: Int?) -> String {
        guard let seconds else { return "n/a" }
        return String(seconds)
    }

    private func chipLabels() -> String {
        let chips = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@ OR label CONTAINS %@", "am Stück", "abgeschlossen"))
        let labels = chips.allElementsBoundByIndex.map { $0.label }
        return labels.isEmpty ? "none found" : labels.joined(separator: ", ")
    }

    private func tileLabel(containing text: String) -> String {
        let tile = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
        return tile.exists ? tile.label : "n/a"
    }

    /// The question text on screen, in reading order, without the chrome.
    private func questionTexts() -> String {
        let labels = app.staticTexts.allElementsBoundByIndex.prefix(14).map { $0.label }.filter { $0.count > 3 }
        return labels.joined(separator: " | ")
    }

    private func buttonDump() -> String {
        app.buttons.allElementsBoundByIndex.map { button in
            let frame = button.frame
            return "\(button.label) [x \(Int(frame.minX)), y \(Int(frame.minY)), \(Int(frame.width)) x \(Int(frame.height))]"
        }.joined(separator: "\n")
    }

    private func navDump() -> String {
        let bars = app.navigationBars.buttons.allElementsBoundByIndex.map { "nav button: \($0.label)" }
        return bars.isEmpty ? "no navigation bar buttons" : bars.joined(separator: "\n")
    }

    /// Anything tappable with a side under 44 pt.
    private func smallTargets() -> String {
        var lines: [String] = []
        let queries = [app.buttons, app.switches, app.links]
        for query in queries {
            for element in query.allElementsBoundByIndex where element.exists {
                let frame = element.frame
                guard frame.width > 0, frame.height > 0, min(frame.width, frame.height) < 44 else { continue }
                lines.append("\(element.label) [x \(Int(frame.minX)), y \(Int(frame.minY)), \(Int(frame.width)) x \(Int(frame.height))]")
            }
        }
        return lines.isEmpty ? "none under 44 pt" : lines.joined(separator: "\n")
    }

    // MARK: - Driving the screen

    /// Taps the first button or text whose label contains `text`, scrolling
    /// down a few times when asked.
    @discardableResult
    private func tap(_ text: String, scroll: Bool = false) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        for attempt in 0..<5 {
            for query in [app.buttons, app.staticTexts] {
                let match = query.matching(predicate).firstMatch
                if match.waitForExistence(timeout: attempt == 0 ? 6 : 1.0), match.isHittable {
                    match.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
                    settle(0.8)
                    return true
                }
            }
            if scroll { app.swipeUp() }
            settle(0.5)
        }
        note("could not tap: \(text)")
        return false
    }

    /// The training tiles scroll sideways on a phone; bring one into view.
    private func revealTrainingTile(_ text: String) {
        let tile = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
        guard tile.waitForExistence(timeout: 6) else { return }
        let height = max(app.frame.height, 1)
        let row = min(max(tile.frame.midY / height, 0.05), 0.95)
        for _ in 0..<3 where !tile.isHittable {
            let from = app.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: row))
            let to = app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: row))
            from.press(forDuration: 0.05, thenDragTo: to)
            settle(0.8)
        }
    }

    private func openRoomDrill(room: String, drill: String, screenshotRoom: String? = nil) -> Bool {
        guard tap(room, scroll: true) else { return false }
        if let screenshotRoom { capture(screenshotRoom) }
        return tap(drill, scroll: true)
    }

    /// Flips the top card, then throws it to the right ("Gewusst").
    private func swipeCardRight() {
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.45))
        start.tap()
        // The first flip of a fresh install plays a one-time nudge animation.
        settle(1.6)
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.98, dy: 0.45))
        start.press(forDuration: 0.1, thenDragTo: end)
        settle(0.9)
    }

    /// Picks the first answer row, then moves on unless told to stay.
    @discardableResult
    private func answerAndAdvance(advance: Bool = true) -> Bool {
        let skip = Set(["Weiter", "Fertig", "Schließen", "Zurück", "Nächste Frage"])
        let row = app.buttons.allElementsBoundByIndex.first { button in
            button.exists && button.isHittable && !button.label.isEmpty && !skip.contains(button.label)
                && button.frame.width > 200 && button.frame.height >= 40 && button.frame.minY > 150
        }
        guard let row else {
            note("no answer row found")
            return false
        }
        row.tap()
        settle(1.0)
        guard advance else { return true }
        let next = app.buttons["Weiter"]
        if next.waitForExistence(timeout: 4) {
            next.tap()
            settle(0.8)
        }
        return true
    }

    private func settle(_ seconds: TimeInterval = 1.4) { Thread.sleep(forTimeInterval: seconds) }

    // MARK: - Evidence

    private func note(_ text: String) { observations.append(text) }

    private func capture(_ name: String) {
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    private func attach(_ name: String, _ text: String) {
        let item = XCTAttachment(string: text.isEmpty ? "none" : text)
        item.name = name
        item.lifetime = .keepAlways
        add(item)
    }

    private func flush(_ name: String) {
        attach("observations_\(name)", observations.joined(separator: "\n"))
    }
}
