import Foundation

/// Ein Nachschlage-Begriff. Kurz gehalten: Er wird am Tisch gelesen, mit dem
/// Blatt in der Hand, nicht gelernt.
struct GlossaryTerm: Identifiable, Sendable {
    let id: String
    let term: String
    /// Other words a player might search for. Never shown, only matched, so
    /// "Matador" finds Spitzen.
    let aliases: [String]
    let group: GlossaryGroup
    let definition: String

    init(id: String, term: String, aliases: [String] = [], group: GlossaryGroup, definition: String) {
        self.id = id
        self.term = term
        self.aliases = aliases
        self.group = group
        self.definition = definition
    }

    func matches(_ query: String) -> Bool {
        let needle = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !needle.isEmpty else { return true }
        if term.lowercased().contains(needle) { return true }
        if aliases.contains(where: { $0.lowercased().contains(needle) }) { return true }
        return definition.lowercased().contains(needle)
    }
}

enum GlossaryGroup: String, CaseIterable, Identifiable, Sendable {
    case cards
    case bidding
    case games
    case value
    case play

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cards: return "Karten und Augen"
        case .bidding: return "Reizen"
        case .games: return "Spielarten"
        case .value: return "Spielwert"
        case .play: return "Am Tisch"
        }
    }

    var icon: String {
        switch self {
        case .cards: return "rectangle.stack.fill"
        case .bidding: return "megaphone.fill"
        case .games: return "suit.club.fill"
        case .value: return "number"
        case .play: return "person.3.fill"
        }
    }
}

/// Das Glossar nach der Internationalen Skatordnung (DSkV, 2022). Die Texte
/// sind eigene Formulierungen. `ReferenceContentTests` prüft die genannten
/// Zahlen gegen `SkatRules`, nach denen auch die Übungen werten.
enum ReferenceContent {
    static func terms(in group: GlossaryGroup, matching query: String = "") -> [GlossaryTerm] {
        glossary.filter { $0.group == group && $0.matches(query) }
    }

    static let glossary: [GlossaryTerm] = [
        // MARK: Karten und Augen
        GlossaryTerm(
            id: "g-augen", term: "Augen", aliases: ["Kartenwert", "Punkte"], group: .cards,
            definition: "Der Zählwert der Karten: Ass 11, Zehn 10, König 4, Dame 3, Bube 2, Neun, Acht und Sieben nichts. Im ganzen Spiel stecken 120 Augen."
        ),
        GlossaryTerm(
            id: "g-buben", term: "Buben", aliases: ["Bube", "Unter", "Wenzel"], group: .cards,
            definition: "Die vier Buben sind in Farbspiel und Grand die höchsten Trümpfe, in der Reihenfolge Kreuz, Pik, Herz, Karo. Sie gehören dann nicht mehr zu ihrer Farbe."
        ),
        GlossaryTerm(
            id: "g-reihenfolge", term: "Kartenreihenfolge", aliases: ["Rangfolge", "Reihenfolge"], group: .cards,
            definition: "In Farbspiel und Grand gilt je Farbe: Ass, Zehn, König, Dame, Neun, Acht, Sieben. Im Null gilt die natürliche Folge Ass, König, Dame, Bube, Zehn, Neun, Acht, Sieben."
        ),
        GlossaryTerm(
            id: "g-trumpf", term: "Trumpf", aliases: ["Trümpfe", "stechen"], group: .cards,
            definition: "Im Farbspiel die vier Buben und alle Karten der angesagten Farbe, zusammen elf Karten. Im Grand nur die vier Buben. Im Null gibt es keinen Trumpf."
        ),
        GlossaryTerm(
            id: "g-skat", term: "Skat", aliases: ["Stock"], group: .cards,
            definition: "Die zwei verdeckten Karten in der Mitte. Ihre Augen zählen am Ende für den Alleinspieler, auch wenn er sie nicht aufgenommen hat."
        ),

        // MARK: Reizen
        GlossaryTerm(
            id: "g-reizen", term: "Reizen", aliases: ["Gebot", "bieten"], group: .bidding,
            definition: "Die Spieler bieten mögliche Spielwerte. Wer am höchsten bietet oder hält, wird Alleinspieler und muss ein Spiel ansagen, das mindestens so viel wert ist."
        ),
        GlossaryTerm(
            id: "g-reizwerte", term: "Reizwerte", aliases: ["18", "20", "Reizfolge"], group: .bidding,
            definition: "Gereizt wird nur mit Werten, die ein Spiel wirklich haben kann: 18, 20, 22, 23, 24, 27, 30, 33, 35, 36, 40, 44 und so weiter. 18 ist das kleinste Gebot."
        ),
        GlossaryTerm(
            id: "g-sagen-hoeren", term: "Sagen und Hören", aliases: ["sagen", "hören", "ja", "passe"], group: .bidding,
            definition: "Mittelhand sagt Vorhand Werte an, Vorhand hört und antwortet mit ja oder passe. Danach reizt Hinterhand den Übriggebliebenen weiter."
        ),
        GlossaryTerm(
            id: "g-eingepasst", term: "Eingepasst", aliases: ["alle passen", "Ramsch"], group: .bidding,
            definition: "Passen alle drei, wird nicht gespielt und der nächste Geber teilt neu aus. Ramsch ist eine Hausregel und gehört nicht zur Skatordnung."
        ),
        GlossaryTerm(
            id: "g-ueberreizt", term: "Überreizt", aliases: ["überreizen"], group: .bidding,
            definition: "Ist der Spielwert am Ende kleiner als der Reizwert, hat der Alleinspieler verloren, selbst mit 61 Augen oder mehr."
        ),

        // MARK: Spielarten
        GlossaryTerm(
            id: "g-farbspiel", term: "Farbspiel", aliases: ["Karo", "Herz", "Pik", "Kreuz", "Farbe"], group: .games,
            definition: "Eine Farbe ist Trumpf, zusammen mit den Buben. Der Alleinspieler gewinnt mit mindestens 61 Augen."
        ),
        GlossaryTerm(
            id: "g-grand", term: "Grand", group: .games,
            definition: "Nur die vier Buben sind Trumpf. Grundwert 24, gewonnen mit mindestens 61 Augen."
        ),
        GlossaryTerm(
            id: "g-null", term: "Null", aliases: ["Nullspiel"], group: .games,
            definition: "Der Alleinspieler darf keinen einzigen Stich bekommen. Es gibt keinen Trumpf und der Bube steht zwischen Dame und Zehn. Feste Werte: Null 23, Null Hand 35, Null ouvert 46, Null ouvert Hand 59."
        ),
        GlossaryTerm(
            id: "g-hand", term: "Handspiel", aliases: ["Hand"], group: .games,
            definition: "Der Alleinspieler lässt den Skat liegen und spielt mit seinen zehn Karten. Das bringt eine Stufe mehr, und nur im Handspiel darf er Schneider oder Schwarz ansagen."
        ),
        GlossaryTerm(
            id: "g-ouvert", term: "Ouvert", aliases: ["offen"], group: .games,
            definition: "Der Alleinspieler legt seine Karten vor dem ersten Ausspiel offen hin. Farbspiel und Grand ouvert sind immer Handspiele mit angesagtem Schwarz."
        ),

        // MARK: Spielwert
        GlossaryTerm(
            id: "g-grundwert", term: "Grundwert", aliases: ["Grundwerte"], group: .value,
            definition: "Karo 9, Herz 10, Pik 11, Kreuz 12, Grand 24. Der Spielwert ist der Grundwert mal die Zahl der Stufen."
        ),
        GlossaryTerm(
            id: "g-spitzen", term: "Spitzen", aliases: ["Matadore", "mit", "ohne"], group: .value,
            definition: "Gezählt wird beim Kreuz-Buben, der Skat zählt mit. Hast du ihn, spielst du mit so vielen Trümpfen, wie du lückenlos von oben hältst. Fehlt er, spielst du ohne so viele, wie dir lückenlos fehlen."
        ),
        GlossaryTerm(
            id: "g-stufen", term: "Gewinnstufen", aliases: ["Stufen", "Spiel", "Fälle"], group: .value,
            definition: "Zu den Spitzen kommt immer eine Stufe für das Spiel selbst, dazu je eine für Hand, Schneider, Schneider angesagt, Schwarz, Schwarz angesagt und Ouvert."
        ),
        GlossaryTerm(
            id: "g-schneider", term: "Schneider", group: .value,
            definition: "Eine Partei mit höchstens 30 Augen ist Schneider. Das bringt dem Spielwert eine Stufe mehr, gleich wer Schneider ist."
        ),
        GlossaryTerm(
            id: "g-schwarz", term: "Schwarz", group: .value,
            definition: "Eine Partei bekommt keinen einzigen Stich. Das zählt als Schneider und zusätzlich als Schwarz."
        ),

        // MARK: Am Tisch
        GlossaryTerm(
            id: "g-geben", term: "Geben", aliases: ["Geber", "austeilen", "3-2-4-3"], group: .play,
            definition: "Der Geber teilt im Uhrzeigersinn je drei Karten aus, legt zwei in den Skat, dann je vier und je drei. Jeder hat zehn Karten."
        ),
        GlossaryTerm(
            id: "g-positionen", term: "Vorhand, Mittelhand, Hinterhand", aliases: ["Vorhand", "Mittelhand", "Hinterhand"], group: .play,
            definition: "Vorhand sitzt links vom Geber und spielt zum ersten Stich aus. Es folgen Mittelhand und Hinterhand. Am Dreiertisch ist der Geber Hinterhand."
        ),
        GlossaryTerm(
            id: "g-alleinspieler", term: "Alleinspieler", aliases: ["Solist", "Spieler"], group: .play,
            definition: "Wer das Reizen gewinnt. Er spielt allein gegen die beiden Gegenspieler, die ihre Augen zusammenzählen."
        ),
        GlossaryTerm(
            id: "g-druecken", term: "Drücken", aliases: ["Skat legen", "ablegen"], group: .play,
            definition: "Nach dem Aufnehmen des Skats legt der Alleinspieler zwei beliebige Karten verdeckt zurück. Ihre Augen zählen für ihn."
        ),
        GlossaryTerm(
            id: "g-bedienen", term: "Bedienen", aliases: ["Farbzwang", "abwerfen", "Trumpfzwang"], group: .play,
            definition: "Du musst die ausgespielte Farbe zugeben, bei Trumpf einen Trumpf, und ein Bube zählt dabei zum Trumpf. Kannst du nicht bedienen, darfst du stechen oder abwerfen, ganz nach Wahl."
        ),
        GlossaryTerm(
            id: "g-stich", term: "Stich", aliases: ["stechen"], group: .play,
            definition: "Drei Karten, eine von jedem Spieler. Der höchste Trumpf gewinnt, sonst die höchste Karte der ausgespielten Farbe. Wer den Stich nimmt, spielt zum nächsten aus."
        ),
        GlossaryTerm(
            id: "g-61", term: "61 Augen", aliases: ["gewonnen", "60"], group: .play,
            definition: "Im Farbspiel und Grand gewinnt der Alleinspieler mit mindestens 61 Augen. Bei 60 zu 60 hat er verloren."
        ),
    ]
}
