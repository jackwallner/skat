import Foundation

struct WhatsNewItem: Identifiable, Sendable {
    let id: String
    let icon: String
    let title: String
    let body: String
    let isPlus: Bool

    init(id: String, icon: String, title: String, body: String, isPlus: Bool = false) {
        self.id = id
        self.icon = icon
        self.title = title
        self.body = body
        self.isPlus = isPlus
    }
}

struct WhatsNewRelease: Sendable {
    let version: String
    let headline: String
    let items: [WhatsNewItem]
}

enum WhatsNew {
    static let currentVersion: String =
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"

    private static let lastSeenKey = "whatsnew.lastSeenVersion"

    static let releases: [WhatsNewRelease] = [
        WhatsNewRelease(
            version: "1.2.0",
            headline: "Ein besserer Rhythmus für den Skatabend",
            items: [
                WhatsNewItem(
                    id: "skat-minute",
                    icon: "calendar.badge.clock",
                    title: "Skat-Minute",
                    body: "Löse täglich dieselben fünf Fragen wie alle anderen Mitglieder, teile dein Ergebnis und halte einen nachsichtigen Rhythmus von fünf Tagen pro Woche.",
                    isPlus: true
                ),
                WhatsNewItem(
                    id: "game-night-prep",
                    icon: "person.2.fill",
                    title: "Skatabend-Vorbereitung",
                    body: "Lege deinen üblichen Skatabend fest und bekomme rechtzeitig eine Fünf-Minuten-Runde aus deinen Fehlern und deinem schwächsten Raum.",
                    isPlus: true
                ),
                WhatsNewItem(
                    id: "ipad",
                    icon: "ipad.landscape",
                    title: "Für das iPad gemacht",
                    body: "Übe am Tisch mit einem eigenen iPad-Layout im Hoch- oder Querformat."
                ),
            ]
        ),
        WhatsNewRelease(
            version: "1.0",
            headline: "Skat lernen, eine Runde nach der anderen",
            items: [
                WhatsNewItem(
                    id: "rooms",
                    icon: "rectangle.grid.2x2.fill",
                    title: "Vier freie Übungsräume",
                    body: "Baue Sicherheit auf mit Karten, Spielarten, Drücken und Stichspiel."
                ),
                WhatsNewItem(
                    id: "coaching",
                    icon: "lightbulb.fill",
                    title: "Erklärungen, die bleiben",
                    body: "Jede Antwort zeigt die Regel, die Beobachtung und den Grund für die Entscheidung."
                ),
                WhatsNewItem(
                    id: "progress",
                    icon: "chart.bar.fill",
                    title: "Übung mit Gedächtnis",
                    body: "Serien, Fehler und eine tägliche Kurzrunde halten das Wichtige griffbereit."
                ),
            ]
        ),
        WhatsNewRelease(
            version: "1.1",
            headline: "Üben ohne Ende",
            items: [
                WhatsNewItem(
                    id: "endless",
                    icon: "infinity",
                    title: "Endlos üben",
                    body: "Frische Kartenmuster bei jeder Runde. Lies Trumpf, Grand, Null und sichere Stiche so lange du möchtest.",
                    isPlus: true
                ),
                WhatsNewItem(
                    id: "review",
                    icon: "arrow.trianglehead.counterclockwise",
                    title: "Fehler wiederholen",
                    body: "Die App merkt sich unsichere Antworten und bringt sie nach und nach zurück.",
                    isPlus: true
                ),
                WhatsNewItem(
                    id: "challenge",
                    icon: "timer",
                    title: "Zeitprüfung",
                    body: "90 Sekunden, so viele sichere Entscheidungen wie möglich, mit persönlicher Bestleistung.",
                    isPlus: true
                ),
                WhatsNewItem(
                    id: "stats",
                    icon: "chart.bar.fill",
                    title: "Fortschritt im Detail",
                    body: "Genauigkeit pro Raum, schwächstes Thema und deine gesamte Übungszeit."
                ),
                WhatsNewItem(
                    id: "content",
                    icon: "plus.rectangle.on.folder.fill",
                    title: "Mehr Übungen in jedem Raum",
                    body: "Neue Originalfragen zu Karten, Spielarten, Drücken, Stichspiel und Meistertisch."
                ),
            ]
        )
    ]

    static var currentRelease: WhatsNewRelease? { releases.first { $0.version == currentVersion } }

    static func shouldPresent(hasOnboarded: Bool, defaults: UserDefaults = .standard) -> Bool {
        guard hasOnboarded, currentRelease != nil else { return false }
        let lastSeen = defaults.string(forKey: lastSeenKey) ?? ""
        return lastSeen != currentVersion
    }

    static func markSeen(defaults: UserDefaults = .standard) { defaults.set(currentVersion, forKey: lastSeenKey) }

    static func markCurrentAsBaseline(defaults: UserDefaults = .standard) {
        defaults.set(currentVersion, forKey: lastSeenKey)
    }
}
