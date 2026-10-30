import Darwin
import SwiftUI
import UIKit
import XCTest
@testable import SkatTrainer

/// SwiftUI only builds its accessibility tree once an assistive client is
/// attached. Turning on automation accessibility (what XCUITest does) makes
/// the hosted tree readable in-process. Test bundle only, never the app.
private func enableAutomationAccessibility() {
    guard let handle = dlopen("/usr/lib/libAccessibility.dylib", RTLD_NOW),
          let symbol = dlsym(handle, "_AXSSetAutomationEnabled") else { return }
    typealias SetEnabled = @convention(c) (Int32) -> Void
    unsafeBitCast(symbol, to: SetEnabled.self)(1)
}

@MainActor
final class DrillAccessibilityTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        enableAutomationAccessibility()
        suiteName = "DrillAccessibilityTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    // MARK: - Drücken deal width

    private var twelveCards: [PlayingCard] {
        Array(Suit.allCases.flatMap { suit in
            PlayingCard.skatRanks.map { PlayingCard.standard(rank: $0, suit: suit) }
        }.prefix(12))
    }

    /// 343, 358, 361 and 370 are the drill column on 375, 390, 393 and 402 pt
    /// phones; 288 is an iPad in Slide Over.
    func testTwelveCardDealFitsCommonPhoneWidths() {
        for width in [288.0, 343, 358, 361, 370] {
            for tileWidth in [44.0, 48] {
                let host = UIHostingController(rootView: CardHandView(tiles: twelveCards, tileWidth: tileWidth))
                let size = host.sizeThatFits(in: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude))
                XCTAssertLessThanOrEqual(size.width, width, "12 cards at \(tileWidth) pt overflow a \(width) pt column")
            }
        }
    }

    func testShortHandKeepsItsRequestedSize() {
        let hand = Array(twelveCards.prefix(4))
        let host = UIHostingController(rootView: CardHandView(tiles: hand, tileWidth: 48))
        let size = host.sizeThatFits(in: CGSize(width: 343, height: CGFloat.greatestFiniteMagnitude))
        XCTAssertEqual(size.width, 4 * 48 + 3 * 6, accuracy: 0.5)
    }

    // MARK: - VoiceOver flashcard grading

    private func elements(in object: NSObject, depth: Int = 0) -> [NSObject] {
        guard depth < 40 else { return [] }
        var found: [NSObject] = []
        if object.isAccessibilityElement { found.append(object) }
        var children: [NSObject] = []
        if let listed = object.accessibilityElements as? [NSObject] {
            children = listed
        } else {
            let count = object.accessibilityElementCount()
            if count > 0, count != NSNotFound {
                children = (0..<count).compactMap { object.accessibilityElement(at: $0) as? NSObject }
            }
            if let view = object as? UIView { children += view.subviews }
        }
        for child in children { found += elements(in: child, depth: depth + 1) }
        return found
    }

    private func labels(in window: UIWindow) -> [String] {
        elements(in: window).compactMap(\.accessibilityLabel)
    }

    private func topCard(in window: UIWindow, label: String) -> NSObject? {
        elements(in: window).first { ($0.accessibilityLabel ?? "").hasPrefix(label) }
    }

    private func settle(_ seconds: Double = 0.2) async throws {
        try await Task.sleep(for: .milliseconds(Int(seconds * 1000)))
    }

    /// A VoiceOver user double-taps to flip, then uses the rotor actions to
    /// grade. Every plain card must be reachable that way, or the deck never
    /// finishes.
    func testVoiceOverCanFlipAndGradeEveryPlainCard() async throws {
        let cards = [
            Flashcard(id: "vo-1", frontTitle: "Karte eins", backTitle: "Rückseite eins", backBody: "Erklärung eins"),
            Flashcard(id: "vo-2", frontTitle: "Karte zwei", backTitle: "Rückseite zwei", backBody: "Erklärung zwei"),
        ]
        let drill = Drill(id: "vo-deck", title: "Deck", subtitle: "", kind: .flashcards(cards))
        let progress = ProgressStore(defaults: defaults)
        let view = NavigationStack {
            FlashcardDrillView(drill: drill, cards: cards)
        }
        .environmentObject(progress)
        .environmentObject(SubscriptionService.shared)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        window.rootViewController = UIHostingController(rootView: view)
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        try await settle()
        // The harness itself must see the SwiftUI tree, or a miss below means nothing.
        XCTAssertTrue(labels(in: window).contains("0 von 2 geschafft"), "tree: \(labels(in: window))")

        for (index, card) in cards.enumerated() {
            let front = try XCTUnwrap(topCard(in: window, label: card.frontTitle),
                                      "front of card \(index + 1) not exposed: \(labels(in: window))")
            XCTAssertTrue(front.accessibilityActivate(), "double-tap must flip card \(index + 1)")
            try await settle(0.7)

            let back = try XCTUnwrap(topCard(in: window, label: card.backTitle),
                                     "card \(index + 1) did not flip: \(labels(in: window))")
            let actions = back.accessibilityCustomActions ?? []
            let names = actions.map(\.name)
            XCTAssertTrue(names.contains("Gewusst"), "actions on card \(index + 1): \(names)")
            XCTAssertTrue(names.contains("Nochmal"), "actions on card \(index + 1): \(names)")
            let knew = try XCTUnwrap(actions.first { $0.name == "Gewusst" })
            if let handler = knew.actionHandler {
                XCTAssertTrue(handler(knew))
            } else {
                XCTFail("Gewusst has no handler")
            }
            try await settle(0.7)
        }

        XCTAssertEqual(progress.completions(for: drill.id), 1, "deck must finish through VoiceOver alone")
    }
}
