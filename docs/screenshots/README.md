# Skat Trainer Screenshots

`01_onboarding.png` ist ein Beleg aus dem Headless-Simulator `agent-skat`. Die
sechs nummerierten Produktbilder zeigen den Ablauf: Kurzrunde, Handanalyse,
Drücken, Stichspiel, Startseite und Karten & Reizen. Alte Quellbilder wurden
entfernt, weil sie den vorherigen Kartenbereich des Templates zeigten.

Für Release-Bilder jede fertige Ansicht im Headless-Simulator aufnehmen und die
Rohdateien mit 1320 x 2868 Pixeln unter `scripts/screenshot_raw/` ablegen. Dann:

```sh
python3 scripts/appstore_screenshot_compositor.py
```

Der Kompositor schreibt die App-Store-Bilder nach
`fastlane/screenshots/en-US/`. Reihenfolge und Raumbezeichnungen stehen im
Kompositor. Screenshots der Quell-App zu kopieren verletzt die Paritätsprüfung.
