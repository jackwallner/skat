import Foundation

/// Teaching categories for the parts of a Skat hand that players learn to
/// recognise first. They describe practice concepts, not a complete rules
/// engine or a particular deal from a card.
enum HandCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case karten
    case reizen
    case trumpf
    case grand
    case nullspiel
    case farbe
    case stich
    case spielwert
    case endspiel

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .karten: return "Karten"
        case .reizen: return "Reizen"
        case .trumpf: return "Trumpf"
        case .grand: return "Grand"
        case .nullspiel: return "Null"
        case .farbe: return "Farbe"
        case .stich: return "Stich"
        case .spielwert: return "Spielwert"
        case .endspiel: return "Endspiel"
        }
    }

    var shortName: String { displayName }

    var howToSpot: String {
        switch self {
        case .karten:
            return "Präge dir die 32 Karten, ihre Augenwerte und die Reihenfolge in jeder Spielart ein."
        case .reizen:
            return "Beim Reizen vergleichst du deine Position und Kartenstärke mit dem Spielwert, den du übernehmen kannst."
        case .trumpf:
            return "Im Farbspiel sind alle vier Buben und die angesagte Farbe Trumpf. Zähle die Trumpfstärke vor dem Reizen."
        case .grand:
            return "Im Grand sind nur die vier Buben Trumpf. Die übrigen Farben werden normal bedient."
        case .nullspiel:
            return "Im Null gibt es keinen Trumpf und keine Augen. Das Ziel ist, keinen Stich zu bekommen."
        case .farbe:
            return "Wer eine angespielte Farbe hat, muss sie bedienen. Erst ohne diese Farbe darfst du frei wählen."
        case .stich:
            return "Der höchste Trumpf gewinnt, sonst die höchste Karte der angespielten Farbe."
        case .spielwert:
            return "Der Spielwert entsteht aus Grundwert, Spitzen und dem angesagten Spiel. Hand und Schneider können ihn verändern."
        case .endspiel:
            return "Im letzten Drittel zählen sichere Stiche, Restkarten und die Gewinnbedingung mehr als schöne Einzelkarten."
        }
    }
}
