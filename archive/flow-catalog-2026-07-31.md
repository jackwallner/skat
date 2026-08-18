# Laufzeitkatalog

Der CardPort-Port bewahrt die Laufzeitstruktur der Vorlage und übersetzt sie
in Skat-Übungen:

| Ablauf | Hauptinteraktion | Abschluss |
| --- | --- | --- |
| Einführung | Spielstärke, Primer, Feature-Tour | echte Kurzrunde oder direkter Einstieg zur Startseite |
| Karten & Reizen | Karten wischen und Quizfragen | bewertete Übung abgeschlossen |
| Spielarten | Spielart erkennen und Stichgründe lesen | bewertete Übung abgeschlossen |
| Drücken | zwei Karten aus zwölf Karten auswählen | Szenarioauswertung und Erklärung |
| Stichspiel | Bedienpflicht und Kartenwahl | bewertete Übung abgeschlossen |
| Der Meistertisch | fortgeschrittene gesperrte Inhalte | mit Skat+ freigeschaltete Übung |
| Übungsmodi | generierte, wiederholte oder zeitbegrenzte Aufgaben | Punktzahl, Bestwert oder Lernverlauf |

## Finaler Paritätscheck, 1. August 2026

- Gerät: `agent-skat`, UDID `BAA39AD4-B4B7-4D67-BBAF-EFA3F3AC5E94`.
- Build: `xcodegen generate`, danach das Schema `SkatTrainer` auf dem
  dedizierten Simulator.
- Tests: 52 Tests, 0 Fehler.
- UI-Prüfung: Startseite, Kurzrunde, Karten & Reizen, Drücken, Stichspiel,
  Einstellungen und Skat+-Paywall. Der Paywall zeigt Jahres-, Monats- und
  Dauerangebot, Probezeit, Verlängerung, Wiederherstellen sowie Links zu
  Nutzungsbedingungen und Datenschutz.
- Release-Bilder: sechs echte Simulator-Bilder in
  `scripts/screenshot_raw/`, `fastlane/screenshots/en-US/` und den sechs
  öffentlichen `docs/appstore-screenshot-*.png`.
- Simulator-Sicherheit: RevenueCat wird im Simulator nicht mit dem
  Produktionsschlüssel konfiguriert.
- CardPort-Prüfungen: Identität, Inhalt, UI-Struktur, Legal-Routen und
  Screenshot-Abmessungen sind verifiziert.
