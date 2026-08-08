# Projektleitfaden für Skat Trainer

Skat Trainer ist eine Übungs-App für deutsches Skat. Sie vermittelt Karten,
Reizen, Spielarten, Drücken und Stichspiel in kurzen Übungen. Sie ist kein
vollständiges Mehrspieler-Spiel. XcodeGen-Projekt und Scheme heißen
`SkatTrainer`, der Headless-Simulator heißt `agent-skat`, die Bundle-ID ist
`com.jackwallner.skat`.

## Produktregeln

Der Wischstapel ist die prägende Interaktion, aber die App ist mehr als eine
Lernkarten-App. Jeder Raum darf die Mechanik verwenden, die zur Fähigkeit
passt: Auswahlfragen, Handanalyse, Drück-Szenarien oder generierte Übungen.

Alle Beispiele sind eigene Lehrhände. Sie erklären allgemeine Skat-Regeln und
kopieren keine externe Karte, Lektion oder markenrechtlich geschützte Quelle.
Hausregeln können abweichen. Texte sollen die gelehrte Regel nennen, wenn eine
Variante häufig vorkommt.

`ContentValidityTests` prüft alle Übungen in `DrillLibrary`. IDs müssen
einmalig sein. Verwende ein 32-Karten-Skatblatt, wiederhole keine physische
Karte in einer Hand oder einem Blatt, halte Drück-Szenarien bei zwölf Karten
mit zwei empfohlenen Karten, vermeide Gedankenstriche in sichtbaren Texten
und bewahre die Trennung zwischen kostenlos und Skat+.

Der Review-Ablauf ist endgültig. Nach der dritten abgeschlossenen positiven
Übung fragt `ReviewPromptSheet`, ob die App Freude macht. Ja öffnet die
Bewertungsseite für App-Store-ID 6796913722, Nein öffnet den Feedback-Entwurf.
Unzufriedene Spieler sehen keine Bewertungsaufforderung.

## Skat+-Produkte

Die lokale StoreKit-Konfiguration enthält:

- `com.jackwallner.skat.monthly`, 1,99 $ pro Monat, eine Woche Probe
- `com.jackwallner.skat.yearly`, 9,99 $ pro Jahr, eine Woche Probe
- `com.jackwallner.skat.lifetime`, 29,99 $ einmalig

Dieses Projekt hat zwei Berechtigungen, `pro` und `Skat+`, und jedes Produkt
hängt an beiden. Das Gerüst hat die Berechtigung nach dem Spielernamen
benannt, und RevenueCat lässt einen `lookup_key` nicht ändern, also kam `pro`
daneben: ausgelieferte Builds, die `entitlements["pro"]` prüfen, und aktuelle,
die jede aktive Berechtigung akzeptieren, schalten beide nach einem Kauf frei.
Beide müssen versorgt bleiben, das erledigt `scripts/rc-wire-appstore-products.py`
idempotent, zusammen mit den App-Store-Produkten und den Paketen `$rc_monthly`,
`$rc_annual` und `$rc_lifetime` des aktuellen Angebots. Das Projekt hatte nur
Test-Store-Produkte, was ein Angebot ohne Pakete und einen toten Kaufknopf
ergibt, also vor jeder Einreichung `scripts/verify-store-config.py` laufen
lassen. Der
Spielername lautet `Skat+`. Der öffentliche RevenueCat-Schlüssel steht in
`Shared/Services/SubscriptionService.swift`. Der Simulator-Schutz muss
erhalten bleiben, damit der Produktionsschlüssel `appl_` nie in einem
Simulator konfiguriert wird. Für Simulator-Käufe dienen die lokale StoreKit-
Datei und die lokale Mitgliedschaftsüberschreibung in den Einstellungen.

## Architektur

- `Shared/Models` enthält `PlayingCard`, `Suit`, `HandCategory`, Übungsmodelle
  und die Raum-Sperren.
- `Shared/Content` enthält Karten- und Reizgrundlagen, Spielarten, Drücken,
  Stichspiel, Primer, Zusatzübungen und den Meistertisch. `DrillLibrary.rooms`
  ist die Quelle für die fünf Räume.
- `Shared/Services` enthält Fortschritt, Einstellungen, Wiederholungsplanung,
  Abos, Benachrichtigungen und den Review-Ablauf.
- `SkatTrainer/Views` enthält Onboarding, Lobby, Räume, Wischstapel,
  Kurzrunden, generierte Übungen, Einstellungen und Paywall.
- `SkatTrainer/Utilities/Theme.swift` enthält das warme Karten­tisch-Design,
  Haptik, Töne und wiederverwendbare View-Stile.

Die vier Anfänger-Räume sind kostenlos. Jeder erhält einen zusätzlichen
Skat+-Satz. Der Meistertisch ist nur für Mitglieder. `Room.isLocked` ist die
einzige Sperrlogik, und `SessionBuilder` verwendet dieselbe Regel für
Kurzrunden.

Generierte Übungen verwenden `HandGenerator` für eindeutige Fünf-Karten-
Strukturen, `PracticeRecordStore` für Wiederholungen und `PracticeRunView` für
Endlos-, Wiederholungs- und Zeitmodus. Generierte Fragen müssen gültig bleiben
und dürfen keine IDs der redaktionellen Inhalte verbrauchen.

## Inhaltsablauf

1. Eigene Inhalte unter `Shared/Content` ergänzen.
2. Die Übung in `DrillLibrary` registrieren und als kostenlos oder Skat+
   markieren.
3. Invarianten in `ContentValidityTests` ergänzen oder anpassen.
4. Mit `xcodegen generate` das Xcode-Projekt neu erzeugen.
5. Unit-Tests ausführen und den Raum auf `agent-skat` prüfen.

Der wiederverwendbare CardPort-Ablauf liegt im Nachbarordner
`/Users/jackwallner/cardport`. Für weitere Karten-Apps zuerst README und
`docs/parity-contract.md` lesen, dann Scaffold und Prüfskripte verwenden.

## Build und Simulator

Nach neuen oder entfernten Swift-Dateien und nach Änderungen an `project.yml`
immer `xcodegen generate` ausführen. Mit dem Scheme `SkatTrainer` bauen. Für
Laufzeitprüfungen ausschließlich den dedizierten Simulator `agent-skat`
verwenden. Simulator.app darf nicht geöffnet werden.

Release-Skripte erwarten App-Store-Connect-Zugangsdaten aus der lokalen
Credential-Datei. Diese Daten dürfen niemals ausgegeben werden. Die App-
Store-ID wird nach dem Anlegen des ASC-Eintrags ergänzt.

Details zum Wischstapel stehen in `SkatTrainer/Views/Drills/CLAUDE.md`.
