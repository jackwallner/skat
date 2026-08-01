# Release-Readiness-Audit, 1. August 2026

## Ergebnis

Die App ist ein funktionsfähiger CardPort-Port der Mahj-Produktoberfläche für
deutsches Skat-Training. Sie ist kein vollständiges Mehrspieler-Skatspiel und
noch nicht zur Einreichung bereit.

## Geprüft und bestanden

- CardPort-Identität und Template-Parität: bestanden.
- Metadaten- und ASO-Validierung: 50 ASC-Locale mit deutschem Fallback.
- XcodeGen-Projekt: Entwicklungssprache und Region `de`.
- Build auf `agent-skat`: erfolgreich.
- Tests auf `agent-skat`: 52 bestanden, 0 fehlgeschlagen.
- Laufzeit-Smoke-Test: Startseite, Kurzrunde, Einstellungen und Skat+-Paywall.
  Die sichtbaren Texte in diesen Flows waren deutsch.
- Simulator-Logs: kein App-Fehler und kein produktiver RevenueCat-Schlüssel.

## App Store Connect

- App: `Skat Trainer: Skat üben`.
- App-Store-ID: `6796913722`.
- Version 1.0: `PREPARE_FOR_SUBMISSION`.
- App-Info- und Versions-Metadaten: 50 Locales vorhanden.
- Deutsche Screenshots: 6 auf `APP_IPHONE_67` hochgeladen.
- Altersfreigabe, Kategorie, Preise, Verfügbarkeiten und Testangebote sind
  eingerichtet.
- Lifetime-Kauf: `READY_TO_SUBMIT`.
- Monats- und Jahresabo: Versions-Metadaten und 1024x1024-Produktbilder sind
  vorhanden, der ASC-Elternstatus meldet weiterhin `MISSING_METADATA`.

## Offen

- Kein Build ist an Version 1.0 angehängt.
- Die App wurde nicht zur Prüfung eingereicht und nicht über TestFlight
  verteilt.
- Die Monats- und Jahresabos brauchen noch die abschließende ASC-Zuordnung
  beziehungsweise Einreichung zusammen mit einem App-Build.
- Die 50 Storefront-Locale verwenden derzeit deutsches Fallback-Copy. Das ist
  keine unabhängige Übersetzung in 50 Sprachen.
