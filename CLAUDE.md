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

## Game-night rhythm (1.2)

Skat+ owns two recurring rituals. `SkatMinuteContent` deterministically builds the
same five questions for every member on a local calendar day: two generated
Blattlesen, one Drücken decision, and two Stichspiel questions. Results and a 30-day
archive stay on device in `SkatMinuteStore`; sharing uses the system share sheet and
needs no account or leaderboard.

The Drücken question is built straight from the authored scenarios, NOT through
`SessionBuilder.choiceItems`. The quick-session pool deliberately excludes
those drills, so drawing the daily from it silently produced a four-question
challenge with that skill missing entirely.

`HandGenerator` deals the daily hands from a caller-supplied generator all the
way down: `deal`, `fill`, and `randomHand` are all generic over
`RandomNumberGenerator`. One `.shuffled()` or `.randomElement()` left calling
the system source is enough to make the same day deal different hands on
different devices, and the stability test is what catches it.

`GameNightPrepView` stores a weekly game night in `AppSettings`, schedules a
local notification, and opens directly into `SessionBuilder.gameNightPrep`,
which prioritizes due mistakes, misses, the weakest room, and unseen member
content in that order. Both features are entirely Skat+ gated.

## iPad (1.2)

iPad support is free: `TARGETED_DEVICE_FAMILY "1,2"`, portrait and landscape,
adaptive Home columns, drill grids, and readable content widths.

Every drill body is a scroll view, so a question that underfills the viewport
was pinned to the top and left the bottom half of a 13-inch iPad empty.
`CenteringScrollView` centres short content and leaves taller content scrolling
untouched (minHeight, not height). Keep its `maxWidth: .infinity`: a plain
ScrollView centres narrow content for you, an explicitly framed one does not.
The room eyebrow lives INSIDE `QuestionPager` so it centres with the question,
and the flashcard deck is capped at 520pt wide so a card still looks like a
card.

## Screenshots

`scripts/capture-screenshots.sh <udid> <out-dir> [prefix]` drives the real app
through the App Store screens via the `Screenshots` scheme.
`scripts/with-ipad-sim.sh` creates a throwaway 13-inch iPad (App Store iPad
shots must be 2064x2752 and the agent-sim pool has no iPad Pro), boots it
headless, and deletes it on exit:

```bash
./scripts/with-ipad-sim.sh sh -c './scripts/capture-screenshots.sh "$IPAD_UDID" out ipad_'
```

Gotchas baked into the test: the What's New sheet covers Home on the first
launch after a version bump and returns every time Home reappears, so the
script passes the marketing version in through
`TEST_RUNNER_SCREENSHOT_APP_VERSION` and the test marks it seen; returning to
the root only taps navigation-bar button 0 while a back button is there,
because on Home that button is the Settings gear; and the test never calls
XCTFail, because a failing UI test spends ten minutes collecting simulator
diagnostics first.
