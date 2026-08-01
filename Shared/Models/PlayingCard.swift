import Foundation

enum Suit: String, Codable, CaseIterable, Hashable, Sendable {
    case clubs, spades, hearts, diamonds

    var symbol: String {
        switch self {
        case .clubs: return "♣"
        case .spades: return "♠"
        case .hearts: return "♥"
        case .diamonds: return "♦"
        }
    }

    var displayName: String {
        switch self {
        case .clubs: return "Kreuz"
        case .spades: return "Pik"
        case .hearts: return "Herz"
        case .diamonds: return "Karo"
        }
    }
}

enum PlayingCard: Hashable, Codable, Sendable {
    case standard(rank: Int, suit: Suit)
    case joker

    static let skatRanks = Array(7...14)

    static func c(_ rank: Int) -> PlayingCard { .standard(rank: rank, suit: .clubs) }
    static func s(_ rank: Int) -> PlayingCard { .standard(rank: rank, suit: .spades) }
    static func h(_ rank: Int) -> PlayingCard { .standard(rank: rank, suit: .hearts) }
    static func d(_ rank: Int) -> PlayingCard { .standard(rank: rank, suit: .diamonds) }

    var shortLabel: String {
        switch self {
        case .standard(let rank, let suit): return "\(Self.rankLabel(rank))\(suit.symbol)"
        case .joker: return "Joker"
        }
    }

    var spokenName: String {
        switch self {
        case .standard(let rank, let suit): return "\(Self.rankName(rank)) \(suit.displayName)"
        case .joker: return "Joker"
        }
    }

    var suit: Suit? {
        guard case .standard(_, let suit) = self else { return nil }
        return suit
    }

    var rankValue: Int {
        switch self {
        case .standard(let rank, _): return rank
        case .joker: return 0
        }
    }

    /// Card points used when counting tricks in a normal suit or Grand game.
    var skatValue: Int {
        switch self {
        case .standard(let rank, _):
            switch rank {
            case 11: return 2
            case 12: return 3
            case 13: return 4
            case 14: return 11
            default: return rank == 10 ? 10 : 0
            }
        case .joker: return 0
        }
    }

    var isJack: Bool { rankValue == 11 }

    var sortKey: Int {
        switch self {
        case .standard(let rank, let suit):
            let suitOrder: [Suit: Int] = [.clubs: 0, .spades: 1, .hearts: 2, .diamonds: 3]
            return (suitOrder[suit] ?? 0) * 20 + rank
        case .joker: return 100
        }
    }

    static func rankLabel(_ rank: Int) -> String {
        switch rank {
        case 11: return "B"
        case 12: return "D"
        case 13: return "K"
        case 14: return "A"
        default: return String(rank)
        }
    }

    static func rankName(_ rank: Int) -> String {
        switch rank {
        case 11: return "Bube"
        case 12: return "Dame"
        case 13: return "König"
        case 14: return "Ass"
        default: return String(rank)
        }
    }
}

extension Array where Element == PlayingCard {
    var racked: [PlayingCard] { sorted { $0.sortKey < $1.sortKey } }
}
