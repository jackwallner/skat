# Regeln für das Lernkarten-Deck

`FlashcardDrillView` ist ein Wisch-Deck. Tippen dreht eine Karte um. Eine
umgedrehte Karte kann nach rechts für „gewusst“ oder nach links für „noch
einmal“ gewischt werden. Ziehen vor dem Umdrehen federt zurück, statt zu
bewerten. Rückgängig legt die zuletzt bearbeitete Karte wieder nach vorn.

Karten mit `CardChoice` zeigen vorn zwei Antwortschaltflächen. Die Auswahl
bewertet die Antwort, dreht zur Erklärung und lässt das Ergebnis sichtbar, bis
die Person auf Weiter tippt. Ein Wisch darf eine ausgewählte Antwort nicht
überschreiben.

Das Deck verwendet ein `DragGesture(minimumDistance: 0)`. Eine Bewegung unter
zehn Punkten beim Loslassen dreht die Karte um. Nicht durch ein eigenes
Tap-Gesture ersetzen, weil SwiftUI sonst das Umdrehen blockieren kann.

Die ganze Karte dreht sich als Einheit. `FlipRotation` wechselt die Seite bei
90 Grad, wenn die Karte nur von der Kante zu sehen ist. Beide Seiten bleiben
innerhalb von `SkatCardFace`, damit Rahmen, Wasserzeichen und Text bei der
Drehung zusammenbleiben.

Modell und Inhalte bleiben möglichst unabhängig vom einzelnen Raum.
Kartendarstellung gehört in `PlayingCardView`; diese Ansicht verwaltet Gesten,
Bewertung und Deck-Zustand.
