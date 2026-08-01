import SwiftUI

/// A compact, readable playing-card face. The app teaches skat decisions,
/// so rank and suit stay legible even when a hand is shown at drill width.
struct PlayingCardView: View {
    let tile: PlayingCard
    var width: CGFloat = 44

    private var height: CGFloat { width * 1.42 }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: width * 0.16)
                .fill(Theme.card)
                .shadow(color: .black.opacity(0.22), radius: 1.5, y: 1.5)
            RoundedRectangle(cornerRadius: width * 0.16)
                .strokeBorder(Theme.cardEdge, lineWidth: 1)
            face
        }
        .frame(width: width, height: height)
        .accessibilityLabel(tile.spokenName)
    }

    @ViewBuilder
    private var face: some View {
        switch tile {
        case .standard(let rank, let suit):
            VStack(spacing: 2) {
                HStack(spacing: 2) {
                    Text(PlayingCard.rankLabel(rank))
                        .font(.system(size: width * 0.32, weight: .bold, design: .serif))
                    Text(suit.symbol)
                        .font(.system(size: width * 0.26, weight: .bold))
                }
                .foregroundStyle(suitColor(suit))
                Text(suit.symbol)
                    .font(.system(size: width * 0.52, weight: .regular))
                    .foregroundStyle(suitColor(suit))
                Text(PlayingCard.rankLabel(rank))
                    .font(.system(size: width * 0.23, weight: .bold, design: .serif))
                    .foregroundStyle(suitColor(suit))
            }
        case .joker:
            VStack(spacing: 3) {
                Image(systemName: "sparkles")
                    .font(.system(size: width * 0.36, weight: .semibold))
                Text("JOKER")
                    .font(.system(size: max(7, width * 0.15), weight: .heavy))
            }
            .foregroundStyle(Theme.plum)
        }
    }

    private func suitColor(_ suit: Suit) -> Color {
        switch suit {
        case .diamonds, .hearts: return Theme.coral
        case .clubs, .spades: return Theme.ink
        }
    }
}

/// A wrapping row of playing cards, ordered for a quick visual scan.
struct CardHandView: View {
    let tiles: [PlayingCard]
    var tileWidth: CGFloat = 44
    var highlightedIndices: Set<Int> = []
    var onTap: ((Int) -> Void)?

    private let columns = 7

    var body: some View {
        let rows = tiles.enumerated().map { (index: $0.offset, tile: $0.element) }
            .chunked(into: columns)
        VStack(spacing: 10) {
            ForEach(0..<rows.count, id: \.self) { rowIndex in
                HStack(spacing: 6) {
                    ForEach(rows[rowIndex], id: \.index) { item in
                        tileCell(item.index, item.tile)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func tileCell(_ index: Int, _ tile: PlayingCard) -> some View {
        let selected = highlightedIndices.contains(index)
        PlayingCardView(tile: tile, width: tileWidth)
            .overlay {
                if selected {
                    RoundedRectangle(cornerRadius: tileWidth * 0.16)
                        .strokeBorder(Theme.gold, lineWidth: 3)
                }
            }
            .offset(y: selected ? -8 : 0)
            .onTapGesture { onTap?(index) }
            .animation(.spring(duration: 0.25), value: selected)
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
