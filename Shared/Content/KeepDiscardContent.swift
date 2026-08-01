import Foundation

/// Situationen für das Ausspielen und die Bedienpflicht.
enum KeepDiscardContent {
    static let judgmentCards: [Flashcard] = [
        Flashcard(
            id: "stich-entscheidung-1",
            frontTitle: "Farbe bedienen",
            frontTiles: [.h(14), .h(7), .c(13)],
            frontSubtitle: "Herz ist angespielt",
            backTitle: "Herz muss folgen",
            backBody: "Wenn du Herz hältst, musst du Herz bedienen. Der Herz-König darf nicht gespielt werden, solange noch eine Herzkarte auf deiner Hand liegt.",
            choice: CardChoice("Herz bedienen", "Eine fremde Farbe spielen", answerIndex: 0)
        ),
        Flashcard(
            id: "stich-entscheidung-2",
            frontTitle: "Keine Farbe vorhanden",
            frontTiles: [.h(14), .c(11)],
            frontSubtitle: "Herz ist angespielt, du hast kein Herz",
            backTitle: "Jetzt darfst du frei wählen",
            backBody: "Ohne Karte der angespielten Farbe darfst du eine andere Farbe oder einen Trumpf spielen. Die Bedienpflicht entfällt erst dann.",
            choice: CardChoice("Frei wählen", "Trotzdem Herz legen", answerIndex: 0)
        ),
        Flashcard(
            id: "stich-entscheidung-3",
            frontTitle: "Trumpf ziehen",
            frontTiles: [.c(11), .h(14), .h(10)],
            frontSubtitle: "Kreuz-Bube schlägt Herz-Ass",
            backTitle: "Trumpf gewinnt vor Farbe",
            backBody: "Der Kreuz-Bube ist in einem Farbspiel Trumpf. Er gewinnt den Stich auch dann, wenn eine hohe Karte der angespielten Farbe liegt.",
            choice: CardChoice("Trumpf gewinnt", "Das Herz-Ass gewinnt immer", answerIndex: 0)
        ),
        Flashcard(
            id: "stich-entscheidung-4",
            frontTitle: "Trumpfreihenfolge",
            frontTiles: [.c(11), .s(11), .h(11), .d(11)],
            frontSubtitle: "Die Buben von oben nach unten",
            backTitle: "Kreuz vor Pik vor Herz vor Karo",
            backBody: "Die Buben haben in jeder normalen Spielart dieselbe Reihenfolge. Der Kreuz-Bube ist der höchste, der Karo-Bube der niedrigste Bube.",
            choice: CardChoice("Kreuz-Bube ist höher", "Karo-Bube ist höher", answerIndex: 0)
        ),
        Flashcard(
            id: "stich-entscheidung-5",
            frontTitle: "Nullspiel",
            frontTiles: [.c(14), .c(7), .s(11)],
            frontSubtitle: "Kein Trumpf im Null",
            backTitle: "Das Ass bleibt hoch",
            backBody: "Im Null sind die Buben keine Trümpfe. Die normale Kartenreihenfolge gilt, und das Ass ist die höchste Karte der Farbe.",
            choice: CardChoice("Ass ist hoch", "Bube ist Trumpf", answerIndex: 0)
        ),
        Flashcard(
            id: "stich-entscheidung-6",
            frontTitle: "Den Stich sichern",
            frontTiles: [.c(11), .h(14), .h(7)],
            frontSubtitle: "Wann reicht eine kleine Karte?",
            backTitle: "Nicht jeden Stich überstechen",
            backBody: "Wenn dein Partner den Stich sicher gewinnt, musst du keinen höheren Trumpf verschenken. Das genaue Zeichen dafür hängt vom Tisch und der Karteninformation ab.",
            choice: CardChoice("Kleine Karte kann reichen", "Immer den höchsten Trumpf spielen", answerIndex: 0)
        ),
    ]
}
