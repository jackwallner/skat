import Foundation

enum MoreContent {
    static let cardExtras: [QuizQuestion] = [
        QuizQuestion(
            id: "mehr-karten-1",
            prompt: "Wie viele Karten liegen im Skat?",
            choices: ["1", "2", "3"],
            answerIndex: 1,
            explanation: "Zwei Karten werden beim Geben verdeckt in die Mitte gelegt und bilden den Skat."
        ),
        QuizQuestion(
            id: "mehr-karten-2",
            prompt: "Welche Karte zählt im Farbspiel vier Augen?",
            tiles: [.c(13), .d(12), .h(11)],
            choices: ["König", "Dame", "Bube"],
            answerIndex: 0,
            explanation: "Der König zählt vier Augen. Die Dame zählt drei und der Bube zwei."
        ),
        QuizQuestion(
            id: "mehr-karten-3",
            prompt: "Welche Position spielt im ersten Stich aus?",
            choices: ["Vorhand", "Mittelhand", "Hinterhand"],
            answerIndex: 0,
            explanation: "Vorhand spielt den ersten Stich aus. Die Sitzordnung bleibt auch beim Reizen wichtig."
        ),
        QuizQuestion(
            id: "mehr-karten-4",
            prompt: "Wie viele Karten bleiben nach dem Drücken auf der Hand?",
            choices: ["8", "10", "12"],
            answerIndex: 1,
            explanation: "Nach dem Aufnehmen sind es zwölf Karten. Zwei werden gedrückt, zehn bleiben für das Spiel."
        ),
        QuizQuestion(
            id: "mehr-karten-5",
            prompt: "Was ist im Grand Trumpf?",
            tiles: [.c(11), .s(11), .h(11), .d(11)],
            choices: ["Nur die vier Buben", "Eine angesagte Farbe", "Keine Karte"],
            answerIndex: 0,
            explanation: "Im Grand sind ausschließlich die vier Buben Trumpf."
        ),
    ]

    static let handReading: [HandMatchQuestion] = [
        HandMatchQuestion(
            id: "mehr-struktur-1",
            tiles: [.c(11), .s(11), .h(7), .d(10), .h(14)],
            choices: [.trumpf, .grand, .nullspiel],
            answer: .trumpf,
            explanation: "Zwei Buben plus mehrere Herz-Karten geben einem möglichen Farbspiel eine erkennbare Trumpfidee."
        ),
        HandMatchQuestion(
            id: "mehr-struktur-2",
            tiles: [.c(7), .d(8), .h(9), .s(10), .d(7)],
            choices: [.nullspiel, .stich, .grand],
            answer: .nullspiel,
            explanation: "Das Muster ist niedrig und frei von Buben. Genau diese Ruhe suchst du im Nullspiel."
        ),
        HandMatchQuestion(
            id: "mehr-struktur-3",
            tiles: [.c(7), .c(9), .c(10), .c(13), .c(14)],
            choices: [.farbe, .nullspiel, .grand],
            answer: .farbe,
            explanation: "Die fünf Kreuz-Karten liefern die Länge für eine Farbidee. Im eigentlichen Farbspiel kommen die Kreuz-Trümpfe dazu."
        ),
        HandMatchQuestion(
            id: "mehr-struktur-4",
            tiles: [.c(14), .d(14), .h(10), .s(13), .c(12)],
            choices: [.stich, .nullspiel, .trumpf],
            answer: .stich,
            explanation: "Die beiden Asse und die hohen Seitenkarten sprechen für mögliche Augenstiche, nicht für ein ruhiges Null."
        ),
    ]

    static let discardExtras: [DiscardScenario] = [
        DiscardScenario(
            id: "mehr-druecken-1",
            situation: "Du spielst Grand und hast nach dem Skat zwölf Karten. Welche zwei niedrigen Karten sind die Lehrentscheidung?",
            deal: [.c(11), .s(11), .h(11), .d(11), .c(14), .d(14), .h(13), .s(13), .c(7), .d(7), .h(8), .s(8)],
            recommendedDiscard: [.h(8), .s(8)],
            reasoning: "Die Buben und die hohen Augen bilden den Kern. Die beiden Achter bringen keine Augen und werden als lose Beikarten gedrückt.",
            tip: "Im Grand sind kleine Karten nicht automatisch schlecht, aber lose kleine Karten ohne Stichplan sind oft die schwächsten."
        ),
        DiscardScenario(
            id: "mehr-druecken-2",
            situation: "Du planst ein Karo-Farbspiel. Welche zwei fremden Karten gibst du als erste Lehrentscheidung ab?",
            deal: [.d(7), .d(8), .d(9), .d(10), .d(14), .c(11), .s(11), .h(13), .c(14), .s(14), .h(7), .c(8)],
            recommendedDiscard: [.h(7), .c(8)],
            reasoning: "Die Karo-Serie bleibt vollständig. Zwei kleine Fremdfarben haben wenig Anschluss und nehmen Platz für Trumpf und Augen weg.",
            tip: "Sortiere nach Spielidee: Farbe und Trümpfe zuerst, dann sichere Augen, dann lose Nebenfarben."
        ),
        DiscardScenario(
            id: "mehr-druecken-3",
            situation: "Du versuchst Null. Welche zwei hohen Karten willst du nicht in deiner Zehnerhand behalten?",
            deal: [.c(7), .d(8), .h(9), .s(10), .c(8), .d(9), .h(10), .s(7), .c(14), .d(13), .h(12), .s(11)],
            recommendedDiscard: [.c(14), .d(13)],
            reasoning: "Ass und König sind im Null gefährliche Gewinnerkarten. Die niedrigen Karten erlauben eher, einen Stich abzugeben.",
            tip: "Buben sind im Null keine Trümpfe, bleiben aber eine hohe Karte. Prüfe jede hohe Karte auf ihren möglichen Zwangsstich."
        ),
        DiscardScenario(
            id: "mehr-druecken-4",
            situation: "Du hast einen Grand mit zwei Buben im Plan. Welche zwei Karten wirken als lose Augenarme?",
            deal: [.c(11), .s(11), .c(14), .d(14), .h(13), .s(13), .c(10), .d(10), .h(7), .s(8), .h(8), .d(9)],
            recommendedDiscard: [.h(7), .s(8)],
            reasoning: "Die kleinen Karten bringen keine Augen und haben keinen sichtbaren Anschluss. Der Trumpfkern und die Augen bleiben im Blatt.",
            tip: "Nicht nur Kartenpunkte zählen: Ein Drückpaar soll auch die erwartete Stichverteilung berücksichtigen."
        ),
    ]

    static let tableQuiz: [QuizQuestion] = [
        QuizQuestion(
            id: "mehr-stich-quiz-1",
            prompt: "Was gilt, wenn du die angespielte Farbe nicht hast?",
            choices: ["Du darfst frei wählen", "Du musst passen", "Du musst die höchste Karte spielen"],
            answerIndex: 0,
            explanation: "Ohne Karte der angespielten Farbe darfst du eine andere Farbe oder einen Trumpf spielen."
        ),
        QuizQuestion(
            id: "mehr-stich-quiz-2",
            prompt: "Was schlägt eine Karte der Seitenfarbe?",
            tiles: [.c(11), .h(14)],
            choices: ["Jeder Trumpf", "Nur ein Ass", "Nur eine Karte derselben Farbe"],
            answerIndex: 0,
            explanation: "Ein gültiger Trumpf gewinnt gegen jede Karte einer Seitenfarbe."
        ),
        QuizQuestion(
            id: "mehr-stich-quiz-3",
            prompt: "Was ist das Ziel des Alleinspielers im Null?",
            choices: ["61 Augen", "Keinen Stich", "Alle vier Buben"],
            answerIndex: 1,
            explanation: "Im Null gewinnt der Alleinspieler, wenn er keinen Stich erhält."
        ),
        QuizQuestion(
            id: "mehr-stich-quiz-4",
            prompt: "Wer spielt den nächsten Stich aus?",
            choices: ["Der Gewinner des letzten Stichs", "Immer Vorhand", "Der Spieler mit den meisten Augen"],
            answerIndex: 0,
            explanation: "Der Gewinner eines Stichs spielt den nächsten Stich aus."
        ),
        QuizQuestion(
            id: "mehr-stich-quiz-5",
            prompt: "Welche Karte ist im Null innerhalb einer Farbe am höchsten?",
            tiles: [.c(14), .c(13), .c(11)],
            choices: ["Ass", "Bube", "König"],
            answerIndex: 0,
            explanation: "Im Null gilt die normale Reihenfolge. Das Ass ist hoch und die Buben sind keine Trümpfe."
        ),
        QuizQuestion(
            id: "mehr-stich-quiz-6",
            prompt: "Wie viele Augen zählen Bube und Dame zusammen?",
            tiles: [.h(11), .h(12)],
            choices: ["3", "5", "7"],
            answerIndex: 1,
            explanation: "Der Bube zählt zwei und die Dame drei Augen. Zusammen sind das fünf."
        ),
        QuizQuestion(
            id: "mehr-stich-quiz-7",
            prompt: "Was muss im Farbspiel zuerst geprüft werden?",
            choices: ["Bedienpflicht", "Die eigene Punktzahl", "Ob der Skat offen liegt"],
            answerIndex: 0,
            explanation: "Die Bedienpflicht entscheidet, welche Karten überhaupt legal gespielt werden dürfen."
        ),
        QuizQuestion(
            id: "mehr-stich-quiz-8",
            prompt: "Was zeigt im Farbspiel die Trumpfhöhe?",
            tiles: [.c(11), .s(11), .h(11), .d(11)],
            choices: ["Die Bubenreihenfolge", "Die Anzahl der Augen", "Die Sitzposition allein"],
            answerIndex: 0,
            explanation: "Die Buben stehen im Farbspiel über der angesagten Farbe und haben eine feste Reihenfolge."
        ),
    ]

    static let judgment: [Flashcard] = [
        Flashcard(
            id: "mehr-entscheidung-1",
            frontTitle: "Kleine Farbe abwerfen",
            frontTiles: [.h(14), .c(11), .c(7)],
            frontSubtitle: "Du hast kein Herz",
            backTitle: "Frei wählen ist legal",
            backBody: "Wenn Herz angespielt ist und du kein Herz hältst, darfst du eine andere Farbe oder Trumpf spielen. Eine kleine Seitenkarte kann die richtige Schonung sein.",
            choice: CardChoice("Frei wählen", "Herz muss folgen", answerIndex: 0)
        ),
        Flashcard(
            id: "mehr-entscheidung-2",
            frontTitle: "Sicheres Ass",
            frontTiles: [.h(14), .h(7)],
            frontSubtitle: "Herz ist angespielt",
            backTitle: "Ass gewinnt ohne Trumpf",
            backBody: "Wenn kein Trumpf im Stich liegt und Herz bedient werden muss, gewinnt das Herz-Ass diesen Stich.",
            choice: CardChoice("Ass gewinnt", "Die Sieben gewinnt", answerIndex: 0)
        ),
        Flashcard(
            id: "mehr-entscheidung-3",
            frontTitle: "Null und Bube",
            frontTiles: [.c(11), .c(7)],
            frontSubtitle: "Kreuz ist angespielt",
            backTitle: "Der Bube ist keine Sonderkarte",
            backBody: "Im Null ist der Bube kein Trumpf. Er ist eine hohe Karte der Farbe, während das Ass noch höher liegt.",
            choice: CardChoice("Bube ist kein Trumpf", "Bube gewinnt immer", answerIndex: 0)
        ),
        Flashcard(
            id: "mehr-entscheidung-4",
            frontTitle: "Stich auswerten",
            frontTiles: [.c(14), .d(14), .c(10)],
            frontSubtitle: "Trumpf liegt im Stich",
            backTitle: "Trumpf schlägt Seitenfarbe",
            backBody: "Auch ein kleiner Trumpf gewinnt gegen ein Ass einer Seitenfarbe. Erst der Trumpfrang, dann die Augen zählen.",
            choice: CardChoice("Trumpf gewinnt", "Ass gewinnt immer", answerIndex: 0)
        ),
    ]

    static let advancedRules: [QuizQuestion] = [
        QuizQuestion(
            id: "mehr-regel-1",
            prompt: "Was ist der Grundwert eines Grand?",
            choices: ["9", "24", "35"],
            answerIndex: 1,
            explanation: "Der Grundwert des Grand beträgt 24. Der tatsächliche Spielwert wird mit dem passenden Multiplikator berechnet."
        ),
        QuizQuestion(
            id: "mehr-regel-2",
            prompt: "Was ist der Grundwert eines Nullspiels?",
            choices: ["12", "23", "30"],
            answerIndex: 1,
            explanation: "Ein einfaches Nullspiel hat den festen Spielwert 23. Null Hand und Null ouvert haben eigene Werte."
        ),
        QuizQuestion(
            id: "mehr-regel-3",
            prompt: "Was bedeutet Schneider im Farbspiel oder Grand?",
            choices: ["Eine Gewinnstufe mit höchstens 30 Augen für die Gegner", "Ein Spiel ohne Trumpf", "Ein Spiel mit offenem Skat"],
            answerIndex: 0,
            explanation: "Schneider bedeutet, dass die Gegenspieler höchstens 30 Augen erreichen. Das verändert die Gewinnstufe und damit den Spielwert."
        ),
        QuizQuestion(
            id: "mehr-regel-4",
            prompt: "Was ist bei einem Handspiel anders?",
            choices: ["Der Skat wird nicht aufgenommen", "Es gibt keine Trümpfe", "Es spielen nur zwei Personen"],
            answerIndex: 0,
            explanation: "Beim Handspiel bleibt der Skat liegen. Der Alleinspieler drückt zwei Karten, ohne die beiden Karten vorher zu sehen."
        ),
        QuizQuestion(
            id: "mehr-regel-5",
            prompt: "Was bedeutet Null ouvert?",
            choices: ["Der Alleinspieler zeigt seine Karten und darf keinen Stich machen", "Der Skat wird offen gezeigt", "Alle Buben sind Trumpf"],
            answerIndex: 0,
            explanation: "Bei Null ouvert liegen die Karten des Alleinspielers offen, und er muss weiterhin stichlos bleiben."
        ),
        QuizQuestion(
            id: "mehr-regel-6",
            prompt: "Was zählt für die Gewinnbedingung im Grand?",
            choices: ["Augen in den eigenen Stichen", "Der Spielwert allein", "Nur die Anzahl der Trümpfe"],
            answerIndex: 0,
            explanation: "Der Spielwert beschreibt die Ansage. Gewonnen wird der Grand mit mindestens 61 Augen in den eigenen Stichen."
        ),
    ]
}
