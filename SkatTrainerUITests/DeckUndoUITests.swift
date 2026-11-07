import XCTest

/// The flashcard deck's undo button takes the answer back (state machine
/// audit 2026-11-06, B1). Kept from the audit's repro, which failed on the
/// claim with every precondition passing before the fix.
///
/// Route: Home > Karten & Reizen > Die Karten kennenlernen > flip the card >
/// swipe left ("Nochmal") > toolbar "Letzte Antwort zurücknehmen" > back to Home
/// > "Tage am Stück" (Dein Fortschritt). Dein Fortschritt shows the
/// "Antworten" count from `PracticeRecordStore.totalAttempts`, or "Noch keine
/// Übung" when it is zero.
///
/// P8 route: Home > Stichspiel > Stich-Entscheidungen > pick "Herz bedienen" >
/// Weiter > undo > pick "Herz bedienen" again > Weiter > Dein Fortschritt.
///
/// Never hard-fails on navigation: records what it could not do in `problems`
/// and asserts preconditions with messages, so a failure on the last assertion
/// of each test is the claim itself.
@MainActor
final class DeckUndoUITests: XCTestCase {
    private var app: XCUIApplication!
    private var problems: [String] = []

    override func setUp() async throws {
        try await super.setUp()
        continueAfterFailure = true
        app = XCUIApplication(bundleIdentifier: "com.jackwallner.skat")
        app.launchArguments = [
            "-progress.hasOnboarded", "YES",
            "-skat.hasReadPrimer", "YES",
            "-skat.skillLevel", "some",
            "-skat.suppressWhatsNew", "YES",
            "-whatsnew.lastSeenVersion", "1.3.1",
        ]
        app.launch()
        _ = app.wait(for: .runningForeground, timeout: 30)
        settle()
    }

    // MARK: - Tests

    /// Control: a "Nochmal" swipe with no undo records an answer, so the
    /// progress screen leaves its empty state.
    func testControlSwipeRecordsAnAnswer() {
        resetProgress()
        XCTAssertTrue(progressIsEmpty(), "precondition: progress starts empty after the reset")
        guard openFirstDeck() else { return XCTFail("could not open the deck: \(problems)") }
        XCTAssertTrue(flipAndSwipeLeft(), "precondition: the card was flipped and swiped")
        XCTAssertTrue(app.buttons["Letzte Antwort zurücknehmen"].waitForExistence(timeout: 3),
                      "precondition: the undo button appeared after the swipe")
        goHome()
        XCTAssertFalse(progressIsEmpty(), "control: the swiped answer is counted on Dein Fortschritt")
    }

    /// Claim: undoing the swipe takes the answer back, so progress is empty again.
    func testUndoTakesTheAnswerBack() {
        resetProgress()
        XCTAssertTrue(progressIsEmpty(), "precondition: progress starts empty after the reset")
        guard openFirstDeck() else { return XCTFail("could not open the deck: \(problems)") }
        XCTAssertTrue(flipAndSwipeLeft(), "precondition: the card was flipped and swiped")
        let undo = app.buttons["Letzte Antwort zurücknehmen"]
        XCTAssertTrue(undo.waitForExistence(timeout: 3), "precondition: the undo button appeared")
        undo.tap()
        settle(1.0)
        XCTAssertFalse(undo.exists, "precondition: undo consumed the last swipe")
        attach("deck_after_undo", app.debugDescription)
        goHome()
        XCTAssertTrue(progressIsEmpty(), "after taking the answer back, Dein Fortschritt has no answers")
    }

    // MARK: - Choice cards (P8)

    /// Control: two choice cards picked and advanced count two answers, so
    /// the reader below can tell one answer from two.
    func testControlTwoChoiceCardsCountTwoAnswers() {
        resetProgress()
        guard openChoiceDeck() else { return XCTFail("could not open the choice deck: \(problems)") }
        XCTAssertTrue(pickAndAdvance("Herz bedienen"), "precondition: the first card was picked and advanced")
        XCTAssertTrue(pickAndAdvance("Frei wählen"), "precondition: the second card was picked and advanced")
        goHome()
        XCTAssertEqual(answerCount(), 2, "control: two picks count two answers")
    }

    /// Claim: a choice card picked, advanced, taken back and picked again is
    /// one answer, not two.
    func testChoiceCardPickedAgainAfterUndoCountsOnce() {
        resetProgress()
        guard openChoiceDeck() else { return XCTFail("could not open the choice deck: \(problems)") }
        XCTAssertTrue(pickAndAdvance("Herz bedienen"), "precondition: the card was picked and advanced")
        let undo = app.buttons["Letzte Antwort zurücknehmen"]
        XCTAssertTrue(undo.waitForExistence(timeout: 3), "precondition: the undo button appeared")
        undo.tap()
        settle(1.0)
        XCTAssertTrue(app.buttons["Herz bedienen"].waitForExistence(timeout: 3),
                      "precondition: the choice card is back in front, unanswered")
        XCTAssertTrue(pickAndAdvance("Herz bedienen"), "precondition: the card was picked again and advanced")
        attach("choice_deck_after_second_pick", app.debugDescription)
        goHome()
        XCTAssertEqual(answerCount(), 1, "after undo and a second pick, the card counts one answer")
    }

    // MARK: - Steps

    private func resetProgress() {
        let gear = app.buttons["Einstellungen"].firstMatch
        guard gear.waitForExistence(timeout: 5) else { problems.append("no settings gear"); return }
        gear.tap()
        settle(1.0)
        let reset = app.buttons["Fortschritt zurücksetzen"].firstMatch
        if !reset.waitForExistence(timeout: 3) { app.swipeUp(); settle(0.5) }
        guard reset.waitForExistence(timeout: 3) else { problems.append("no reset row"); return }
        reset.tap()
        settle(0.8)
        let confirm = app.alerts.buttons["Zurücksetzen"].firstMatch
        guard confirm.waitForExistence(timeout: 3) else { problems.append("no reset confirm"); return }
        confirm.tap()
        settle(0.8)
        let done = app.buttons["Fertig"].firstMatch
        if done.waitForExistence(timeout: 3) { done.tap() }
        settle(1.0)
    }

    private func openFirstDeck() -> Bool {
        guard open("Karten & Reizen"), open("Die Karten kennenlernen") else { return false }
        return true
    }

    private func flipAndSwipeLeft() -> Bool {
        let middle = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        middle.tap()
        settle(1.0)
        let from = app.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.5))
        let to = app.coordinate(withNormalizedOffset: CGVector(dx: 0.02, dy: 0.5))
        from.press(forDuration: 0.15, thenDragTo: to)
        settle(1.2)
        return true
    }

    private func openChoiceDeck() -> Bool {
        goHome()
        for _ in 0..<5 {
            let named = NSPredicate(format: "label CONTAINS %@", "Stichspiel")
            let room = app.buttons.matching(named).firstMatch
            let title = app.staticTexts.matching(named).firstMatch
            if (room.exists && room.isHittable) || (title.exists && title.isHittable) { break }
            app.swipeUp()
            settle(0.6)
        }
        guard open("Stichspiel"), open("Stich-Entscheidungen") else { return false }
        return true
    }

    private func pickAndAdvance(_ option: String) -> Bool {
        let pick = app.buttons[option].firstMatch
        guard pick.waitForExistence(timeout: 5) else { problems.append("no option \(option)"); return false }
        pick.tap()
        settle(1.2)
        let next = app.buttons["Weiter"].firstMatch
        guard next.waitForExistence(timeout: 5) else { problems.append("no Weiter after \(option)"); return false }
        next.tap()
        settle(1.2)
        return true
    }

    /// The number above "Antworten" on Dein Fortschritt, or nil when the
    /// screen shows no answers. Returns to Home afterwards.
    private func answerCount() -> Int? {
        goHome()
        guard open("Tage am Stück") else { problems.append("no stats link"); return nil }
        defer { goHome() }
        let caption = app.staticTexts["Antworten"].firstMatch
        guard caption.waitForExistence(timeout: 3) else { return nil }
        attach("stats_answers", app.debugDescription)
        let below = caption.frame
        let value = app.staticTexts.allElementsBoundByIndex.first { text in
            let frame = text.frame
            return abs(frame.midX - below.midX) < 30 && frame.maxY <= below.minY + 2 && below.minY - frame.maxY < 40
        }
        return value.flatMap { Int($0.label) }
    }

    private func goHome() {
        for _ in 0..<4 {
            if atHome { return }
            let back = app.navigationBars.buttons.element(boundBy: 0)
            guard back.exists else { return }
            back.tap()
            settle(0.6)
        }
    }

    /// Opens Dein Fortschritt from Home and reports whether it shows the empty
    /// state. Returns to Home afterwards.
    private func progressIsEmpty() -> Bool {
        goHome()
        guard open("Tage am Stück") else { problems.append("no stats link"); return false }
        let empty = app.staticTexts["Noch keine Übung"].waitForExistence(timeout: 3)
        let answers = app.staticTexts["Antworten"].exists
        attach("stats_empty_\(empty)_answers_\(answers)", app.debugDescription)
        goHome()
        return empty && !answers
    }

    @discardableResult
    private func open(_ label: String) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS %@", label)
        for query in [app.buttons, app.staticTexts] {
            let match = query.matching(predicate).firstMatch
            guard match.waitForExistence(timeout: 6) else { continue }
            match.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            settle()
            return true
        }
        problems.append("could not open: \(label)")
        return false
    }

    private var atHome: Bool {
        app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "DIE R")).firstMatch.exists
    }

    private func settle(_ seconds: TimeInterval = 1.6) {
        Thread.sleep(forTimeInterval: seconds)
    }

    private func attach(_ name: String, _ text: String) {
        let item = XCTAttachment(string: text)
        item.name = name
        item.lifetime = .keepAlways
        add(item)
    }
}
