import Foundation

/// Der Meistertisch: anspruchsvollere, aber weiterhin originale Lehrsituationen.
enum ProContent {
    static let advancedDiscard: [DiscardScenario] = [
        DiscardScenario(
            id: "meister-druecken-1",
            situation: "Du hast vier Buben, zwei Asse und willst Grand spielen. Welche zwei Karten drückst du als Lehrentscheidung?",
            deal: [.c(11), .s(11), .h(11), .d(11), .c(14), .d(14), .h(13), .s(13), .c(10), .d(10), .h(7), .s(8)],
            recommendedDiscard: [.h(7), .s(8)],
            reasoning: "Der Trumpfkern ist vollständig. Die kleinen Seitenkarten liefern keine Augen und haben keinen sichtbaren Anschluss, während die hohen Karten die 61-Augen-Linie stützen.",
            tip: "Am Meistertisch zählt die Kombination aus Trumpfkontrolle und Augenplan. Frage nicht nur, was du drückst, sondern welche Stiche danach sicher sind."
        ),
        DiscardScenario(
            id: "meister-druecken-2",
            situation: "Du planst ein Karo-Farbspiel mit langer Farbe. Welche zwei Karten hältst du für die schwächsten Seitenkarten?",
            deal: [.d(7), .d(8), .d(9), .d(10), .d(14), .c(11), .s(11), .h(13), .c(14), .s(14), .h(7), .c(8)],
            recommendedDiscard: [.h(7), .c(8)],
            reasoning: "Die Karo-Karten bilden eine geschlossene Farbe. Herz-Sieben und Kreuz-Acht sind kleine Einzelkarten ohne Augen und ohne erkennbaren Stichanschluss.",
            tip: "Eine lange Trumpffarbe kann die Gegner unter Druck setzen. Bewahre trotzdem die Augen und die Buben, die deine sichere Seite bilden."
        ),
        DiscardScenario(
            id: "meister-druecken-3",
            situation: "Du möchtest Null ouvert versuchen. Welche zwei hohen Karten dürfen nicht in der Hand bleiben?",
            deal: [.c(7), .d(8), .h(9), .s(10), .c(8), .d(9), .h(10), .s(7), .c(14), .d(13), .h(12), .s(11)],
            recommendedDiscard: [.c(14), .d(13)],
            reasoning: "Bei Null ouvert ist jede hohe Karte sichtbar und für die Gegner planbar. Ass und König sind gefährliche Gewinner und werden zuerst abgelegt.",
            tip: "Offene Karten machen die Kontrolle schwerer. Niedrige Karten und lange Farben sind wichtiger als Augen."
        ),
        DiscardScenario(
            id: "meister-druecken-4",
            situation: "Der Spielwert ist knapp. Du hast zwei Buben und mehrere Augen, aber nur eine kurze Trumpffarbe. Welche zwei Karten gibst du ab?",
            deal: [.c(11), .s(11), .h(14), .d(14), .h(10), .h(7), .c(13), .s(13), .c(10), .d(10), .c(8), .s(8)],
            recommendedDiscard: [.c(8), .s(8)],
            reasoning: "Die kleinen Seitenkarten sichern keinen eigenen Stich und helfen beim Augenplan wenig. Buben, Asse und Zehnen bleiben als mögliche Gewinnstiche.",
            tip: "Ein knappes Spiel braucht einen konkreten Stichplan. Prüfe, ob die gedrückten Karten später wirklich keinen notwendigen Übergang liefern."
        ),
    ]

    static let defenseQuiz: [QuizQuestion] = [
        QuizQuestion(
            id: "meister-verteidigung-1",
            prompt: "Was ist als Gegenspieler die erste Pflicht?",
            choices: ["Die angespielte Farbe bedienen", "Sofort Trumpf spielen", "Die höchste Karte werfen"],
            answerIndex: 0,
            explanation: "Auch als Gegenspieler gilt die Bedienpflicht. Erst wenn die Farbe fehlt, kommt eine freie Entscheidung."
        ),
        QuizQuestion(
            id: "meister-verteidigung-2",
            prompt: "Wann ist ein Trumpf als Gegenspieler besonders wertvoll?",
            choices: ["Wenn er einen wichtigen Augenstich übernimmt", "Wenn er immer der höchste ist", "Wenn keine Karte im Stich liegt"],
            answerIndex: 0,
            explanation: "Ein Trumpf sollte einen wichtigen Stich sichern oder die Spielidee des Alleinspielers stören. Blindes Trumpfen verschenkt oft Kontrolle."
        ),
        QuizQuestion(
            id: "meister-verteidigung-3",
            prompt: "Was beobachtest du neben den Augen?",
            choices: ["Welche Farben und Trümpfe noch frei sind", "Nur die Reihenfolge der Spieler", "Nur den Spielwert"],
            answerIndex: 0,
            explanation: "Restkarten und bereits gefallene Trümpfe helfen, die nächsten Stiche zu planen."
        ),
        QuizQuestion(
            id: "meister-verteidigung-4",
            prompt: "Was bedeutet es, wenn der Alleinspieler eine Farbe nicht bedienen kann?",
            choices: ["Er darf eine andere Karte wählen", "Er verliert sofort", "Er muss den Stich abgeben"],
            answerIndex: 0,
            explanation: "Wenn die angespielte Farbe fehlt, darf der Spieler eine andere Farbe oder einen Trumpf spielen."
        ),
        QuizQuestion(
            id: "meister-verteidigung-5",
            prompt: "Wie viele Augen braucht der Alleinspieler im Farbspiel zum Sieg?",
            choices: ["60", "61", "90"],
            answerIndex: 1,
            explanation: "61 Augen gewinnen das Farbspiel oder den Grand. Die Gegenspieler gewinnen mit mindestens 60 Augen."
        ),
        QuizQuestion(
            id: "meister-verteidigung-6",
            prompt: "Was ist im Null ein guter Verteidigungsplan?",
            choices: ["Hohe Karten in den Stich bringen", "Eigene Augen sammeln", "Alle Buben als Trumpf behandeln"],
            answerIndex: 0,
            explanation: "Im Null will der Alleinspieler keinen Stich. Die Gegenspieler versuchen daher, hohe Karten des Alleinspielers zum Stichgewinn zu zwingen."
        ),
    ]

    static let expertHandReading: [HandMatchQuestion] = [
        HandMatchQuestion(
            id: "meister-struktur-1",
            tiles: [.c(11), .s(11), .h(11), .d(11), .c(14)],
            choices: [.grand, .trumpf, .spielwert],
            answer: .grand,
            explanation: "Vier Buben sind die maximale Trumpfkontrolle im Grand. Der konkrete Spielwert hängt zusätzlich von den Spitzen und der Gewinnstufe ab."
        ),
        HandMatchQuestion(
            id: "meister-struktur-2",
            tiles: [.d(7), .d(8), .d(9), .d(10), .d(14)],
            choices: [.farbe, .nullspiel, .stich],
            answer: .farbe,
            explanation: "Die geschlossene Karo-Farbe gibt viele mögliche Trumpfstiche. Der Spielwert selbst ist aus dem Muster allein noch nicht vollständig ablesbar."
        ),
        HandMatchQuestion(
            id: "meister-struktur-3",
            tiles: [.c(7), .d(8), .h(9), .s(10), .c(9)],
            choices: [.nullspiel, .grand, .endspiel],
            answer: .nullspiel,
            explanation: "Niedrige Karten ohne Buben und ohne hohe Augen sind eine ruhige Nullstruktur. Die doppelte Neun ist kein Trumpfproblem."
        ),
        HandMatchQuestion(
            id: "meister-struktur-4",
            tiles: [.c(14), .d(14), .h(13), .s(13), .c(10)],
            choices: [.stich, .spielwert, .nullspiel],
            answer: .stich,
            explanation: "Zwei Asse und zwei Könige versprechen Augen, wenn du ihre Stiche sichern kannst. Das ist eine Stichidee, noch keine vollständige Spielwertrechnung."
        ),
        HandMatchQuestion(
            id: "meister-struktur-5",
            tiles: [.c(11), .s(11), .h(14), .h(10), .h(7)],
            choices: [.trumpf, .reizen, .nullspiel],
            answer: .trumpf,
            explanation: "Zwei Buben und eine lange Herzfarbe bilden die Trumpfseite. Beim Reizen prüfst du danach, ob die gewünschte Ansage tragbar ist."
        ),
        HandMatchQuestion(
            id: "meister-struktur-6",
            tiles: [.c(14), .s(14), .h(12), .d(13), .c(10)],
            choices: [.stich, .endspiel, .nullspiel],
            answer: .stich,
            explanation: "Hohe Karten und zwei Asse können im Endspiel wertvoll sein, aber zuerst erkennst du die mögliche Augenstich-Struktur."
        ),
    ]
}
