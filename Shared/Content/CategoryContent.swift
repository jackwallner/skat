import Foundation

/// Die Spielarten und ihre ersten erkennbaren Strukturen.
enum CategoryContent {
    static let categoryCards: [Flashcard] = [
        Flashcard(
            id: "spielarten-trumpf",
            frontTitle: "Trumpf im Farbspiel",
            frontTiles: [.c(11), .s(11), .h(14), .h(10)],
            frontSubtitle: "Vier Buben plus eine Farbe",
            backTitle: "Buben schlagen die Farbe",
            backBody: "Bei einem Herzspiel sind Kreuz-, Pik-, Herz- und Karo-Bube Trumpf. Danach folgen Herz-Ass, Herz-Zehn, Herz-König, Herz-Dame, Herz-Neun, Herz-Acht und Herz-Sieben."
        ),
        Flashcard(
            id: "spielarten-grand",
            frontTitle: "Grand",
            frontTiles: [.c(11), .s(11), .h(11), .d(11)],
            frontSubtitle: "Nur die Buben sind Trumpf",
            backTitle: "Die vier Buben zuerst",
            backBody: "Im Grand sind nur die vier Buben Trumpf. In jeder anderen Farbe gilt die normale Reihenfolge mit Ass, Zehn, König, Dame, Neun, Acht, Sieben."
        ),
        Flashcard(
            id: "spielarten-null",
            frontTitle: "Null",
            frontTiles: [.c(7), .d(8), .h(9), .s(10)],
            frontSubtitle: "Kein Trumpf, kein Stich",
            backTitle: "Das Ass ist hoch",
            backBody: "Im Nullspiel gibt es keinen Trumpf und keine Augen. Die normale Reihenfolge gilt, das Ass ist hoch. Der Alleinspieler darf keinen Stich bekommen."
        ),
        Flashcard(
            id: "spielarten-bedienpflicht",
            frontTitle: "Bedienpflicht",
            frontTiles: [.h(14), .h(7), .c(13)],
            frontSubtitle: "Die angespielte Farbe muss folgen",
            backTitle: "Erst Farbe, dann frei",
            backBody: "Wer eine Karte der angespielten Farbe hält, muss diese Farbe spielen. Wer sie nicht hat, darf eine andere Farbe oder einen Trumpf legen."
        ),
        Flashcard(
            id: "spielarten-stich",
            frontTitle: "Wer gewinnt den Stich?",
            frontTiles: [.c(11), .h(14), .h(10)],
            frontSubtitle: "Trumpf vor Farbe",
            backTitle: "Der höchste gültige Rang",
            backBody: "Ein Trumpf gewinnt gegen jede Karte einer Seitenfarbe. Gibt es keinen Trumpf, gewinnt die höchste Karte der angespielten Farbe."
        ),
        Flashcard(
            id: "spielarten-augen",
            frontTitle: "Die Augen",
            frontTiles: [.h(14), .h(13), .h(12), .h(11), .h(10)],
            frontSubtitle: "Was zählt im Stich?",
            backTitle: "Jeder Stich wird gezählt",
            backBody: "Nach dem Spiel zählen die Parteien die Augen ihrer Stiche. Ass und Zehn bringen zusammen bereits 21 Augen, Bube, Dame und König weitere 9."
        ),
        Flashcard(
            id: "spielarten-spielwert",
            frontTitle: "Spielwert",
            frontSubtitle: "Nicht mit Augen verwechseln",
            backTitle: "Grundwert mal Spitzen",
            backBody: "Der Spielwert ist der Wert der Ansage. Er entsteht aus dem Grundwert der Spielart und dem Multiplikator aus Spitzen und Gewinnstufe. Augen entscheiden dagegen, wer das Spiel gewinnt."
        ),
        Flashcard(
            id: "spielarten-endspiel",
            frontTitle: "Das Endspiel",
            frontSubtitle: "Die letzten Stiche planen",
            backTitle: "Sichere Augen sichern",
            backBody: "Wenn nur noch wenige Karten liegen, zählt die Reihenfolge. Ein sicheres Ass oder ein verbleibender Trumpf kann wichtiger sein als eine riskante lange Farbe."
        ),
    ]

    static let handMatch: [HandMatchQuestion] = [
        HandMatchQuestion(
            id: "struktur-hand-1",
            tiles: [.c(11), .s(11), .h(7), .h(10), .h(14)],
            choices: [.trumpf, .grand, .nullspiel],
            answer: .trumpf,
            explanation: "Zwei Buben und drei Karten einer Farbe zeigen eine starke Trumpfstruktur. Ob daraus ein Farbspiel wird, hängt zusätzlich vom Reizen ab."
        ),
        HandMatchQuestion(
            id: "struktur-hand-2",
            tiles: [.c(11), .s(11), .h(11), .d(11), .c(8)],
            choices: [.grand, .trumpf, .nullspiel],
            answer: .grand,
            explanation: "Alle vier Buben liegen im Muster. Das ist die zentrale Trumpfstruktur des Grand."
        ),
        HandMatchQuestion(
            id: "struktur-hand-3",
            tiles: [.c(7), .d(8), .h(9), .s(10), .c(8)],
            choices: [.nullspiel, .grand, .trumpf],
            answer: .nullspiel,
            explanation: "Die Karten sind niedrig und enthalten keinen Buben. Für ein Nullmuster gibt es keinen Trumpf und keine Augen."
        ),
        HandMatchQuestion(
            id: "struktur-hand-4",
            tiles: [.c(7), .c(8), .c(9), .c(10), .c(14)],
            choices: [.farbe, .grand, .nullspiel],
            answer: .farbe,
            explanation: "Fünf Karten derselben Farbe bilden eine klare Farbstruktur. Im Farbspiel wird diese Farbe zum Trumpf."
        ),
        HandMatchQuestion(
            id: "struktur-hand-5",
            tiles: [.c(14), .d(14), .h(13), .s(12), .c(10)],
            choices: [.stich, .nullspiel, .grand],
            answer: .stich,
            explanation: "Zwei Asse und hohe Beikarten versprechen mögliche sichere Stiche. Ohne Buben ist das noch kein Grand."
        ),
        HandMatchQuestion(
            id: "struktur-hand-6",
            tiles: [.c(11), .s(11), .h(14), .d(14), .c(10)],
            choices: [.reizen, .spielwert, .nullspiel],
            answer: .reizen,
            explanation: "Zwei Buben und zwei Asse sind ein Reizsignal. Beim Reizen musst du daraus aber noch einen tragbaren Spielwert ableiten."
        ),
        HandMatchQuestion(
            id: "struktur-hand-7",
            tiles: [.h(7), .h(8), .h(9), .d(11), .s(11)],
            choices: [.trumpf, .stich, .farbe],
            answer: .trumpf,
            explanation: "Die beiden Buben und die Herzserie geben einem möglichen Herzspiel mehrere Trumpfkarten und eine klare Beikartenidee."
        ),
        HandMatchQuestion(
            id: "struktur-hand-8",
            tiles: [.c(14), .c(13), .s(14), .h(10), .d(9)],
            choices: [.stich, .nullspiel, .grand],
            answer: .stich,
            explanation: "Asse und ein König liefern mögliche Augenstiche. Für Null sind die hohen Augen und das Ass keine ruhige Struktur."
        ),
    ]
}
