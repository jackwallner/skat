import XCTest

/// Persona audit: a skeptical free player working out what is paid, then
/// testing restore, cancel and exit paths. Never calls XCTFail; it attaches
/// screenshots, control frames and a list of what it could not reach.
/// RevenueCat is never configured on a simulator, so prices stay on the
/// loading placeholder and no purchase can complete here.
@MainActor
final class SubscriptionAuditTests: XCTestCase {
    private var app: XCUIApplication!
    private var notes: [String] = []

    private func launch(onboarded: Bool, member: Bool = false, extra: [String] = []) {
        continueAfterFailure = true
        app = XCUIApplication()
        var args = [
            "-progress.hasOnboarded", onboarded ? "YES" : "NO",
            "-skat.hasReadPrimer", "YES",
            "-skat.skillLevel", onboarded ? "some" : "",
            "-whatsnew.lastSeenVersion", ProcessInfo.processInfo.environment["SCREENSHOT_APP_VERSION"] ?? "1.3.0",
        ]
        args += ["-subscription.localProOverride", member ? "YES" : "NO"]
        app.launchArguments = args + extra
        app.launch()
        _ = app.wait(for: .runningForeground, timeout: 30)
        settle()
    }

    // MARK: - First run

    func testFirstRunOnboardingToTrialPage() {
        launch(onboarded: false)
        capture("01_onboarding_page0")
        tap("Weiter"); capture("02_onboarding_page1")
        tap("Weiter"); capture("03_onboarding_page2")
        tap("Weiter"); capture("04_skill_page_nothing_chosen")
        frame("Weiter", "skill page Weiter (disabled until choice)")
        // A swipe must not skip the question.
        app.swipeLeft(); settle(0.8)
        capture("05_skill_page_after_swipe_left")
        tap("Ganz neu"); settle(0.5)
        capture("06_skill_page_chosen")
        tap("Weiter"); settle(1.2)
        capture("07_trial_page")
        frame("Loslegen", "trial page soft exit 'Loslegen'")
        frame("Wiederherstellen", "trial page Wiederherstellen")
        frame("Nutzungsbedingungen", "trial page Nutzungsbedingungen")
        frame("Datenschutz", "trial page Datenschutz")
        dumpLabels("trial page labels")
        // Restore as a free account.
        tap("Wiederherstellen"); settle(1.5)
        capture("08_trial_restore_result")
        tapIfExists("OK"); settle(0.6)
        // The primary CTA with no price loaded (sim has no store).
        let cta = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@ OR label CONTAINS[c] %@", "Skat+", "Tage")).firstMatch
        notes.append("primary CTA label: \(cta.exists ? cta.label : "not found")")
        if cta.exists { cta.tap(); settle(2.0) }
        capture("09_trial_cta_tapped_no_price")
        if app.buttons["Schließen"].exists {
            capture("09b_fallback_paywall_open")
            app.buttons["Schließen"].tap(); settle(1.0)
        }
        // Free exit.
        tap("Loslegen"); settle(1.5)
        capture("10_after_loslegen_primer")
        tapIfExists("Für später überspringen"); settle(1.5)
        capture("11_after_skip_home_or_tour")
        tapIfExists("Tour überspringen"); settle(1.5)
        capture("12_home_after_onboarding")
        attach("notes", notes.joined(separator: "\n"))
    }

    // MARK: - Free player on Home, rooms, paywall

    func testFreeHomeLocksAndPaywall() {
        launch(onboarded: true)
        capture("20_free_home_top")
        app.swipeUp(); settle(0.8)
        capture("21_free_home_scrolled")
        app.swipeDown(); settle(0.6)
        dumpLabels("home labels")
        // Which of the five training tiles are locked?
        for tile in ["Endlos", "Skat", "Skatabend", "90", "Fehler"] {
            let hit = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", tile)).firstMatch
            notes.append("tile \(tile): \(hit.exists ? "label=\(hit.label) hint=\(hit.value ?? "")" : "absent")")
        }
        // Locked tile -> paywall
        if open("Endlos") {
            settle(1.2)
            capture("22_paywall_from_endlos_tile")
            frame("Wiederherstellen", "paywall Wiederherstellen")
            frame("Nutzungsbedingungen", "paywall Nutzungsbedingungen")
            frame("Datenschutz", "paywall Datenschutz")
            frame("Schließen", "paywall Schließen")
            dumpLabels("paywall labels")
            app.swipeUp(); settle(0.6)
            capture("23_paywall_scrolled")
            tap("Wiederherstellen"); settle(1.5)
            capture("24_paywall_restore_free_result")
            tapIfExists("OK"); settle(0.6)
            tap("Monatlich"); settle(0.6)
            capture("25_paywall_monthly_selected")
            tap("Dauerhaft"); settle(0.6)
            capture("26_paywall_lifetime_selected")
            // Cancel path: the close button
            tapIfExists("Schließen"); settle(1.0)
            capture("27_home_after_paywall_close")
        }
        // Skat Minute tile (a daily ritual): is it locked?
        if open("Skat\nMinute") || open("Skat Minute") {
            settle(1.0)
            capture("28_skat_minute_tile_result")
            tapIfExists("Schließen"); settle(0.8)
        }
        if open("Skatabend") {
            settle(1.0)
            capture("29_skatabend_tile_result")
            tapIfExists("Schließen"); settle(0.8)
        }
        if open("Loslegen") {
            capture("30_free_quick_session")
            home()
        }
        attach("notes", notes.joined(separator: "\n"))
    }

    func testFreeRoomsAndLockedDrills() {
        launch(onboarded: true)
        if open("Karten & Reizen") {
            capture("40_free_room_top")
            app.swipeUp(); settle(0.8)
            capture("41_free_room_scrolled")
            app.swipeDown(); settle(0.5)
            // First locked row
            let locked = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Skat+")).firstMatch
            notes.append("room locked row: \(locked.exists ? locked.label : "none")")
            if locked.exists {
                locked.tap(); settle(1.2)
                capture("42_paywall_from_locked_drill")
                // dismiss by swipe-down gesture
                app.swipeDown(velocity: .fast); settle(1.0)
                capture("43_room_after_swipe_dismiss")
            }
            home()
        }
        if open("Meistertisch") {
            settle(1.0)
            capture("44_meistertisch_room")
            app.swipeUp(); settle(0.6)
            capture("45_meistertisch_scrolled")
            home()
        }
        attach("notes", notes.joined(separator: "\n"))
    }

    func testFreeSettingsRestoreAndManage() {
        launch(onboarded: true)
        let gear = app.navigationBars.buttons.element(boundBy: 0)
        if gear.exists { gear.tap() } else { notes.append("no gear") }
        settle(1.2)
        capture("50_settings_free_top")
        dumpLabels("settings labels")
        app.swipeUp(); settle(0.6)
        capture("51_settings_free_scrolled")
        tap("Käufe wiederherstellen"); settle(1.8)
        capture("52_settings_restore_alert_free")
        tapIfExists("OK"); settle(0.6)
        tap("Skat+ entdecken"); settle(1.2)
        capture("53_settings_paywall")
        tapIfExists("Schließen"); settle(0.8)
        attach("notes", notes.joined(separator: "\n"))
    }

    // MARK: - Member / return visit

    func testMemberSettingsAndReturnVisit() {
        launch(onboarded: true, member: true)
        capture("60_member_home")
        let gear = app.navigationBars.buttons.element(boundBy: 0)
        if gear.exists { gear.tap() } else { notes.append("no gear") }
        settle(1.2)
        capture("61_member_settings_top")
        dumpLabels("member settings labels")
        notes.append("manage link present: \(app.links["Abonnement verwalten"].exists || app.buttons["Abonnement verwalten"].exists)")
        app.swipeUp(); settle(0.6)
        capture("62_member_settings_scrolled")
        tap("Fortschritt zurücksetzen"); settle(1.0)
        capture("63_reset_alert")
        tapIfExists("Abbrechen"); settle(0.6)
        attach("notes", notes.joined(separator: "\n"))
    }

    func testLargeTextPaywallAndTrialPage() {
        launch(onboarded: false, extra: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXL"])
        capture("70_axxxl_onboarding0")
        // Try to reach the trial page. Skill page needs a choice.
        for _ in 0..<3 { tapIfExists("Weiter"); settle(0.8) }
        tapIfExists("Ganz neu"); settle(0.5)
        capture("71_axxxl_skill")
        tapIfExists("Weiter"); settle(1.2)
        capture("72_axxxl_trial_page")
        app.swipeUp(); settle(0.6)
        capture("73_axxxl_trial_scrolled")
        dumpLabels("axxxl trial labels")
        attach("notes", notes.joined(separator: "\n"))
    }

    // MARK: - Helpers

    @discardableResult
    private func open(_ label: String) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS %@", label)
        for query in [app.buttons, app.staticTexts] {
            let match = query.matching(predicate).firstMatch
            guard match.waitForExistence(timeout: 4) else { continue }
            match.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            settle()
            return true
        }
        notes.append("could not open: \(label)")
        return false
    }

    private func tap(_ label: String) {
        let predicate = NSPredicate(format: "label CONTAINS %@", label)
        for query in [app.buttons, app.staticTexts] {
            let match = query.matching(predicate).firstMatch
            if match.waitForExistence(timeout: 4) {
                match.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
                settle(0.8)
                return
            }
        }
        notes.append("could not tap: \(label)")
    }

    private func tapIfExists(_ label: String) {
        let match = app.buttons[label].firstMatch
        if match.exists { match.tap(); settle(0.6) }
    }

    private func frame(_ label: String, _ what: String) {
        let match = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", label)).firstMatch
        if match.exists {
            let f = match.frame
            notes.append("FRAME \(what): w=\(Int(f.width)) h=\(Int(f.height)) at y=\(Int(f.minY)) hittable=\(match.isHittable) enabled=\(match.isEnabled)")
        } else {
            notes.append("FRAME \(what): not found")
        }
    }

    private func dumpLabels(_ name: String) {
        var lines: [String] = []
        for element in app.descendants(matching: .any).allElementsBoundByIndex.prefix(250) {
            let label = element.label
            guard !label.isEmpty else { continue }
            let f = element.frame
            lines.append("\(element.elementType.rawValue) \"\(label)\" \(Int(f.minX)),\(Int(f.minY)) \(Int(f.width))x\(Int(f.height)) hittable=\(element.isHittable)")
        }
        attach(name, lines.joined(separator: "\n"))
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

    private func settle(_ seconds: TimeInterval = 1.2) { Thread.sleep(forTimeInterval: seconds) }

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
