import Foundation

/// The game types the generated trick and Spitzen questions are asked in.
enum TrickGame: Equatable, Sendable {
    case suit(Suit)
    case grand
    case null

    var title: String {
        switch self {
        case .suit(let suit): return "\(suit.displayName)-Farbspiel"
        case .grand: return "Grand"
        case .null: return "Null"
        }
    }

    /// One sentence the player can check the answer against.
    var trumpDescription: String {
        switch self {
        case .suit(let suit): return "Trumpf sind alle vier Buben und alle \(suit.displayName)-Karten"
        case .grand: return "Trumpf sind nur die vier Buben"
        case .null: return "Es gibt keinen Trumpf, der Bube steht zwischen Dame und Zehn"
        }
    }
}

/// Card order and trick resolution for the 32-card Skat deck under the
/// standard (Deutscher Skatverband) order. Kept free of UI so generated
/// questions can be checked against it in tests.
enum SkatRules {
    /// Buben, highest first: Kreuz, Pik, Herz, Karo.
    static let jackOrder: [Suit] = [.clubs, .spades, .hearts, .diamonds]

    /// Side order in Farbspiel and Grand, highest first.
    static let suitRankOrder = [14, 10, 13, 12, 9, 8, 7]

    /// Side order in Null, highest first. The Bube sits between Dame and Zehn.
    static let nullRankOrder = [14, 13, 12, 11, 10, 9, 8, 7]

    enum Family: Equatable {
        case trump
        case suit(Suit)
    }

    static func family(of card: PlayingCard, in game: TrickGame) -> Family {
        guard case .standard(let rank, let suit) = card else { return .trump }
        switch game {
        case .null:
            return .suit(suit)
        case .grand:
            return rank == 11 ? .trump : .suit(suit)
        case .suit(let trump):
            return (rank == 11 || suit == trump) ? .trump : .suit(suit)
        }
    }

    /// Strength inside the card's own family. Higher wins.
    static func strength(of card: PlayingCard, in game: TrickGame) -> Int {
        guard case .standard(let rank, let suit) = card else { return 0 }
        if game == .null {
            return 20 - (nullRankOrder.firstIndex(of: rank) ?? 20)
        }
        if rank == 11 {
            return 100 - (jackOrder.firstIndex(of: suit) ?? 0)
        }
        return 20 - (suitRankOrder.firstIndex(of: rank) ?? 20)
    }

    /// Index of the card that takes a trick, cards in play order. The first
    /// card sets the led family. A trump beats everything else, otherwise only
    /// the led family can win.
    static func winnerIndex(of trick: [PlayingCard], in game: TrickGame) -> Int {
        guard let first = trick.first else { return 0 }
        let hasTrump = trick.contains { family(of: $0, in: game) == .trump }
        let winningFamily = hasTrump ? Family.trump : family(of: first, in: game)
        var best = 0
        var bestStrength = -1
        for (index, card) in trick.enumerated() where family(of: card, in: game) == winningFamily {
            let value = strength(of: card, in: game)
            if value > bestStrength {
                best = index
                bestStrength = value
            }
        }
        return best
    }

    /// Augen in the trick. Null has no card points.
    static func points(in trick: [PlayingCard]) -> Int {
        trick.reduce(0) { $0 + $1.skatValue }
    }

    /// Spitzen from the Buben alone: "mit n" when the run of top Buben from
    /// Kreuz-Bube down is n long, otherwise "ohne n" for the run of missing
    /// top Buben. This is the Grand rule; in a Farbspiel the run continues
    /// into the trump suit, so questions state that they are about Grand.
    static func spitzen(holding jackSuits: Set<Suit>) -> (mit: Bool, count: Int) {
        let mit = jackSuits.contains(jackOrder[0])
        var count = 0
        for suit in jackOrder {
            guard jackSuits.contains(suit) == mit else { break }
            count += 1
        }
        return (mit, count)
    }
}
