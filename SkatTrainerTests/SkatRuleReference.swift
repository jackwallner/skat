import Foundation
@testable import SkatTrainer

/// ISkO 2.2 through 2.6, 3.6 and 4.2/4.3. nil trump means Grand.
enum SkatRuleReference {
    static func isTrump(_ card: PlayingCard, trump: Suit?, null: Bool = false) -> Bool {
        !null && (card.isJack || (trump != nil && card.suit == trump))
    }
    static func legal(_ hand: [PlayingCard], led: PlayingCard, trump: Suit?, null: Bool = false) -> [PlayingCard] {
        let following = hand.filter {
            isTrump(led, trump: trump, null: null) ? isTrump($0, trump: trump, null: null)
                : !isTrump($0, trump: trump, null: null) && $0.suit == led.suit
        }
        return following.isEmpty ? hand : following
    }
    static func winner(_ trick: [PlayingCard], trump: Suit?, null: Bool = false) -> Int? {
        guard let led = trick.first else { return nil }
        func strength(_ card: PlayingCard) -> Int {
            if isTrump(card, trump: trump, null: null) {
                if card.isJack { return 200 - Suit.allCases.firstIndex(of: card.suit!)! }
                return 100 + [7, 8, 9, 12, 13, 10, 14].firstIndex(of: card.rankValue)!
            }
            guard !isTrump(led, trump: trump, null: null), card.suit == led.suit else { return 0 }
            return 10 + (null ? card.rankValue : [7, 8, 9, 12, 13, 10, 14].firstIndex(of: card.rankValue)!)
        }
        return trick.indices.max { strength(trick[$0]) < strength(trick[$1]) }
    }
    static func matadors(_ cardsIncludingSkat: [PlayingCard], trump: Suit?) -> Int {
        let jacks: [PlayingCard] = [.c(11), .s(11), .h(11), .d(11)]
        let order = jacks + (trump.map { suit in [14, 10, 13, 12, 9, 8, 7].map { PlayingCard.standard(rank: $0, suit: suit) } } ?? [])
        let withTop = cardsIncludingSkat.contains(order[0])
        return order.prefix { cardsIncludingSkat.contains($0) == withTop }.count
    }
    static func score(base: Int, matadors: Int, hand: Bool = false, points: Int, tricks: Int,
                      bid: Int, schneider: Bool = false, schwarz: Bool = false, ouvert: Bool = false) -> Int? {
        guard hand || !(schneider || schwarz || ouvert) else { return nil }
        let announcement = ouvert ? 5 : schwarz ? 4 : schneider ? 2 : 0
        let achieved = (points <= 30 || points >= 90 ? 1 : 0) + (tricks == 0 || tricks == 10 ? 1 : 0)
        let value = base * (matadors + 1 + (hand ? 1 : 0) + max(announcement, achieved))
        let win = points >= 61 && (!(schneider || schwarz || ouvert) || points >= 90)
            && (!(schwarz || ouvert) || tricks == 10) && value >= bid
        return win ? value : -2 * max(value, ((bid + base - 1) / base) * base)
    }
    /// Overbid Null requires the separate ISkO 3.6.2 suit/Grand valuation.
    static func nullScore(hand: Bool, ouvert: Bool, tricks: Int, bid: Int) -> Int? {
        let value = ouvert ? (hand ? 59 : 46) : (hand ? 35 : 23)
        guard bid <= value else { return nil }
        return tricks == 0 ? value : -2 * value
    }
}
