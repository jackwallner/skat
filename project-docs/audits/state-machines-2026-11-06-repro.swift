// State machine audit repro suite, 2026-11-06. Not compiled from here.
// Two files in one: copy part 1 into SkatTrainerTests/ and part 2 into SkatTrainerUITests/ (xcodegen generate), then run
//   gh-sim test --scheme SkatTrainer --only SkatTrainerTests/StateMachineAuditRepro
//   gh-sim test --scheme SkatTrainerUITests --only SkatTrainerUITests/StateMachineAuditRepro
// The notification tests (testControlDailyReminder..., testControlGameNightHour..., testLaunchReschedules...) are inconclusive on the GitHub runner:
// their controls fail because the runner shows no pending requests. See the audit doc.

// ===== Part 1: SkatTrainerTests/StateMachineAuditRepro.swift =====
import UserNotifications
import XCTest
@testable import SkatTrainer

/// State machine audit repro suite (2026-11-06). Every test asserts its own
/// preconditions first, so a failure on a "claim" assertion means the claim and
/// not a broken setup. Controls are the tests that are expected to pass.
///
/// Notification tests use the real `UNUserNotificationCenter` of the hosted
/// test app: `AppSettings` has no injection point for it. Scheduling does not
/// need authorization, so pending requests can be read back.
@MainActor
final class StateMachineAuditRepro: XCTestCase {
    private let dailyID = "skat.dailyReminder"
    private let gameNightID = "skat.gameNightReminder"
    private var savedZone: TimeZone = NSTimeZone.default
    private var suiteNames: [String] = []

    /// Plain Sendable copy of a pending request, so nothing non-Sendable
    /// crosses the center's callback.
    private struct Pending: Sendable {
        let id: String
        let hour: Int?
        let weekday: Int?
    }

    override func setUp() async throws {
        try await super.setUp()
        savedZone = NSTimeZone.default
        clearReminders()
    }

    override func tearDown() async throws {
        NSTimeZone.default = savedZone
        clearReminders()
        suiteNames.forEach { UserDefaults().removePersistentDomain(forName: $0) }
        try await super.tearDown()
    }

    // MARK: - Helpers

    private func freshDefaults() -> UserDefaults {
        let name = "StateMachineAuditRepro.\(UUID().uuidString)"
        suiteNames.append(name)
        return UserDefaults(suiteName: name)!
    }

    private func clearReminders() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [dailyID, gameNightID])
    }

    private func pendingRequests() async -> [Pending] {
        await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                let copies = requests.map { request -> Pending in
                    let parts = (request.trigger as? UNCalendarNotificationTrigger)?.dateComponents
                    return Pending(id: request.identifier, hour: parts?.hour, weekday: parts?.weekday)
                }
                continuation.resume(returning: copies)
            }
        }
    }

    /// Polls because `add` completes asynchronously.
    private func waitForPending(_ id: String, timeout: TimeInterval = 3) async -> Pending? {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if let hit = await pendingRequests().first(where: { $0.id == id }) { return hit }
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        return nil
    }

    private func utc(_ iso: String) -> Date {
        ISO8601DateFormatter().date(from: iso)!
    }

    // MARK: - S1: reminder toggles never reconcile with the pending requests

    /// Control: with the toggle on, the app's own scheduling path does put the
    /// request in the center, so the center is usable from this host.
    func testControlDailyReminderSchedulesWhenTimeIsEdited() async {
        let defaults = freshDefaults()
        defaults.set(true, forKey: "settings.reminderEnabled")
        let settings = AppSettings(defaults: defaults)
        XCTAssertTrue(settings.reminderEnabled, "precondition: persisted toggle is on")
        let none = await pendingRequests().first { $0.id == dailyID }
        XCTAssertNil(none, "precondition: nothing pending before the edit")

        settings.reminderTime = settings.reminderTime
        let scheduled = await waitForPending(dailyID)
        XCTAssertNotNil(scheduled, "control: editing the time while enabled schedules the reminder")
    }

    /// Claim: toggle persisted as on, but the center holds no request (state
    /// after a restore to a new device, or after iOS dropped the requests).
    /// Constructing the settings (what every launch does) never repairs it.
    func testLaunchReschedulesEnabledRemindersThatAreNotPending() async {
        let defaults = freshDefaults()
        defaults.set(true, forKey: "settings.reminderEnabled")
        defaults.set(true, forKey: "settings.gameNightReminderEnabled")
        clearReminders()
        let before = await pendingRequests().filter { [dailyID, gameNightID].contains($0.id) }
        XCTAssertTrue(before.isEmpty, "precondition: no reminder request is pending")

        let settings = AppSettings(defaults: defaults)
        XCTAssertTrue(settings.reminderEnabled && settings.gameNightReminderEnabled,
                      "precondition: both toggles read back as on")

        let daily = await waitForPending(dailyID, timeout: 3)
        let game = await waitForPending(gameNightID, timeout: 1)
        XCTAssertNotNil(daily, "claim: an enabled daily reminder is pending after launch")
        XCTAssertNotNil(game, "claim: an enabled game night reminder is pending after launch")
    }

    // MARK: - S2: reminder wall-clock time shifts when the zone changes in a live process

    private func triggerHour(of id: String) async -> (hour: Int?, weekday: Int?)? {
        guard let request = await waitForPending(id) else { return nil }
        return (request.hour, request.weekday)
    }

    func testControlGameNightHourStaysSeventeenInTheSameZone() async {
        NSTimeZone.default = TimeZone(identifier: "Europe/Berlin")!
        XCTAssertEqual(Calendar.current.timeZone.identifier, "Europe/Berlin", "precondition: zone applied")
        let defaults = freshDefaults()
        defaults.set(17, forKey: "settings.gameNightHour")
        defaults.set(0, forKey: "settings.gameNightMinute")
        defaults.set(true, forKey: "settings.gameNightReminderEnabled")
        let settings = AppSettings(defaults: defaults)
        XCTAssertEqual(Calendar.current.component(.hour, from: settings.gameNightReminderTime), 17,
                       "precondition: picker value reads 17:00 in the zone it was built in")

        settings.gameNightDay = .friday
        let trigger = await triggerHour(of: gameNightID)
        XCTAssertEqual(trigger?.hour, 17, "control: same zone keeps 17:00")
        XCTAssertEqual(trigger?.weekday, 6)
    }

    func testGameNightHourSurvivesATimeZoneChangeWhileTheAppIsResident() async {
        NSTimeZone.default = TimeZone(identifier: "Europe/Berlin")!
        XCTAssertEqual(Calendar.current.timeZone.identifier, "Europe/Berlin", "precondition: zone applied")
        let defaults = freshDefaults()
        defaults.set(17, forKey: "settings.gameNightHour")
        defaults.set(0, forKey: "settings.gameNightMinute")
        defaults.set(true, forKey: "settings.gameNightReminderEnabled")
        let settings = AppSettings(defaults: defaults)
        XCTAssertEqual(Calendar.current.component(.hour, from: settings.gameNightReminderTime), 17,
                       "precondition: settings were built reading 17:00 in Berlin")

        // The phone lands in New York while the app is still in memory.
        NSTimeZone.default = TimeZone(identifier: "America/New_York")!
        XCTAssertEqual(Calendar.current.timeZone.identifier, "America/New_York", "precondition: zone changed")
        XCTAssertEqual(defaults.integer(forKey: "settings.gameNightHour"), 17, "precondition: stored hour is still 17")

        // What the picker row shows.
        let shownHour = Calendar.current.component(.hour, from: settings.gameNightReminderTime)
        XCTAssertEqual(shownHour, 17, "claim: the picker still shows the stored 17:00")

        // Changing only the weekday reschedules with the recomputed time.
        clearReminders()
        settings.gameNightDay = .saturday
        let trigger = await triggerHour(of: gameNightID)
        XCTAssertNotNil(trigger, "precondition: a request was scheduled")
        XCTAssertEqual(trigger?.hour, 17, "claim: changing the weekday keeps the stored 17:00")
    }

    // MARK: - S3: streak counts two wall-clock dates as consecutive days across a zone change

    func testControlSameZoneSameDayKeepsStreakAtOne() {
        NSTimeZone.default = TimeZone(identifier: "Asia/Tokyo")!
        let store = ProgressStore(defaults: freshDefaults())
        store.recordSession(drillID: "a", now: utc("2026-11-06T01:00:00Z"))
        store.recordSession(drillID: "b", now: utc("2026-11-06T05:00:00Z"))
        XCTAssertEqual(store.streakCount, 1, "control: two sessions on one date in one zone")
    }

    func testStreakDoesNotGrowForTwoSessionsOnTheSameCalendarDateAcrossZones() {
        let tokyo = TimeZone(identifier: "Asia/Tokyo")!
        let la = TimeZone(identifier: "America/Los_Angeles")!
        let first = utc("2026-11-06T01:00:00Z")   // 10:00 on 6 Nov in Tokyo
        let second = utc("2026-11-06T17:00:00Z")  // 09:00 on 6 Nov in Los Angeles
        var tokyoCal = Calendar(identifier: .gregorian); tokyoCal.timeZone = tokyo
        var laCal = Calendar(identifier: .gregorian); laCal.timeZone = la
        XCTAssertEqual(tokyoCal.component(.day, from: first), 6, "precondition: first session is on the 6th")
        XCTAssertEqual(laCal.component(.day, from: second), 6, "precondition: second session is on the 6th")

        NSTimeZone.default = tokyo
        let store = ProgressStore(defaults: freshDefaults())
        store.recordSession(drillID: "a", now: first)
        XCTAssertEqual(store.streakCount, 1, "precondition: first session starts a streak of 1")

        NSTimeZone.default = la
        XCTAssertEqual(Calendar.current.timeZone.identifier, "America/Los_Angeles", "precondition: zone changed")
        store.recordSession(drillID: "b", now: second)
        XCTAssertEqual(store.streakCount, 1, "claim: still one calendar date, so still a streak of 1")
    }

    // MARK: - S4: weekly gain chip counts items again when membership returns

    func testWeeklyGainIsNotInventedByAMembershipComingBack() throws {
        let now = Date()
        let day: TimeInterval = 86_400
        guard let room = DrillLibrary.rooms.first(where: { $0.id == "card-room" }),
              let plusDrill = room.drills.first(where: \.isPlus),
              case .quiz(let questions) = plusDrill.kind else {
            return XCTFail("precondition: card-room has a Skat+ quiz drill")
        }
        let ids = questions.prefix(5).map(\.id)
        XCTAssertEqual(ids.count, 5, "precondition: five Skat+ questions to answer")

        let records = PracticeRecordStore(defaults: freshDefaults())
        // Four right answers in a row while a member, the last one 8 days ago.
        for offset in [-20.0, -19.0, -16.0, -8.0] {
            for id in ids {
                records.record(itemID: id, roomID: room.id, correct: true, now: now.addingTimeInterval(offset * day))
            }
        }
        let asMember = records.masteryByRoom(isMember: true, now: now).reduce(0) { $0 + $1.known }
        let asFree = records.masteryByRoom(isMember: false, now: now.addingTimeInterval(-3 * day)).reduce(0) { $0 + $1.known }
        XCTAssertEqual(asMember, 5, "precondition: the five Skat+ items count as known for a member")
        XCTAssertEqual(asFree, 0, "precondition: a free player's count excludes them")

        let ledger = MasteryLedger(defaults: freshDefaults())
        // Lapsed, opened Home 3 days ago (free count recorded), re-subscribed today.
        ledger.record(records.masteryByRoom(isMember: false, now: now.addingTimeInterval(-3 * day)),
                      now: now.addingTimeInterval(-3 * day))
        ledger.record(records.masteryByRoom(isMember: true, now: now), now: now)
        XCTAssertNil(ledger.weeklyGain(now: now),
                     "claim: no question was answered in the last 8 days, so no gain is reported")
    }

    func testControlWeeklyGainStaysNilWhenMembershipDoesNotChange() throws {
        let now = Date()
        let day: TimeInterval = 86_400
        let room = try XCTUnwrap(DrillLibrary.rooms.first(where: { $0.id == "card-room" }))
        let records = PracticeRecordStore(defaults: freshDefaults())
        let ledger = MasteryLedger(defaults: freshDefaults())
        ledger.record(records.masteryByRoom(isMember: true, now: now.addingTimeInterval(-3 * day)),
                      now: now.addingTimeInterval(-3 * day))
        ledger.record(records.masteryByRoom(isMember: true, now: now), now: now)
        XCTAssertEqual(room.id, "card-room", "precondition: room exists")
        XCTAssertNil(ledger.weeklyGain(now: now), "control: unchanged membership, no practice, no gain")
    }
}

// ===== Part 2: SkatTrainerUITests/StateMachineAuditRepro.swift =====
import XCTest

/// State machine audit repro (2026-11-06): the flashcard deck's undo button.
///
/// Route: Home > Karten & Reizen > Die Karten kennenlernen > flip the card >
/// swipe left ("Nochmal") > toolbar "Letzte Antwort zurücknehmen" > back to Home
/// > "Tage am Stück" (Dein Fortschritt). Dein Fortschritt shows the
/// "Antworten" count from `PracticeRecordStore.totalAttempts`, or "Noch keine
/// Übung" when it is zero.
///
/// Never hard-fails on navigation: records what it could not do in `problems`
/// and asserts preconditions with messages, so a failure on the last assertion
/// of each test is the claim itself.
@MainActor
final class StateMachineAuditRepro: XCTestCase {
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
        XCTAssertTrue(progressIsEmpty(), "claim: after taking the answer back, Dein Fortschritt has no answers")
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
