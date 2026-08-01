# Release-Readiness-Audit, 1. August 2026

## Ergebnis

Die App ist ein funktionsfähiger CardPort-Port der Mahj-Produktoberfläche für
deutsches Skat-Training. Sie ist kein vollständiges Mehrspieler-Skatspiel.
Build 19 ist hochgeladen, die Einreichung wartet noch auf veröffentlichte
App-Privacy-Antworten.

## Geprüft und bestanden

- CardPort-Identität und Template-Parität: bestanden.
- Metadaten- und ASO-Validierung: 50 ASC-Locale mit deutschem Fallback.
- XcodeGen-Projekt: Entwicklungssprache und Region `de`.
- Build auf `agent-skat`: erfolgreich.
- Tests auf `agent-skat`: 52 bestanden, 0 fehlgeschlagen.
- Laufzeit-Smoke-Test: Startseite, Kurzrunde, Einstellungen und Skat+-Paywall.
  Die sichtbaren Texte in diesen Flows waren deutsch.
- Simulator-Logs: kein App-Fehler und kein produktiver RevenueCat-Schlüssel.
- App-Icon: eigenständiges blau-goldenes Skat-Motiv mit Karo, Schelle und
  Eichel, nicht das Cribbage-Icon.

## App Store Connect

- App: `Skat Trainer: Skat üben`.
- App-Store-ID: `6796913722`.
- Version 1.0: `PREPARE_FOR_SUBMISSION`, Build 19 ist angehängt und `VALID`.
- App-Info- und Versions-Metadaten: 50 Locales vorhanden.
- Deutsche Screenshots: 6 auf `APP_IPHONE_67` hochgeladen.
- Altersfreigabe, Kategorie, Preise, Verfügbarkeiten und Testangebote sind
  eingerichtet.
- Lifetime-Kauf: `READY_TO_SUBMIT`.
- Monats- und Jahresabo: `READY_TO_SUBMIT`, Versions-Metadaten und
  1024x1024-Produktbilder sind vorhanden.
- Lifetime-IAP: `READY_TO_SUBMIT`, Versions-Metadaten und das
  versionsgebundene 1024x1024-Produktbild sind vorhanden.
- Ein ASC-Review-Entwurf enthält die App-Version, die Subscription-Gruppe,
  beide Subscription-Versionen und das Lifetime-IAP.

## Offen

- App Privacy ist noch nicht veröffentlicht. ASC blockiert die App-Version mit
  `APP_DATA_USAGES_REQUIRED`.
- Die App wurde noch nicht zur Prüfung eingereicht. Nach Veröffentlichung der
  App-Privacy-Antworten kann der bestehende Review-Entwurf eingereicht werden.
- Für den interaktiven ASC-Web-Login wird noch eine `FASTLANE_SESSION` benötigt.
- Die 50 Storefront-Locale verwenden derzeit deutsches Fallback-Copy. Das ist
  keine unabhängige Übersetzung in 50 Sprachen.
