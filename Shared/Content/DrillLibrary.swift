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
                    id: "applied-bidding",
                    title: "Reizen am Beispiel",
                    subtitle: "Zwölf konkrete Fälle zu Spitzen und Reizdeckung",
                    kind: .quiz(AppliedContent.bidding)
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
                    id: "applied-tricks",
                    title: "Welche Karte ist legal?",
                    subtitle: "Zwölf konkrete Stiche mit klarer Spielansage",
                    kind: .quiz(AppliedContent.tricks)
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
                    subtitle: "Acht Drückziele mit Spielart, Position und Reizwert",
                    kind: .discard(AdvancedContent.discards)
                ),
                Drill(
                    id: "master-defense",
                    title: "Verteidigung",
                    subtitle: "20 Situationen: schmieren, stechen, zählen",
                    kind: .quiz(AdvancedContent.defense)
                ),
                Drill(
                    id: "master-counting",
                    title: "Spielwert sicher rechnen",
                    subtitle: "24 Rechnungen mit Hand, Ansagen und Überreizen",
                    kind: .quiz(AdvancedContent.scoring)
                ),
                Drill(
                    id: "master-rules",
                    title: "Null: Angriff und Rettung",
                    subtitle: "20 konkrete Fälle zu Zwangsstichen und Reizgrenzen",
                    kind: .quiz(AdvancedContent.nullPlay)
                ),
                Drill(
                    id: "master-endgames",
                    title: "Die letzten Stiche",
                    subtitle: "20 Endspiele mit Restkarten und Augenbilanz",
                    kind: .quiz(AdvancedContent.endgames)
                ),
                Drill(
                    id: "master-three-tricks",
                    title: "Drei Stiche voraus",
                    subtitle: "Acht vollständige Endspiele gegen optimale Abwehr",
                    kind: .quiz(AdvancedContent.planning)
                ),
            ]
        ),
    ]

    static func room(id: String) -> Room? { rooms.first { $0.id == id } }

    static func roomID(forDrillID drillID: String) -> String {
        rooms.first { $0.drills.contains { $0.id == drillID } }?.id ?? ""
    }
}
