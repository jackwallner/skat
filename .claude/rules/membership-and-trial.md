---
paths:
  - "Shared/Services/SubscriptionService.swift"
  - "Shared/Services/ProgressStore.swift"
  - "SkatTrainer/Views/OnboardingView.swift"
  - "SkatTrainer/Views/PaywallView.swift"
  - "SkatTrainer/Views/HowToPlayView.swift"
  - "SkatTrainer/Views/FeatureTourView.swift"
  - "SkatTrainerTests/TrialCopyTests.swift"
  - "SkatTrainerTests/TrialEligibilityTests.swift"
  - "SkatTrainerTests/PaywallFunnelTests.swift"
---

# Skat Trainer: membership, the trial flow and fit

Skat+ (entitlements `Skat+` and `pro`, any active one unlocks). Prices are read
live from StoreKit through RevenueCat (`PaywallPricing`); never hardcode one
anywhere. The German storefront once saw an invented "$9.99 / Jahr", which is
why there is no fallback amount.

**Trial flow, structurally Mahj 1.3.2.** Onboarding trial page: soft "Loslegen"
exit above the primary, primary CTA in the exact "Weiter" slot, one tap buys
the MONTHLY trial, Apple confirms. The page title is "Skat+ freischalten", never
"kostenlos testen": App Review 3.1.2(c) rejected a headline that made the free
trial louder than the billed amount. The billed amount is the most prominent
price (26pt bold, on the trial page and in the paywall footer) with the small
disclosure under it. The onboarding disclosure is
`OnboardingView.trialDisclosure(amount:)` ("Abrechnung: ..., inklusive 7 Tagen
kostenlos. Verlängert sich automatisch, bis du kündigst.") and must always name
the plan the CTA buys; the paywall uses `PaywallPricing.terms`. Backing out of
Apple's sheet is `PurchaseOutcome.cancelled`, never an error and never another
paywall. A member reaching the trial page (reinstall, second device) sees
"Weiter" and goes straight to the tour. The trial end date is not shown
anywhere; Settings shows "Abonnement verwalten" only when there is an
expiration date (not for lifetime). Only the button wording varies, via
`TrialCTA` offering metadata; any other change to this flow needs Jack's
go-ahead.

The five benefit rows follow Mahj 1.3.2 (Jack, 2026-10-21): free beginner
rooms first, then the paid Minute and a personalized Game Night Prep, then
Endless Practice, Fix My Mistakes and the extra sets. Mahj 1.4.1 rewrote
rows 2 and 4 because its Minute went free; here the Minute is still paid,
so the 1.3.2 wording holds. Drop the Minute from row 2 if it ever goes free. The paywall CTA stays disabled until StoreKit returns a price, which
includes every simulator run (RevenueCat is never configured there).

**Intro-offer eligibility (2026-10-20, Mahj fc6b7ed).** Apple gives one free
week per subscription group, so a lapsed member is charged on day one.
`SubscriptionService.isTrialEligible(for:)` asks StoreKit (no product reads as
eligible, as before). The onboarding trial page and `PaywallView` load it and,
when it is false, drop every free-week line: the CTA "Skat+ abonnieren", the
plan cards "Jährliche Abrechnung. Verlängert sich automatisch." / "Monatliche
Abrechnung. ...", and `PaywallPricing.terms(..., trial: false)` /
`OnboardingView.trialDisclosure(amount:trial: false)` ("Abrechnung: X, heute
berechnet. Verlängert sich automatisch ..."). The onboarding title is already
trial-free. The billed amount stays the largest price. A purchase tap re-checks
eligibility after offerings load and, if it changed, redraws and returns without
buying. `TrialEligibilityTests` runs against `SkatTrainer.storekit`; its
lapsed-account half is left out because `Product.purchase` hangs on the gh-sim
runner. The eligible copy is unchanged.

**Membership state.** `membershipResolved` is false until a customer record was
read (cache or network); nothing may treat "not a member" as a lapse or sell a
trial before it. A reinstall is a new anonymous RevenueCat user:
`recoverReinstalledMembershipIfNeeded` syncs once per install when StoreKit owns
an entitlement, and `ensureOfferings` (so every purchase) waits for it (3s cap).
`startedTrial` comes from the purchased entitlement's `periodType`, not the
product. `confirmEntitlement` fetches a fresh record. Simulators keep the
early return in `configureIfNeeded`: never configure the production `appl_` key
there.

**Fit.** Every fix is conditional on fit or text size, never on device. At
accessibility sizes the onboarding pages, the primer and the tour put the page
in a ScrollView with the buttons pinned below; Home and the room grid drop to
one column, the Skat+ badge stacks under the title and the room icon tile
hides; the trial page keeps the designed layout below AX sizes. The primer's
hand row takes the largest of 46/40/36/32pt that fits. Home's header stacks the
chips under the title on compact widths (no gear collision), and the toolbar
keeps its system background. Dark mode uses `Theme.onFill` on filled buttons
and `Theme.goldText` for small gold text. `Theme.display` scales with Dynamic
Type, capped at 1.6x.

**What's New mechanics.** `WhatsNew.currentRelease` is the newest entry at or
below the running version, so a build with no entry of its own still carries
the last notes once to a player who skipped a version. It is marked seen when
shown, and `shownThisLaunch` delays ATT to the next launch.
