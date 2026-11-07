# Project documentation

Developer notes and historical audits for this repository. The published site remains in the docs directory.

## Audits

- [audit823.md](audits/audit823.md): Skat Trainer audit823
- [ios27SkatTrainer.md](audits/ios27SkatTrainer.md): iOS 27 compatibility audit: Skat Trainer
- [mahj-parity-audit-2026-10-20.md](audits/mahj-parity-audit-2026-10-20.md): Mahj-inspired gap audit and what shipped
- [mahj-parity-ui-findings-2026-10-20.md](audits/mahj-parity-ui-findings-2026-10-20.md): persona UI walkthrough
- [state-machines-2026-11-06.md](audits/state-machines-2026-11-06.md): state machine audit (5 bugs, 4 proved by test) with repro suite `state-machines-2026-11-06-repro.swift`
- [state-machines-2026-11-06-review.md](audits/state-machines-2026-11-06-review.md): independent review of that audit (1 confirmed, 3 minor, 1 unverified, 0 false positives)
- [state-machines-2026-11-06-fixes.md](audits/state-machines-2026-11-06-fixes.md): fixes for that review after the verify (5 fixed, 3 held for Jack, 0 skipped), all tests green
- [state-machines-2026-11-06-verify.md](audits/state-machines-2026-11-06-verify.md): independent check of the second fixes pass (PASS: B1, P8, B3, B4, B5 fail without their fixes, suite green, B2 and G1 back at base)

## Releases

- [1.2.3-content.md](releases/1.2.3-content.md): contextual expert content and reviewer response.

## ASO

- [2026-10-28-aso-pass.md](aso/2026-10-28-aso-pass.md): US and German App Store metadata audit and updates.

## Marketing

- [tiktok-kit/](marketing/tiktok-kit/): German TikTok slideshow kit and 5 animated shorts (ports of the Mahj kit and shorts engine); renders into iCloud `Skat TikTok Kit/`.
