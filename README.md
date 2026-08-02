# Skat Trainer

Skat Trainer ist eine deutsche Skat-Lernapp für kurze Übungen zu Karten,
Reizen, Spielarten, Drücken und Stichspiel. Sie ist ein unabhängiger Trainer
und kein vollständiges Mehrspieler-Spiel.

## Produktidentität

- Anzeigename: Skat Trainer
- Bundle-ID: `com.jackwallner.skat`
- App-Store-ID: `6796913722`
- Version: `1.0`
- Website: <https://jackwallner.github.io/skat/>
- Hilfe: <https://jackwallner.github.io/skat/support>
- Datenschutz: <https://jackwallner.github.io/skat/privacy-policy>
- Nutzungsbedingungen: <https://jackwallner.github.io/skat/terms>
- Mitgliedschaft: Skat+

## Entwicklung

```sh
xcodegen generate
python3 scripts/generate_metadata_all.py
python3 scripts/validate_metadata.py
xcodebuild -project SkatTrainer.xcodeproj -scheme SkatTrainer \
  -destination 'platform=iOS Simulator,id=<agent-skat-udid>' \
  test CODE_SIGNING_ALLOWED=NO
```

Für Laufzeitprüfungen den dedizierten Headless-Simulator `agent-skat` verwenden.
Simulator.app nicht öffnen. Simulator-Builds dürfen den Produktionsschlüssel
von RevenueCat nicht konfigurieren.

## Veröffentlichung

Die Checkliste liegt unter
[`docs/asc-submission-checklist.md`](docs/asc-submission-checklist.md). Die
Skripte in `scripts/` unterstützen App Store Connect und TestFlight. Zugangsdaten
aus der lokalen Credential-Datei niemals ausgeben.

```sh
./scripts/testflight.sh
```

Den Upload erst nach erfolgreichem Headless-Test ausführen. Eine Einreichung zur
Prüfung ist eine separate Entscheidung.

## CardPort

Der Scaffold- und Prüfablauf liegt in `/Users/jackwallner/cardport`. Die Datei
`.cardport.json` dokumentiert die öffentliche Identität dieses Ports. Nach
Änderungen an Swift-Dateien oder `project.yml` `xcodegen generate` ausführen.
