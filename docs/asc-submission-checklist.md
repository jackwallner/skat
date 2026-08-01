# App-Store-Connect-Checkliste, Skat Trainer

Diese Datei ist eine Referenz zum manuellen Ausfüllen der Datenschutz- und
Altersfreigabe-Fragebögen in App Store Connect. Die Antworten werden nicht
automatisch übertragen.

## Datenschutz

Erfasst werden ausschließlich **Käufe** und **Kennungen**, die der RevenueCat-
SDK für den Mitgliedschaftsstatus übermittelt. Die App hat kein Konto, keine
Analyse-SDK, keine Werbung und sammelt weder Namen noch E-Mail-Adresse.

### Käufe

- Datentyp: Kaufverlauf
- Erfasst: Ja
- Mit der Identität verknüpft: Ja, mit der anonymen RevenueCat-App-ID
- Für Tracking verwendet: Nein
- Zweck: App-Funktionalität, insbesondere die Freischaltung von Skat+

### Kennungen

- Datentyp: Benutzer-ID
- Erfasst: Ja
- Mit der Identität verknüpft: Ja, mit derselben anonymen App-ID
- Für Tracking verwendet: Nein
- Zweck: App-Funktionalität

### Alles Weitere

Kontaktinformationen, Standort, Kontakte, Gesundheitsdaten, Finanzdaten,
Nutzerinhalte, Suchverlauf, Nutzungsdaten, Diagnosedaten und Tracking werden
als nicht erfasst angegeben. Apple verarbeitet die Zahlungsdaten. Die App
erhält keine Karten- oder Kontodaten.

## Altersfreigabe

Ziel: **4+**. Für Gewalt, Sexualität, Sprache, Drogen, Horror, medizinische
Themen und ähnliche Kategorien jeweils **Keine** wählen.

**Simuliertes Glücksspiel: Nein.** Skat Trainer ist eine Einzelspieler-
Übungsapp mit Lernkarten, Quizfragen, Drück-Szenarien und Stichentscheidungen.
Es gibt keine Gegner, Einsätze, Chips, Wetten oder Preise.

**Uneingeschränkter Webzugriff: Nein.** Nutzungsbedingungen, Datenschutz,
Support und App-Store-Bewertung öffnen sich über System-Links im Browser.

## Release-Quellen

- Datenschutz: `docs/privacy-policy.html`
- Nutzungsbedingungen: `docs/terms.html`
- Support: `docs/support.html`
- App-Store-Metadaten: `fastlane/metadata/de-DE/`
- Review-Hinweise: `fastlane/metadata/review_information/notes.txt`
- Produkte: `scripts/asc-setup-release.py`, `scripts/asc-create-lifetime.py`

Vor der Einreichung die Produkte, Preise, Probezeit, Legal-Links und den
TestFlight-Build in App Store Connect nochmals prüfen. Die Einreichung bleibt
eine bewusste manuelle Entscheidung.
