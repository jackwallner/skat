# Skat-Inhaltsprüfung

Diese Prüfung dokumentiert die fachliche Umstellung der Vorlage auf deutsches
Skat.

## Geprüftes Modell

- Standard-Skatblatt mit 32 Karten: 7 bis Ass in Kreuz, Pik, Herz und Karo.
- Kartenwerte: 7 bis 9 zählen null, die Zehn zählt zehn, Bube zwei, Dame
  drei, König vier und Ass elf Augen.
- Geübte Bereiche sind Kartenwerte, Reizen, Trumpf, Grand, Null, Drücken,
  Bedienpflicht, Stichführung und Spielwert.
- Hand-Erkennungsfragen verwenden fünf verschiedene Karten.
- Drück-Szenarien verwenden zwölf verschiedene Karten nach Aufnahme des Skats
  und empfehlen genau zwei Karten aus diesem Blatt.
- Kein Szenario verwendet Joker oder Karten außerhalb des Skatblatts.

## Geprüfte Produktschicht

Die Unit-Tests decken eindeutige IDs, gültige Antwortindizes, freie Räume,
Skat+-Extras, die Sperre des Meistertischs, die Filterung der Kurzrunde und
die Eindeutigkeit generierter Hände ab. Die App-Store-ID wird nach dem
Anlegen des ASC-Eintrags ergänzt. Der Bewertungsdialog erscheint erst nach
der Zufriedenheitsfrage.

## Vor Veröffentlichung

- Hausregel-Hinweise nochmals mit der für die Veröffentlichung verwendeten
  Skat-Regelquelle abgleichen.
- Alle Räume auf `agent-skat` mit den vorgesehenen Dynamic-Type-Größen
  prüfen.
- CardPort-Parität nach jeder Änderung an Produktoberfläche oder Release-Datei
  erneut ausführen.
