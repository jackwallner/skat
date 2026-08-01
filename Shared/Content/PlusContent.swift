import Foundation

/// Zusätzliche Originalübungen für Skat+.
enum PlusContent {
    static let cardExtras: [QuizQuestion] = [
        QuizQuestion(
            id: "plus-karten-1",
            prompt: "Wie viele Augen zählt eine Zehn?",
            tiles: [.c(10)],
            choices: ["0", "10", "11"],
            answerIndex: 1,
            explanation: "Die Zehn zählt zehn Augen. Nur das Ass ist mit elf Augen noch wertvoller."
        ),
        QuizQuestion(
            id: "plus-karten-2",
            prompt: "Welche Karten sind in einem Farbspiel immer Trumpf?",
            choices: ["Die vier Buben", "Alle Asse", "Nur die Karten der angesagten Farbe"],
            answerIndex: 0,
            explanation: "Die vier Buben sind unabhängig von der angesagten Farbe Trumpf. Dazu kommt die komplette angesagte Farbe."
        ),
        QuizQuestion(
            id: "plus-karten-3",
            prompt: "Wie viele Karten legt der Alleinspieler in den Skat zurück?",
            choices: ["1", "2", "4"],
            answerIndex: 1,
            explanation: "Nach dem Aufnehmen legt der Alleinspieler genau zwei Karten verdeckt zurück."
        ),
        QuizQuestion(
            id: "plus-karten-4",
            prompt: "Welche Aussage zum Reizen stimmt?",
            choices: ["Die höchste tragbare Ansage übernimmt das Spiel", "Vorhand gewinnt immer", "Die Gegner sagen die Spielart an"],
            answerIndex: 0,
            explanation: "Der Spieler, der die höchste Ansage hält, wird Alleinspieler. Er sagt die Spielart selbst an."
        ),
    ]

    static let extraHandReading: [HandMatchQuestion] = [
        HandMatchQuestion(
            id: "plus-struktur-1",
            tiles: [.c(11), .s(11), .h(11), .d(8), .c(14)],
            choices: [.grand, .trumpf, .nullspiel],
            answer: .grand,
            explanation: "Drei Buben bilden im Muster den Kern eines Grand. Ein vierter Bube würde die Trumpfkontrolle noch verstärken."
        ),
        HandMatchQuestion(
            id: "plus-struktur-2",
            tiles: [.d(7), .d(8), .d(10), .d(13), .d(14)],
            choices: [.farbe, .nullspiel, .stich],
            answer: .farbe,
            explanation: "Fünf Karten in Karo geben eine lange Farbe. Die Farbe kann im passenden Farbspiel zur Trumpffarbe werden."
        ),
        HandMatchQuestion(
            id: "plus-struktur-3",
            tiles: [.c(7), .d(8), .h(9), .s(10), .h(8)],
            choices: [.nullspiel, .grand, .reizen],
            answer: .nullspiel,
            explanation: "Niedrige Karten ohne Buben halten das Muster für Null ruhig. Es gibt keinen offensichtlichen Zwangsstich."
        ),
        HandMatchQuestion(
            id: "plus-struktur-4",
            tiles: [.c(14), .s(14), .h(13), .d(12), .c(10)],
            choices: [.stich, .nullspiel, .grand],
            answer: .stich,
            explanation: "Die beiden Asse sind mögliche sichere Augenstiche. Ohne Buben ist die Struktur kein Grand."
        ),
    ]

    static let extraDiscards: [DiscardScenario] = [
        DiscardScenario(
            id: "plus-druecken-1",
            situation: "Du hast ein Herzspiel mit langer Farbe im Blick. Welche zwei Karten drückst du?",
            deal: [.h(7), .h(8), .h(9), .h(10), .h(14), .c(11), .s(11), .d(13), .c(7), .s(8), .d(9), .c(12)],
            recommendedDiscard: [.c(7), .s(8)],
            reasoning: "Die Herzserie bleibt als Trumpf- und Beikartenkern erhalten. Die kleinen, losen Fremdfarben bringen in dieser Idee am wenigsten.",
            tip: "Eine Farbe mit Länge kann die Entscheidung vereinfachen. Suche zuerst die Karten ohne Farbe, Augen oder Anschluss."
        ),
        DiscardScenario(
            id: "plus-druecken-2",
            situation: "Du reizt auf Grand. Welche beiden Karten sind ohne Augen und ohne sichtbare Verbindung?",
            deal: [.c(11), .s(11), .c(14), .d(14), .h(13), .s(13), .c(10), .d(10), .h(7), .d(7), .h(8), .s(8)],
            recommendedDiscard: [.h(7), .d(7)],
            reasoning: "Buben, Asse und Zehnen tragen die Grand-Idee. Die beiden Siebener liefern weder Augen noch einen erkennbaren sicheren Stich.",
            tip: "Die beste Lehrentscheidung ist nicht immer die Karte mit dem niedrigsten Wert, aber hier sind die beiden Siebener klar lose."
        ),
        DiscardScenario(
            id: "plus-druecken-3",
            situation: "Du nimmst den Skat für ein Nullspiel auf. Welche zwei hohen Karten willst du loswerden?",
            deal: [.c(7), .d(8), .h(9), .s(10), .c(8), .d(9), .h(10), .s(7), .c(14), .d(13), .h(12), .s(11)],
            recommendedDiscard: [.c(14), .d(13)],
            reasoning: "Ass und König können im Null schnell einen Stich gewinnen. Die niedrigen Karten lassen eher zu, einen Stich abzugeben.",
            tip: "Im Null sind Augen nicht das Ziel. Beurteile jede hohe Karte danach, ob sie dich zum Stichgewinn zwingt."
        ),
        DiscardScenario(
            id: "plus-druecken-4",
            situation: "Du hältst vier Buben und planst einen Grand. Welche zwei kleinen Seitenkarten legst du ab?",
            deal: [.c(11), .s(11), .h(11), .d(11), .c(14), .s(14), .h(13), .d(13), .c(7), .s(7), .h(8), .d(8)],
            recommendedDiscard: [.h(8), .d(8)],
            reasoning: "Der Vier-Buben-Kern und die hohen Augen bleiben erhalten. Die beiden Achter sind kleine Einzelkarten ohne Augen.",
            tip: "Bei vielen sicheren Trümpfen darfst du die Beikarten genauer auf Augen und Anschluss prüfen."
        ),
    ]

    static let extraJudgment: [Flashcard] = [
        Flashcard(
            id: "plus-entscheidung-1",
            frontTitle: "Farbe behalten",
            frontTiles: [.h(14), .h(7), .c(11)],
            frontSubtitle: "Herz ist die Spielidee",
            backTitle: "Trumpfstruktur vor Einzelkarte",
            backBody: "Die Herz-Karten gehören zur Trumpffarbe. Eine einzelne kleine Fremdfarbe ist dagegen nur dann wertvoll, wenn sie einen konkreten Stichplan hat.",
            choice: CardChoice("Herzstruktur halten", "Farbe sofort zerreißen", answerIndex: 0)
        ),
        Flashcard(
            id: "plus-entscheidung-2",
            frontTitle: "Kein Herz",
            frontTiles: [.h(14), .c(7)],
            frontSubtitle: "Herz ist angespielt",
            backTitle: "Kreuz darf gelegt werden",
            backBody: "Ohne Herzkarte darfst du eine andere Farbe spielen. Ob ein Trumpf besser ist, hängt von deinem Spielplan und der Stichlage ab.",
            choice: CardChoice("Andere Farbe ist erlaubt", "Herz muss trotzdem folgen", answerIndex: 0)
        ),
        Flashcard(
            id: "plus-entscheidung-3",
            frontTitle: "Grand-Trumpf",
            frontTiles: [.c(11), .c(14)],
            frontSubtitle: "Kreuz-Bube gegen Kreuz-Ass",
            backTitle: "Der Bube steht höher",
            backBody: "Im Grand gewinnt der Kreuz-Bube den Stich gegen das Kreuz-Ass, weil die vier Buben über allen anderen Karten stehen.",
            choice: CardChoice("Kreuz-Bube gewinnt", "Kreuz-Ass gewinnt", answerIndex: 0)
        ),
        Flashcard(
            id: "plus-entscheidung-4",
            frontTitle: "Null bleibt Null",
            frontTiles: [.s(11), .s(14)],
            frontSubtitle: "Pik ist angespielt",
            backTitle: "Ass ist höher als Bube",
            backBody: "Im Null gibt es keine Buben-Trümpfe. Innerhalb von Pik steht das Ass über dem Buben.",
            choice: CardChoice("Ass ist höher", "Bube ist höher", answerIndex: 0)
        ),
    ]
}
