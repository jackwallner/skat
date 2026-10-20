# Projektleitfaden für Skat Trainer

Skat Trainer ist eine Übungs-App für deutsches Skat. Sie vermittelt Karten,
Reizen, Spielarten, Drücken und Stichspiel in kurzen Übungen. Sie ist kein
vollständiges Mehrspieler-Spiel. XcodeGen-Projekt und Scheme heißen
`SkatTrainer`, der Simulator-Lease-Owner heißt `skat`, die Bundle-ID ist
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

Bewertungen: keine eigene Bewertungsfrage (App Review 5.6.1). Eine abgeschlossene
Übung oder Skat Minute mit mindestens der Hälfte richtig ruft etwa 3 s später
über `.requestsReview(after:)` Apples `requestReview()` auf, wenn nichts darüber
liegt. Bedingungen stehen nur in `ReviewPromptTracker` (zweiter Kaltstart,
30 Tage Abstand) plus Onboarding fertig und der RevenueCat-Schalter
`rating_prompt`. Nur die Einstellungszeile „Skat Trainer bewerten“
(Bewertungsseite für App-Store-ID 6796913722) beendet die Anfragen; „Feedback
senden“ öffnet `ReviewPromptSheet(.feedback)` und schickt über
`FeedbackService` (App-Schlüssel `skat`) an die gemeinsame Feedback-Tabelle,
ohne die Anfragen zu beenden. Dasselbe Blatt stellt die eine Abwanderungsfrage.
Details: `.claude/rules/feedback-and-retention.md`.

Der Probe-Ablauf (Onboarding-Probeseite, Paywall, Kauf bis Tour) ist wie Mahj
1.3.2 aufgebaut; nur der Knopftext variiert über RevenueCat-Angebotsmetadaten
(`TrialCTA`). Der abgerechnete Betrag ist der auffälligste Preis (3.1.2(c)),
Preise kommen immer live aus StoreKit. Jede andere Änderung braucht Jacks
Zustimmung. Das Meta-SDK bleibt inaktiv, solange `META_APP_ID` und
`META_CLIENT_TOKEN` in `project.yml` leer sind, und startet nie im Simulator.
ATT wird nur in `HomeView.askForTrackingIfNeeded` abgefragt.

## Skat+-Produkte

Die lokale StoreKit-Konfiguration enthält:

- `com.jackwallner.skat.monthly`, 6,99 $ pro Monat, eine Woche Probe
- `com.jackwallner.skat.yearly`, 29,99 $ pro Jahr, eine Woche Probe
- `com.jackwallner.skat.lifetime`, 69,99 $ einmalig

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
  Abos, Benachrichtigungen und die Bewertungslogik.
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
5. Unit-Tests ausführen und den Raum auf dem geleasten Simulator prüfen.

Der wiederverwendbare CardPort-Ablauf liegt im Nachbarordner
`/Users/jackwallner/cardport`. Für weitere Karten-Apps zuerst README und
`docs/parity-contract.md` lesen, dann Scaffold und Prüfskripte verwenden.

## Build und Simulator

Release-Skripte erwarten App-Store-Connect-Zugangsdaten aus der lokalen
Credential-Datei. Diese Daten dürfen niemals ausgegeben werden.

Details zum Wischstapel stehen in `SkatTrainer/Views/Drills/AGENTS.md`.

## Deep notes (load on demand)
These files load automatically when you read a file matching their `paths:`. Agents that do not auto-load rules (Codex, Cursor) should open the file for the area they are touching. Record new area-specific learnings in the matching file, not here.

| File | Covers | Read when |
|---|---|---|
| `.claude/rules/game-night.md` | Game-night rhythm (1.2): Skat Minute, the daily Drücken question, deterministic dealing, game night prep | `SkatMinute*`, `GameNightPrepView`, `HandGenerator`, `SessionBuilder` |
| `.claude/rules/ipad-layout.md` | iPad (1.2): device family, `CenteringScrollView`, the pager eyebrow, the deck width cap | Drill layouts, Home columns |
| `.claude/rules/screenshots.md` | Screenshots: the capture script, the throwaway iPad, test gotchas | Capture scripts, the `Screenshots` scheme |
| `.claude/rules/expert-content.md` | Expert exercises, explicit discard objectives, rules and verification | `AdvancedContent`, `AppliedContent`, content validity tests |
| `.claude/rules/generated-practice.md` | Endless skills, rules oracle, miss notes, mastery, What's New | `SkatRules`, `PracticeGenerators`, `EndlessPractice`, `HandGenerator`, `Mastery` |
| `.claude/rules/feedback-and-retention.md` | Feedback sink, churn question, weekly gain ledger, ratings policy, what was not ported | `FeedbackService`, `ReviewPromptSheet`, `MasteryLedger`, `ReviewRequest` |
| `.claude/rules/meta-ads.md` | Meta SDK + ATT (inert), remote switches and `TrialCTA`, the relay that lives in Mahj | `MetaAds`, `RemoteConfig`, ATT timing, `project.yml` Meta ids |
| `.claude/rules/membership-and-trial.md` | Trial flow, 3.1.2(c) price line, membership state, fit at every size, What's New mechanics | `SubscriptionService`, onboarding, paywall, primer, tour |
| `.claude/rules/android.md` | Android port: package, RevenueCat IDs, Play products, Swift content export, Pro AVD commands, store assets, Play state | `android/**`, `docs/android-*.html`, Play scripts |
