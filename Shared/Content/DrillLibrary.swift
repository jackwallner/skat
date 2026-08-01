import Foundation

enum DrillLibrary {
    static let rooms: [Room] = [
        Room(
            id: "card-room",
            name: "Karten & Reizen",
            tagline: "Lerne die 32 Karten und den Weg zum Spiel",
            icon: "rectangle.portrait.on.rectangle.portrait.angled",
            isFree: true,
            drills: [
                Drill(
                    id: "meet-cards",
                    title: "Die Karten kennenlernen",
                    subtitle: "Karteikarten: Farben, Augen, Buben und Reizen",
                    kind: .flashcards(CardBasicsContent.meetTheCards)
                ),
                Drill(
                    id: "card-quiz",
                    title: "Karten-Check",
                    subtitle: "Schnelles Quiz zu den Grundlagen",
                    kind: .quiz(CardBasicsContent.cardQuiz)
                ),
                Drill(
                    id: "plus-card-extras",
                    title: "Karten-Check: Extra-Runden",
                    subtitle: "Mehr Fragen zu Blatt, Skat und Reizposition",
                    kind: .quiz(PlusContent.cardExtras + MoreContent.cardExtras),
                    isPlus: true
                ),
            ]
        ),
        Room(
            id: "scoring-room",
            name: "Spielarten",
            tagline: "Erkenne Trumpf, Grand, Null und sichere Stiche",
            icon: "suit.club.fill",
            isFree: true,
            drills: [
                Drill(
                    id: "scoring-cards",
                    title: "Spielarten verstehen",
                    subtitle: "Karteikarten: Trumpf, Grand, Null und Stich",
                    kind: .flashcards(CategoryContent.categoryCards)
                ),
                Drill(
                    id: "hand-match",
                    title: "Die Struktur lesen",
                    subtitle: "Fünf Karten sehen und die Idee benennen",
                    kind: .handMatch(CategoryContent.handMatch)
                ),
                Drill(
                    id: "plus-hand-extras",
                    title: "Struktur lesen: Extra-Runden",
                    subtitle: "Weitere Muster für Spielart und Stich",
                    kind: .handMatch(PlusContent.extraHandReading + MoreContent.handReading),
                    isPlus: true
                ),
            ]
        ),
        Room(
            id: "discard-room",
            name: "Drücken",
            tagline: "Lege zwei Karten mit einem Plan in den Skat",
            icon: "arrow.down.to.line.compact",
            isFree: true,
            drills: [
                Drill(
                    id: "discard-rules",
                    title: "Das Drücken lernen",
                    subtitle: "Karteikarten: Skat aufnehmen und zwei Karten ablegen",
                    kind: .flashcards(DiscardContent.strategyCards)
                ),
                Drill(
                    id: "discard-two",
                    title: "Dein Skat",
                    subtitle: "Zwölf Karten: Wähle zwei und vergleiche die Lehrentscheidung",
                    kind: .discard(DiscardContent.scenarios)
                ),
                Drill(
                    id: "plus-discard-extras",
                    title: "Dein Skat: Extra-Runden",
                    subtitle: "Weitere Entscheidungen für Farbe, Grand und Null",
                    kind: .discard(PlusContent.extraDiscards + MoreContent.discardExtras),
                    isPlus: true
                ),
            ]
        ),
        Room(
            id: "pegging-room",
            name: "Stichspiel",
            tagline: "Bediene Farben und hole die richtigen Stiche",
            icon: "arrow.up.right.circle.fill",
            isFree: true,
            drills: [
                Drill(
                    id: "pegging-judgment",
                    title: "Stich-Entscheidungen",
                    subtitle: "Entscheide, bediene und drehe die Karte um",
                    kind: .flashcards(KeepDiscardContent.judgmentCards)
                ),
                Drill(
                    id: "pegging-quiz",
                    title: "Stichregeln",
                    subtitle: "Bedienpflicht, Trumpf, Stichgewinn und Null",
                    kind: .quiz(MoreContent.tableQuiz)
                ),
                Drill(
                    id: "plus-pegging-extras",
                    title: "Stich-Entscheidungen: Extra-Runden",
                    subtitle: "Weitere Situationen für Farbe, Trumpf und Endspiel",
                    kind: .flashcards(PlusContent.extraJudgment + MoreContent.judgment),
                    isPlus: true
                ),
            ]
        ),
        Room(
            id: "pro-tables",
            name: "Der Meistertisch",
            tagline: "Reizen, Spielwert und schwierige Endspiele",
            icon: "crown.fill",
            isFree: false,
            drills: [
                Drill(
                    id: "master-discard",
                    title: "Meisterhaft drücken",
                    subtitle: "Hand, Skat und Spielwert gemeinsam beurteilen",
                    kind: .discard(ProContent.advancedDiscard)
                ),
                Drill(
                    id: "master-defense",
                    title: "Verteidigung",
                    subtitle: "Karten verfolgen und den Gegenspieler lesen",
                    kind: .quiz(ProContent.defenseQuiz)
                ),
                Drill(
                    id: "master-counting",
                    title: "Spielwert sicher rechnen",
                    subtitle: "Spitzen, Grundwert und Gewinnstufe verbinden",
                    kind: .handMatch(ProContent.expertHandReading)
                ),
                Drill(
                    id: "master-rules",
                    title: "Meisterregeln",
                    subtitle: "Reizen, Handspiel, Schneider und Null ouvert",
                    kind: .quiz(MoreContent.advancedRules)
                ),
            ]
        ),
    ]

    static func room(id: String) -> Room? { rooms.first { $0.id == id } }

    static func roomID(forDrillID drillID: String) -> String {
        rooms.first { $0.drills.contains { $0.id == drillID } }?.id ?? ""
    }
}
