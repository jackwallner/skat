import Foundation

/// Grundlagen für den ersten Skat-Tisch.
enum CardBasicsContent {
    static let meetTheCards: [Flashcard] = [
        Flashcard(
            id: "karten-deck",
            frontTitle: "Das Skatblatt",
            frontSubtitle: "32 Karten, drei Spieler",
            backTitle: "Jeder bekommt zehn Karten",
            backBody: "Skat wird mit 32 Karten gespielt: 7, 8, 9, 10, Bube, Dame, König und Ass in vier Farben. Drei Spieler erhalten je zehn Karten, zwei Karten bilden den Skat."
        ),
        Flashcard(
            id: "karten-farben",
            frontTitle: "Die vier Farben",
            frontTiles: [.c(10), .s(10), .h(10), .d(10)],
            frontSubtitle: "Kreuz, Pik, Herz und Karo",
            backTitle: "Die Farbe entscheidet über Trumpf",
            backBody: "Im Farbspiel wird eine Farbe angesagt. Die vier Buben sind immer Trumpf, dazu kommen alle Karten der angesagten Farbe."
        ),
        Flashcard(
            id: "karten-augen",
            frontTitle: "Augen zählen",
            frontTiles: [.c(14), .s(13), .h(12), .d(11), .c(10)],
            frontSubtitle: "Ass bis 7",
            backTitle: "11, 4, 3, 2, 10, 0",
            backBody: "Ein Ass zählt 11 Augen, ein König 4, eine Dame 3, ein Bube 2 und eine Zehn 10. Neun, Acht und Sieben zählen keine Augen. Insgesamt liegen 120 Augen im Blatt."
        ),
        Flashcard(
            id: "karten-buben",
            frontTitle: "Die Buben",
            frontTiles: [.c(11), .s(11), .h(11), .d(11)],
            frontSubtitle: "Die höchsten Trümpfe",
            backTitle: "Kreuz-Bube ist der höchste",
            backBody: "Im Farbspiel und im Grand sind alle Buben Trumpf. Ihre Reihenfolge lautet Kreuz, Pik, Herz, Karo."
        ),
        Flashcard(
            id: "karten-geben",
            frontTitle: "Das Geben",
            frontSubtitle: "Drei Karten, Skat, vier Karten",
            backTitle: "3, 2, 4, 3",
            backBody: "Das übliche Geben läuft in Blöcken: drei Karten an jeden, zwei Karten in die Mitte, vier Karten an jeden und danach noch drei Karten an jeden."
        ),
        Flashcard(
            id: "karten-reizen",
            frontTitle: "Das Reizen",
            frontSubtitle: "Wer übernimmt das Spiel?",
            backTitle: "Die höchste Ansage gewinnt",
            backBody: "Beim Reizen wird festgelegt, wer spielt. Der Alleinspieler nimmt den Skat auf, legt zwei Karten wieder ab und sagt danach die Spielart an."
        ),
        Flashcard(
            id: "karten-gewinnen",
            frontTitle: "Das Ziel",
            frontSubtitle: "61 Augen oder keinen Stich",
            backTitle: "Farbspiel und Grand",
            backBody: "Im Farbspiel und Grand braucht der Alleinspieler mindestens 61 Augen. Im Nullspiel gewinnt er, wenn er keinen einzigen Stich macht."
        ),
        Flashcard(
            id: "karten-skat",
            frontTitle: "Der Skat",
            frontTiles: [.h(7), .d(14)],
            frontSubtitle: "Zwei Karten in der Mitte",
            backTitle: "Aufnehmen, dann drücken",
            backBody: "Der Alleinspieler nimmt die zwei Skatkarten auf und hat dadurch zwölf Karten. Danach legt er zwei Karten verdeckt zurück, bevor das Spiel beginnt."
        ),
    ]

    static let cardQuiz: [QuizQuestion] = [
        QuizQuestion(
            id: "karten-quiz-1",
            prompt: "Wie viele Karten hat ein Skatblatt?",
            choices: ["24", "32", "52"],
            answerIndex: 1,
            explanation: "Skat wird mit 32 Karten gespielt: acht Kartenwerte in vier Farben."
        ),
        QuizQuestion(
            id: "karten-quiz-2",
            prompt: "Wie viele Karten bekommt jeder Spieler?",
            choices: ["8", "10", "12"],
            answerIndex: 1,
            explanation: "Jeder der drei Spieler erhält zehn Karten. Zwei Karten bleiben als Skat liegen."
        ),
        QuizQuestion(
            id: "karten-quiz-3",
            prompt: "Wie viele Augen zählt ein Ass im Farbspiel?",
            tiles: [.h(14)],
            choices: ["4", "10", "11"],
            answerIndex: 2,
            explanation: "Das Ass ist mit elf Augen die wertvollste Karte beim Zählen."
        ),
        QuizQuestion(
            id: "karten-quiz-4",
            prompt: "Welcher Bube ist der höchste Trumpf?",
            tiles: [.c(11), .s(11), .h(11), .d(11)],
            choices: ["Kreuz-Bube", "Herz-Bube", "Karo-Bube"],
            answerIndex: 0,
            explanation: "Die Buben rangieren im Farbspiel und Grand von Kreuz über Pik und Herz bis Karo."
        ),
        QuizQuestion(
            id: "karten-quiz-5",
            prompt: "Was passiert nach dem Aufnehmen des Skats?",
            choices: ["Zwei Karten werden gedrückt", "Alle Karten werden neu gegeben", "Der Gegenspieler bestimmt die Farbe"],
            answerIndex: 0,
            explanation: "Der Alleinspieler legt nach dem Aufnehmen zwei Karten verdeckt zurück. Das nennt man Drücken."
        ),
        QuizQuestion(
            id: "karten-quiz-6",
            prompt: "Wie viele Augen liegen insgesamt im Skatblatt?",
            choices: ["100", "120", "132"],
            answerIndex: 1,
            explanation: "Die Kartenwerte ergeben zusammen 120 Augen. Im Farbspiel und Grand teilen sich diese Augen auf die Stiche auf."
        ),
        QuizQuestion(
            id: "karten-quiz-7",
            prompt: "Wer nimmt den Skat auf?",
            choices: ["Der Spieler mit der höchsten Ansage", "Immer Vorhand", "Der Spieler links vom Geber"],
            answerIndex: 0,
            explanation: "Der Spieler, der das Reizen gewinnt, wird Alleinspieler und nimmt den Skat auf."
        ),
        QuizQuestion(
            id: "karten-quiz-8",
            prompt: "Was muss der Alleinspieler im Null erreichen?",
            choices: ["Mindestens 61 Augen", "Mindestens fünf Stiche", "Keinen Stich"],
            answerIndex: 2,
            explanation: "Im Null gibt es keine Augenwertung. Der Alleinspieler gewinnt nur, wenn er keinen Stich erhält."
        ),
    ]
}
