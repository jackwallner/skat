import Foundation

struct HowToPlayPage: Identifiable, Sendable {
    let id: String
    let icon: String
    let title: String
    let body: String
    let tiles: [PlayingCard]
    let tip: String?

    init(id: String, icon: String, title: String, body: String, tiles: [PlayingCard] = [], tip: String? = nil) {
        self.id = id
        self.icon = icon
        self.title = title
        self.body = body
        self.tiles = tiles
        self.tip = tip
    }
}

enum HowToPlayContent {
    static let pages: [HowToPlayPage] = [
        HowToPlayPage(
            id: "primer-ziel",
            icon: "person.3.fill",
            title: "Drei Spieler, ein Alleinspieler",
            body: "Skat ist ein Stichspiel für drei Personen. Nach dem Reizen spielt eine Person allein gegen die beiden anderen.",
            tiles: [.c(14), .s(13), .h(11)],
            tip: "Der Alleinspieler gewinnt im Farbspiel und Grand mit mindestens 61 Augen."
        ),
        HowToPlayPage(
            id: "primer-karten",
            icon: "rectangle.portrait.on.rectangle.portrait.angled",
            title: "Das 32-Karten-Blatt",
            body: "Es gibt vier Farben mit den Werten 7, 8, 9, 10, Bube, Dame, König und Ass. Jede Karte hat ihren Rang und ihren Augenwert.",
            tiles: [.c(7), .d(10), .h(11), .s(14)],
            tip: "Ass und Zehn bringen zusammen 21 Augen."
        ),
        HowToPlayPage(
            id: "primer-reizen",
            icon: "arrow.up.right.circle.fill",
            title: "Reizen und Spiel ansagen",
            body: "Die Spieler reizen mit möglichen Spielwerten. Wer die höchste Ansage hält, übernimmt das Spiel, nimmt den Skat auf und sagt die Spielart an.",
            tiles: [.c(11), .s(11), .h(14)],
            tip: "Reize nur so hoch, wie dein Blatt und dein Plan es tragen."
        ),
        HowToPlayPage(
            id: "primer-skat",
            icon: "arrow.down.to.line.compact",
            title: "Skat aufnehmen und drücken",
            body: "Der Alleinspieler nimmt zwei Karten auf und hat zwölf Karten. Danach legt er genau zwei Karten verdeckt zurück und spielt mit zehn Karten weiter.",
            tiles: [.h(7), .d(8), .c(14), .s(11)],
            tip: "Entscheide erst nach dem Aufnehmen, welche Spielart wirklich passt."
        ),
        HowToPlayPage(
            id: "primer-stich",
            icon: "suit.club.fill",
            title: "Bedienen und Stiche holen",
            body: "Die angespielte Farbe muss bedient werden. Wer sie nicht hat, darf eine andere Farbe oder einen Trumpf spielen. Der höchste gültige Trumpf gewinnt.",
            tiles: [.h(14), .h(7), .c(11)],
            tip: "Im Null gibt es keinen Trumpf und das Ass ist hoch."
        ),
        HowToPlayPage(
            id: "primer-start",
            icon: "rectangle.stack.fill",
            title: "Jetzt üben",
            body: "Starte mit den Karten-Grundlagen oder spring direkt in die empfohlenen fünfminütigen Übungen. Jede Antwort erklärt nicht nur was, sondern warum.",
            tiles: [.c(11), .h(10), .d(14)],
            tip: "Die Räume bleiben frei nutzbar. Skat+ ergänzt weitere Originalübungen."
        ),
    ]

    static func recommendedRoom(forSkillLevel skillLevel: String) -> Room {
        switch skillLevel {
        case "played": return DrillLibrary.room(id: "pegging-room") ?? DrillLibrary.rooms[0]
        case "basics": return DrillLibrary.room(id: "discard-room") ?? DrillLibrary.rooms[0]
        default: return DrillLibrary.room(id: "card-room") ?? DrillLibrary.rooms[0]
        }
    }
}
