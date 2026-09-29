import Foundation

/// Drücken ist eine Entscheidung nach dem Aufnehmen des Skats. Die Beispiele
/// nennen die angenommene Spielidee, weil es keine isoliert beste Karte gibt.
enum DiscardContent {
    static let strategyCards: [Flashcard] = [
        Flashcard(
            id: "druecken-aufnehmen",
            frontTitle: "Skat aufnehmen",
            frontSubtitle: "Aus zehn werden zwölf Karten",
            backTitle: "Erst aufnehmen, dann entscheiden",
            backBody: "Nach dem Reizen nimmt der Alleinspieler die zwei Skatkarten auf. Erst mit zwölf Karten kannst du entscheiden, welche zehn Karten deine Spielidee tragen."
        ),
        Flashcard(
            id: "druecken-zwei",
            frontTitle: "Zwei Karten drücken",
            frontTiles: [.c(7), .d(8)],
            frontSubtitle: "Der Skat muss verdeckt liegen",
            backTitle: "Genau zwei Karten",
            backBody: "Vor dem Ausspielen legst du genau zwei Karten verdeckt zurück. Sie gehören danach nicht mehr zur Hand. Bei Farbe und Grand zählen ihre Augen trotzdem für den Alleinspieler, auch bei einem Handspiel zählt der unberührte Skat."
        ),
        Flashcard(
            id: "druecken-farbe",
            frontTitle: "Farbspiel vorbereiten",
            frontSubtitle: "Trumpf und Beikarten zusammenhalten",
            backTitle: "Eine Farbe braucht Länge",
            backBody: "Bei einem Farbspiel sind die Buben und die angesagte Farbe Trumpf. Beim Drücken hältst du deshalb oft die wertvolle Länge und gibst lose Nebenfarben ab."
        ),
        Flashcard(
            id: "druecken-grand",
            frontTitle: "Grand vorbereiten",
            frontTiles: [.c(11), .s(11), .h(14), .d(14)],
            frontSubtitle: "Buben als Trumpfkern",
            backTitle: "Die Buben sind knapp",
            backBody: "Im Grand gibt es nur vier Trümpfe. Buben und sichere Augen sollten zusammen betrachtet werden, bevor du eine scheinbar kleine Karte drückst."
        ),
        Flashcard(
            id: "druecken-null",
            frontTitle: "Null vorbereiten",
            frontSubtitle: "Keine Augen, keine Trümpfe",
            backTitle: "Hohe Karten werden gefährlich",
            backBody: "Im Null willst du keinen Stich. Niedrige Karten und lange Farben helfen, während Asse, Könige und Zehnen oft die gefährlichen Karten sind."
        ),
        Flashcard(
            id: "druecken-kontext",
            frontTitle: "Der Kontext zählt",
            frontSubtitle: "Nicht jede Entscheidung ist gleich",
            backTitle: "Lehrentscheidung statt Automatismus",
            backBody: "Spielart, Reizwert, Position und bekannte Karten verändern das Drücken. Die Übungen nennen ihren Kontext, damit du ein Prinzip und keine starre Liste lernst."
        ),
    ]

    static let scenarios: [DiscardScenario] = [
        DiscardScenario(
            id: "druecken-deal-1",
            situation: "Herzspiel. Lehrziel: Nach dem Drücken pikfrei sein und alle Trümpfe behalten. Welche zwei Pik-Seitenkarten müssen weg?",
            deal: [.c(14), .d(14), .h(11), .h(14), .h(10), .h(7), .c(12), .s(13), .d(10), .c(7), .s(8), .d(9)],
            recommendedDiscard: [.s(13), .s(8)],
            reasoning: "Pik-König und Pik-Acht sind die einzigen Pik-Seitenkarten. Beide zusammen schaffen Pikfreiheit und sichern vier Skataugen. Die Herztrümpfe und beide Asse bleiben.",
            tip: "Halte die Trumpffarbe und sichere Augen zusammen. Eine einzelne kleine Nebenfarbe ist oft der erste Kandidat für den Skat."
        ),
        DiscardScenario(
            id: "druecken-deal-2",
            situation: "Grand. Lehrziel: Herzfreiheit herstellen, alle Buben und beide Ass-Zehn-Paare behalten. Welche zwei Karten drückst du?",
            deal: [.c(11), .s(11), .h(11), .d(11), .c(14), .d(14), .h(13), .s(12), .c(10), .d(10), .h(7), .d(7)],
            recommendedDiscard: [.h(13), .h(7)],
            reasoning: "Herz-König und Herz-Sieben sind die einzigen Herz-Seitenkarten. Der Herz-Bube bleibt Trumpf. Beide Ass-Zehn-Paare bleiben zusammen, vier Augen gehen in den Skat.",
            tip: "Im Grand ist jeder Bube ein Trumpf. Zähle danach die Augen, die du mit deinen sicheren Stichen erreichen kannst."
        ),
        DiscardScenario(
            id: "druecken-deal-3",
            situation: "Nullspiel. Lehrziel: Die zwei höchsten Karten nach der Null-Reihenfolge drücken. Welche sind das in diesem Blatt?",
            deal: [.c(7), .d(8), .h(9), .s(10), .c(8), .d(9), .h(7), .s(8), .c(14), .d(13), .h(10), .s(12)],
            recommendedDiscard: [.c(14), .d(13)],
            reasoning: "Ass und König können im Null leicht einen Stich erzwingen. Die niedrigen Karten lassen sich eher abwerfen und halten deine Hand für die Nullidee ruhig.",
            tip: "Im Null zählt nicht die Summe der Augen. Frage stattdessen, welche Karte deinen Gegnern einen sicheren Stich schenken könnte."
        ),
        DiscardScenario(
            id: "druecken-deal-4",
            situation: "Herzspiel. Lehrziel: Alle sieben Trümpfe behalten und kreuzfrei werden. Welche beiden Kreuz-Seitenkarten drückst du?",
            deal: [.h(7), .h(8), .h(9), .h(10), .h(14), .c(11), .s(11), .d(12), .c(13), .d(13), .c(9), .s(9)],
            recommendedDiscard: [.c(13), .c(9)],
            reasoning: "Kreuz-König und Kreuz-Neun sind die einzigen Kreuz-Seitenkarten. Kreuz-Bube ist Herztrumpf und bleibt. Mit dem Paar erreichst du Kreuzfreiheit und sicherst vier Augen.",
            tip: "Eine lange Trumpffarbe macht die Auswahl leichter: behalte die Farbe und entsorge möglichst unverbundene Seitenkarten."
        ),
        DiscardScenario(
            id: "druecken-deal-5",
            situation: "Grand mit vier Buben. Lehrziel: Herzfreiheit herstellen und beide Asse behalten. Welches Drückpaar erreicht das?",
            deal: [.c(11), .s(11), .h(11), .d(11), .c(14), .d(14), .h(13), .s(12), .c(7), .d(7), .h(8), .s(8)],
            recommendedDiscard: [.h(13), .h(8)],
            reasoning: "Herz-König und Herz-Acht sind die einzigen Herz-Seitenkarten. Sie zu drücken sichert vier Augen und Herzfreiheit. Der Herz-Bube bleibt als Grandtrumpf.",
            tip: "Wenn dein Spiel schon einen starken Trumpfkern hat, drücke eher die Karten ohne Augen und ohne Anschluss."
        ),
        DiscardScenario(
            id: "druecken-deal-6",
            situation: "Karospiel. Lehrziel: Alle fünf Trümpfe behalten und herzfrei werden. Welche beiden Karten erfüllen das?",
            deal: [.d(10), .d(11), .d(12), .d(13), .d(14), .c(10), .s(10), .h(10), .c(8), .s(8), .h(8), .c(7)],
            recommendedDiscard: [.h(10), .h(8)],
            reasoning: "Herz-Zehn und Herz-Acht sind die einzigen Herzkarten. Ihr Drücken schafft Herzfreiheit und sichert zehn Augen. Alle fünf Karotrümpfe bleiben.",
            tip: "Bei einer langen Farbe musst du nicht jede Nebenfarbe behalten. Prüfe, welche Karte später am wenigsten einen Stich gewinnt."
        ),
    ]
}
