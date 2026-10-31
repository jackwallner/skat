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
/// shows what survived and what did not. Tests are named A..G so the first-run
/// flow runs before any test that passes `-progress.hasOnboarded`.
@MainActor
final class InterruptedAuditUITests: XCTestCase {
    private var app: XCUIApplication!
    private var observations: [String] = []

    private static let bundleID = "com.jackwallner.skat"

    /// Past onboarding, free tier. The What's New sheet is held back so it never
    /// covers Home (flow F lets it show on purpose).
    private static let onboardedArgs = [
        "-progress.hasOnboarded", "YES",
        "-skat.hasReadPrimer", "YES",
        "-skat.skillLevel", "some",
        "-whatsnew.lastSeenVersion", "1.3.1",
        "-skat.suppressWhatsNew",
    ]

    private static let proArgs = ["-subscription.localProOverride", "YES"]

    // MARK: - A: onboarding interrupted

    func testA_OnboardingInterruption() {
        launch([])
        capture("A01_first_launch")
        note("A01 first launch lands on: \(onboardingPage())")
        attach("A01_small_targets", smallTargets())

        // Three value pages, then the skill question.
        for _ in 0..<3 { _ = tap("Weiter") }
        note("A02 after three Weiter taps: \(onboardingPage())")
        _ = tap("Ganz neu")
        capture("A02_skill_selected")
        _ = tap("Weiter")
        capture("A03_trial_page")
        note("A03 reached: \(onboardingPage())")
        attach("A03_buttons", buttonDump())
        attach("A03_small_targets", smallTargets())

        // Backgrounded: the process lives.
        backgroundAndReturn(seconds: 5)
        capture("A04_after_background")
        note("A04 after 5 s in the background: \(onboardingPage())")

        // Killed: iOS does this to a backgrounded app.
        killAndRelaunch()
        capture("A05_after_kill_on_trial_page")
        note("A05 after kill while on the trial page: \(onboardingPage())")

        for _ in 0..<3 { _ = tap("Weiter") }
        capture("A06_skill_page_after_relaunch")
        let ganzNeu = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Ganz neu")).firstMatch
        note("A06 skill page after relaunch: \(onboardingPage()); 'Ganz neu' still selected: \(ganzNeu.exists && ganzNeu.isSelected)")

        // Trial decision made ("Loslegen"), then the primer for a new player.
        _ = tap("Weiter")
        _ = tap("Loslegen")
        capture("A07_primer_page_one")
        note("A07 after the free exit: primer visible: \(app.buttons["Für später überspringen"].exists)")
        _ = tap("Weiter")
        capture("A08_primer_page_two")
        killAndRelaunch()
        capture("A09_after_kill_inside_primer")
        note("A09 after kill inside the primer: \(onboardingPage())")

        // Experienced player: skill question, free exit, straight to the tour.
        for _ in 0..<3 { _ = tap("Weiter") }
        _ = tap("Schon gespielt")
        _ = tap("Weiter")
        _ = tap("Loslegen")
        capture("A10_tour_page_one")
        note("A10 tour visible: \(app.buttons["Zeig es mir"].exists)")
        _ = tap("Zeig es mir")
        capture("A11_tour_page_two")
        killAndRelaunch()
        capture("A12_after_kill_inside_tour")
        note("A12 after kill inside the tour: \(onboardingPage())")
        flush("A_onboarding")
    }

    // MARK: - B: flashcard deck interrupted

    func testB_FlashcardDeckInterruption() {
        launch(Self.onboardedArgs)
        capture("B00_home_before")
        attach("B00_home_small_targets", smallTargets())
        note("B00 home statistics before: \(chipLabels())")

        guard openRoomDrill(room: "Karten & Reizen", drill: "Die Karten kennenlernen") else {
            flush("B_deck")
            return
        }
        capture("B01_deck_start")
        note("B01 deck progress: \(deckProgress())")
        attach("B01_small_targets", smallTargets())
        for _ in 0..<3 { swipeCardRight() }
        capture("B02_deck_after_three_cards")
        note("B02 deck progress after three cards: \(deckProgress())")

        backgroundAndReturn(seconds: 6)
        capture("B03_deck_after_background")
        note("B03 deck progress after 6 s in the background: \(deckProgress())")

        killAndRelaunch()
        capture("B04_home_after_kill")
        note("B04 home after kill: \(chipLabels())")
        guard openRoomDrill(room: "Karten & Reizen", drill: "Die Karten kennenlernen", screenshotRoom: "B05_room_after_kill") else {
            flush("B_deck")
            return
        }
        capture("B06_deck_after_kill")
        note("B06 deck progress after kill and reopen: \(deckProgress())")
        flush("B_deck")
    }

    // MARK: - C: Loslegen (daily quick session) interrupted

    func testC_QuickSessionInterruption() {
        launch(Self.onboardedArgs)
        guard tap("Eine kurze Runde") else {
            flush("C_quick")
            return
        }
        capture("C01_session_start")
        let firstBefore = questionTexts()
        note("C01 progress: \(sessionProgress()); question text: \(firstBefore)")
        attach("C01_small_targets", smallTargets())
        for _ in 0..<3 { answerAndAdvance() }
        capture("C02_session_after_three")
        note("C02 progress after three answers: \(sessionProgress())")

        backgroundAndReturn(seconds: 6)
        capture("C03_after_background")
        note("C03 progress after 6 s in the background: \(sessionProgress())")

        killAndRelaunch()
        capture("C04_home_after_kill")
        note("C04 Loslegen card offered again: \(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Eine kurze Runde")).firstMatch.exists); \(chipLabels())")
        guard tap("Eine kurze Runde") else {
            flush("C_quick")
            return
        }
        capture("C05_session_after_kill")
        let firstAfter = questionTexts()
        note("C05 progress after kill and reopen: \(sessionProgress()); question text: \(firstAfter)")
        note("C05 same first question as before the kill: \(firstBefore == firstAfter)")
        flush("C_quick")
    }

    // MARK: - D: half-written feedback

    func testD_FeedbackDraft() {
        launch(Self.onboardedArgs)
        guard tap("Einstellungen") else {
            flush("D_feedback")
            return
        }
        capture("D01_settings")
        attach("D01_small_targets", smallTargets())
        guard tap("Feedback senden", scroll: true) else {
            flush("D_feedback")
            return
        }
        let editor = app.textViews.firstMatch
        guard editor.waitForExistence(timeout: 6) else {
            note("D02 feedback editor not found")
            flush("D_feedback")
            return
        }
        editor.tap()
        editor.typeText("Der Entwurf ist mir wichtig. Weiter schreibe ich nach dem Anruf.")
        capture("D02_draft_typed")
        note("D02 draft typed: \(editor.value as? String ?? "nil")")
        attach("D02_small_targets", smallTargets())

        backgroundAndReturn(seconds: 6)
        capture("D03_draft_after_background")
        note("D03 draft after 6 s in the background: \(app.textViews.firstMatch.value as? String ?? "nil")")

        // "Später" reads as "keep this for later".
        _ = tap("Später")
        capture("D04_after_spaeter")
        _ = tap("Feedback senden", scroll: true)
        let again = app.textViews.firstMatch
        _ = again.waitForExistence(timeout: 6)
        capture("D05_reopened")
        note("D05 reopened after 'Später': \(again.value as? String ?? "nil")")
        flush("D_feedback")
    }

    // MARK: - E: timed challenge and Skat Minute (member)

    func testE_TimedChallengeAndMinute() {
        launch(Self.onboardedArgs + Self.proArgs)
        capture("E00_home_member")
        guard tap("Sekunden", scroll: true) else {
            flush("E_timed")
            return
        }
        capture("E01_timed_start")
        let t0 = timerSeconds()
        note("E01 timer at start: \(describe(t0))")
        attach("E01_nav_buttons", navDump())
        attach("E01_small_targets", smallTargets())
        settle(3)
        let t1 = timerSeconds()
        note("E02 timer after about 3 s untouched: \(describe(t1))")

        backgroundAndReturn(seconds: 20)
        let t2 = timerSeconds()
        capture("E03_timer_after_20s_away")
        let wallClock = (t1 ?? 0) - 20
        note("E03 timer after 20 s in the background: \(describe(t2)) (a wall clock would read about \(wallClock), a paused one about \(describe(t1)))")

        // Leave mid-run with the system back control.
        let back = app.navigationBars.buttons.element(boundBy: 0)
        if back.exists {
            back.tap()
            settle(1.5)
            capture("E04_after_leaving_timed_run")
            note("E04 left the run with no confirmation; Home tile now: \(tileLabel(containing: "Sekunden"))")
        } else {
            note("E04 no back control found")
        }

        // Skat Minute: deterministic per day, saved only when finished.
        guard tap("Minute", scroll: true), tap("Heutige Runde starten") else {
            flush("E_timed")
            return
        }
        let minuteBefore = questionTexts()
        capture("E05_minute_start")
        note("E05 Minute progress: \(sessionProgress()); question text: \(minuteBefore)")
        answerAndAdvance()
        answerAndAdvance()
        capture("E06_minute_after_two")
        note("E06 Minute progress after two answers: \(sessionProgress())")
        killAndRelaunch()
        guard tap("Minute", scroll: true), tap("Heutige Runde starten") else {
            note("E07 could not reopen the Minute after the kill")
            flush("E_timed")
            return
        }
        capture("E07_minute_after_kill")
        let minuteAfter = questionTexts()
        note("E07 Minute progress after kill: \(sessionProgress()); question text: \(minuteAfter)")
        note("E07 same first question as before the kill: \(minuteBefore == minuteAfter)")
        flush("E_timed")
    }

    // MARK: - F: returning after an update

    func testF_ReturnAfterUpdate() {
        launch([
            "-progress.hasOnboarded", "YES",
            "-skat.hasReadPrimer", "YES",
            "-skat.skillLevel", "some",
            "-whatsnew.lastSeenVersion", "1.0.0",
        ])
        settle(2.5)
        capture("F01_home_after_update")
        note("F01 What's New sheet over Home: \(app.buttons["Fertig"].exists || app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Neu")).firstMatch.exists)")
        attach("F01_buttons", buttonDump())
        attach("F01_small_targets", smallTargets())
        flush("F_update")
    }

    // MARK: - G: paywall opened and interrupted (free player)

    func testG_PaywallInterruption() {
        launch(Self.onboardedArgs)
        guard tap("entdecken", scroll: true) else {
            flush("G_paywall")
            return
        }
        settle(1.5)
        capture("G01_paywall")
        attach("G01_buttons", buttonDump())
        attach("G01_small_targets", smallTargets())
        note("G01 restore reachable: \(app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "wiederherstellen")).firstMatch.exists)")
        backgroundAndReturn(seconds: 6)
        capture("G02_paywall_after_background")
        note("G02 paywall still up after background: \(app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "wiederherstellen")).firstMatch.exists)")
        killAndRelaunch()
        capture("G03_home_after_kill")
        flush("G_paywall")
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
        for attempt in 0..<(scroll ? 5 : 1) {
            for query in [app.buttons, app.staticTexts] {
                let match = query.matching(predicate).firstMatch
                if match.waitForExistence(timeout: attempt == 0 ? 6 : 1.5), match.isHittable {
                    match.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
                    settle(1)
                    return true
                }
            }
            if scroll { app.swipeUp(); settle(0.6) }
        }
        note("could not tap: \(text)")
        return false
    }

    private func openRoomDrill(room: String, drill: String, screenshotRoom: String? = nil) -> Bool {
        guard tap(room, scroll: true) else { return false }
        if let screenshotRoom { capture(screenshotRoom) }
        return tap(drill, scroll: true)
    }

    private func swipeCardRight() {
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.45))
        start.tap()
        settle(0.9)
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.98, dy: 0.45))
        start.press(forDuration: 0.1, thenDragTo: end)
        settle(1.0)
    }

    /// Picks the first answer row, then moves on.
    private func answerAndAdvance() {
        let skip = Set(["Weiter", "Fertig", "Schließen", "Zurück", "Nächste Frage"])
        let row = app.buttons.allElementsBoundByIndex.first { button in
            button.exists && button.isHittable && !button.label.isEmpty && !skip.contains(button.label)
                && button.frame.width > 200 && button.frame.height >= 40 && button.frame.minY > 150
        }
        guard let row else {
            note("no answer row found")
            return
        }
        row.tap()
        settle(1.2)
        let next = app.buttons["Weiter"]
        if next.waitForExistence(timeout: 4) {
            next.tap()
            settle(1.0)
        }
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
