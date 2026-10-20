# Skat Trainer: UI findings (2026-10-20)

Captured on an iPhone 17 simulator (iOS 27) through gh-sim with `AuditCaptureTests` (`SkatTrainerScreenshots/AuditCaptureTests.swift`), Skat+ override on, What's New suppressed.

## Inspected

- Wer sticht? after a miss: the red "Warum nicht" card names the losing card and the trump that beats it, the gold card gives the winner and the Augen. Reads clearly, answer row stays unfaded.
- Spitzen zählen after a miss: note explains mit/ohne from the Kreuz-Bube; explanation shows the run.
- Stats: new Beherrschung card lists all five rooms with "x von n gefestigt" and a level word; accuracy bars below unchanged.
- Largest accessibility text (AX XXL) on Handmuster lesen: text wraps and scrolls, Weiter stays reachable. The auto-scroll to the explanation hides the question while reading it, which is existing behaviour; acceptable but worth a follow-up (scroll to the top of the note cards instead of the bottom).

## Personas

- Beginner: Endless is Skat+, but Kurzrunde, rooms and mastery chips are free. Mastery says "Neu" until a room has locked-in answers, which avoids a discouraging 0 percent ring.
- Experienced player: new Wer sticht / Spitzen / Augen skills, notes that explain the specific miss, Zeitprüfung now mixes five skills.
- Returning player: Fix My Mistakes, due badge and mastery lapse (a full interval past due) are unchanged and tested.
- Larger text: checked at AX XXL. Reduced motion: not checkable here (no launch override for Reduce Motion exists in XCUITest); the new views add no new animation.

## Capture limitations

No native 60 fps recording was possible: this machine has no simulator, and gh-sim UI tests return screenshots only. No video or frame-cadence report exists; `video_reports` is omitted from the receipt rather than faked. Transition quality of the pager was not changed in this work.
