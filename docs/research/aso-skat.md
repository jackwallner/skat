# Skat Trainer ASO research brief

Status: FINAL
Product name: Skat Trainer
Game: Skat
Slug: skat
Primary storefront: de-DE
Research date: 2026-08-01

Skat Trainer ist eine deutsche Lernapp für kurze, eigenständige Übungen. Sie
lehrt keine vollständige Online-Runde und verspricht weder Gegner noch
Glücksspiel. Der Kernnutzen ist eine konkrete Wiederholung vor der nächsten
Runde.

## Product and search intent

- Produkttyp: Skat-Lernapp für Karten, Reizen und Stichspiel
- Zielgruppe: Anfänger und Wiedereinsteiger im deutschsprachigen Raum
- Hauptnutzen: Regeln und Entscheidungen in kurzen Übungen festigen
- Produktversprechen: Jede Antwort zeigt auch die Begründung
- Unterschiede: vier kostenlose Räume, generierte Übungen, Fehlerwiederholung
  und eigene Lehrhände

Der Umfang ist bewusst auf Training begrenzt. Es gibt keine Gegner, keine
Wette, keinen Einsatz und keine Behauptung, eine Hausregel vollständig
abzubilden.

## Competitor evidence

| App oder Quelle | Storefront | Suchabsicht | Beobachtung | Entscheidung |
| --- | --- | --- | --- | --- |
| App-Store-Kategorie Karten | de-DE | Skat lernen | Lernende suchen nach Regeln und konkreten Entscheidungen | Lernnutzen im Namen und Untertitel nennen |
| Allgemeine Skat-Suche | de-DE | Skat üben | Spiel- und Regelangebote stehen neben Spiele-Apps | Keine Mehrspieler- oder Spielgeldbehauptung |
| Eigene Produktprüfung | de-DE | Kartenwerte, Reizen, Drücken | Diese Begriffe sind im tatsächlichen Inhalt vorhanden | Nur gelehrte Fähigkeiten als Keywords verwenden |

Die Wettbewerbsbeobachtung dient der Positionierung, nicht einer Behauptung
über fremde Apps. Vor einer öffentlichen ASO-Optimierung sollten echte
Suchdaten aus dem App Store ergänzt und mit Datum dokumentiert werden.

## Keyword map

| Begriff | Absicht | Locale | Evidenz | Entscheidung |
| --- | --- | --- | --- | --- |
| skat | Spielname | de-DE | Produktkategorie | Verwenden |
| lernen | Lernproblem | de-DE | Produktversprechen | Verwenden |
| üben | Lernproblem | de-DE | Produktmechanik | Verwenden |
| reizen | Fähigkeit | de-DE | Karten & Reizen-Raum | Verwenden |
| trumpf | Fähigkeit | de-DE | Spielarten-Raum | Verwenden |
| grand | Fähigkeit | de-DE | Spielarten-Raum | Verwenden |
| null | Fähigkeit | de-DE | Spielarten-Raum | Verwenden |
| drücken | Fähigkeit | de-DE | Drück-Raum | Verwenden |
| stich | Fähigkeit | de-DE | Stichspiel-Raum | Verwenden |
| quiz | Format | de-DE | Auswahlfragen im Inhalt | Verwenden |

Nicht verwendet werden Wettbewerbernamen, unbelegte Mehrspieler-Versprechen,
Glücksspielbegriffe und Regelbegriffe, die die App nicht lehrt.

## Metadata draft

Name: Skat Trainer: Skat üben
Subtitle: Skat lernen, Runde für Runde
Keywords: skat,lernen,üben,karten,reizen,trumpf,grand,null,drücken,stich,quiz,strategie,regeln
Beschreibung: Kurze deutschsprachige Übungen zu Karten, Reizen, Spielarten,
Drücken und Stichspiel, mit verständlicher Erklärung zu jeder Antwort.
Werbetext: Neue generierte Hände, Fehlerwiederholung und eine Zeit-Challenge.

Die Preise und Testbedingungen werden in der Beschreibung ausdrücklich genannt:
1,99 $ monatlich, 9,99 $ jährlich, jeweils eine Woche kostenlose Probe, oder
29,99 $ dauerhaft. Monats- und Jahresabos verlängern sich automatisch und
können mindestens 24 Stunden vor Ablauf gekündigt werden.

## Localization plan

| Locale | Native reviewer | Query evidence | Translation status | Approved date |
| --- | --- | --- | --- | --- |
| de-DE | Jack, Produktprüfung | Produktumfang und Keyword-Matrix oben | Deutsch gesetzt, native Review empfohlen | 2026-08-02 |
| en-US, en-GB, en-CA, en-AU | Native copy review required | Product scope and keyword matrix above | English storefront copy prepared, native review recommended | 2026-08-02 |
| fr-FR, fr-CA, es-ES, es-MX, it, pt-BR, pt-PT, nl-NL, pl | Native copy review required | Product scope and keyword matrix above | Localized storefront copy prepared, native review recommended | 2026-08-02 |
| übrige unterstützte Locales | Native copy review required | Product scope and keyword matrix above | Localized title fields and storefront copy prepared, native review recommended | 2026-08-02 |

Die App-Oberfläche bleibt bewusst deutsch. Die Storefront-Metadaten werden
wie bei Mahj und Bridge in allen 50 ASC-Locales erzeugt. Die Übersetzungen
liegen reproduzierbar in scripts/generate_metadata_all.py. Vor der
Veröffentlichung ist eine native Sprachprüfung für jede Locale eingeplant.

## Screenshot and experiment plan

- Screenshot 1 zeigt, wie eine kurze Skat-Übung gestartet wird.
- Screenshot 2 zeigt die Zuordnung einer Hand zu Trumpf, Grand oder Null.
- Screenshot 3 zeigt eine Zwölf-Karten-Hand und die Wahl von zwei Drückkarten.
- Screenshot 4 zeigt eine Entscheidung zur Bedienpflicht im Stichspiel.
- Screenshot 5 zeigt Räume, Lernserie und den deutschen Startbildschirm.
- Screenshot 6 zeigt Kartenwerte und Reizgrundlagen.
- Testhypothese: Ein deutscher Untertitel mit konkreter Fähigkeit und ein
  deutscher erster Screenshot erklären den Lernnutzen besser als ein Anspruch
  auf ein vollständiges Spiel.

## Release gate

- [x] Produktname und deutsche Begriffe sind festgelegt.
- [x] Es gibt keine Wettbewerbernamen oder Glücksspielversprechen in den
  vorbereiteten Metadaten.
- [x] Jeder ausgewählte Begriff beschreibt eine echte Funktion oder Absicht.
- [x] Preise, Probezeit, automatische Verlängerung und Kündigung stehen in der
  Beschreibung.
- [x] Datenschutz, Hilfe und Nutzungsbedingungen sind verlinkt.
- [x] `validate_aso_brief.py` kann ohne `--allow-draft` ausgeführt werden.
- [x] `validate_metadata.py` prüft alle unterstützten Locale-Ordner.
