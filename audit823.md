# Skat Trainer audit823

Audit date: 2026-08-23

Scope: Skat Trainer only, repository `/Users/jackwallner/skat`.

Purpose: identify improvements to downloads, trial starts, paid conversion, activation, ratings, ongoing user experience, release safety, and agent-facing repository organization.

This is a fresh max-reasoning rerun. The audit is read-only with respect to the app, ASC, RevenueCat, the App Store, and the websites. The only file written by this task is this audit. No app code, project configuration, ASC setting, RevenueCat setting, notification, commit, or push was changed.

## Executive assessment

Skat Trainer is shipped and locally coherent at bundle ID `com.jackwallner.skat`, App Store ID `6796913722`, version `1.2.2`, build 30. The product has a strong free activation loop, a clear German positioning, four free practice rooms, an offline-first experience, and a deliberately gated Skat+ catalog.

The highest-risk area is paid conversion health, not the existence of products. RevenueCat currently shows approved, fetchable products, but the production overview for 2026-07-27 through 2026-08-23 showed one active trial, zero active subscriptions, zero MRR, and zero revenue. Recent transactions showed a trial cancellation and a trial ending. This is a small sample and is not proof of a broken purchase flow, but it is enough to make a real-device production purchase and trial investigation the first operational task.

The most important structural issues are:

1. The simulator purchase path turns any purchase into a local success and never configures RevenueCat. This can make every local paywall test pass while production products, offerings, entitlement mapping, and restore behavior are broken.
2. `AGENTS.md` and `CLAUDE.md` are separate files with different authority. The short `AGENTS.md` points to the full `CLAUDE.md`, but this relies on every agent client following a cross-file pointer consistently.
3. Release and ASO tooling contains old prices and old versions. Some scripts can still be run to publish stale prices or stale metadata.
4. The website's structured data claims a 5.0 rating from one review while the public App Store listing says it does not have enough ratings or reviews to display an overview. The site also advertises version 1.2.0 and iPhone-only support while the live app is 1.2.2 and supports iPad.
5. The trial is offered after five onboarding pages and before the user completes a real free exercise. This is the main activation and trial-start experiment to run.
6. There is no crash, hang, or purchase-regression watchdog in the repository. ASC and RevenueCat provide useful read-only surfaces, but there is no automated release-window alerting or in-app error funnel.

## Priority key

- P0: investigate immediately because a live revenue or release-health failure may be present.
- P1: high-impact issue that should be resolved before the next material release or acquisition push.
- P2: meaningful conversion, measurement, or UX improvement.
- P3: hygiene, polish, or lower-risk optimization.

Evidence labels used below:

- Evidence: directly observed in local source/config or a read-only live console/storefront check.
- Inference: a plausible interpretation that requires a product or data check before being treated as fact.
- Recommendation: proposed action, not an observed defect.
- Not observed: the relevant surface was available but no value was visible in this read-only pass.

## Current identity and status

| Item | Evidence | Assessment |
| --- | --- | --- |
| Product | `Skat Trainer` | German Skat learning and practice app. |
| Bundle ID | `project.yml`, `SkatTrainer/Info.plist`: `com.jackwallner.skat` | Consistent locally. |
| App Store ID | `CLAUDE.md`, `Shared/Services/ReviewPromptTracker.swift`, live ASC: `6796913722` | Consistent locally and live. |
| Local version | `project.yml`: marketing version `1.2.2`, build `30` | Current local release identity. |
| Live version | ASC app list and public App Store: `1.2.2`, `Ready for Distribution` | Live at audit time. |
| Deployment | `project.yml`: iOS 17.0, Swift 6.0, iPhone and iPad | Consistent with the live listing's device support. |
| UI language | `project.yml`: German development language and region; public listing language: German | Do not assume that 50 metadata locales equal 50 localized acquisition experiences. |
| Architecture | XcodeGen project, SwiftUI, Swift 6, RevenueCat SPM from 5.72.0 | Source is organized around views, stores, services, and content libraries. |
| Git state before this audit | `main`, clean, latest commit `79c9e21` | No pre-existing `audit823.md` was present. |

The public listing observed at `https://apps.apple.com/us/app/skat-trainer-learn-skat/id6796913722` showed:

- title `Skat Trainer: Learn Skat`
- subtitle `Learn Skat, Hand by Hand`
- free download with in-app purchases
- Education category, age 4+, German language
- iOS 17 or later, iPhone and iPad support
- version 1.2.2
- the message that the app has not received enough ratings or reviews to display an overview

The public App Store page did not expose reliable download, trial, or conversion counts in this pass. ASC analytics navigation exposed acquisition, monetization, subscription, cohort, retention, benchmark, and app-usage surfaces, but no numeric values were visible in the loaded page. Treat those values as unknown until exported from ASC.

## 1. Agent documentation and source-of-truth

### Observed state

`/Users/jackwallner/skat/AGENTS.md` is a regular eight-line file, not a symlink. It says that the binding rules are in `CLAUDE.md`, identifies the bundle ID, requires the `agent-skat` simulator, German visible text, RevenueCat simulator protection, `xcodegen generate`, and relevant tests.

`/Users/jackwallner/skat/CLAUDE.md` is the full 163-line project guide. It contains the product identity, simulator and signing rules, App Store ID, StoreKit product IDs and prices, RevenueCat entitlements, free and paid content boundaries, review funnel rules, screenshot commands, and release conventions.

`/Users/jackwallner/skat/SkatTrainer/Views/Drills/CLAUDE.md` is a nested guide for the drill subtree. It should remain an addendum, not a second root source of truth.

`README.md` is a human-facing setup and release document. It currently contains stale version information and should not be treated as binding agent policy.

`archive/README.md` explicitly describes the archive as historical. Archived readiness notes should not be automatically loaded as current instructions.

### Why the current split is unsafe

The pointer in `AGENTS.md` is useful to a human, but it is not an enforceable include. Claude Code conventionally discovers `CLAUDE.md`. Codex and other agent harnesses commonly discover `AGENTS.md`. Cursor may be configured to discover repository instruction files, but it should not be assumed to follow a prose pointer with the same precedence as a native instruction file.

This creates several failure modes:

- A Codex session may load only the short `AGENTS.md` and miss product, purchase, and release rules.
- A Claude session may load `CLAUDE.md` plus a separate global or repository `AGENTS.md` and have to resolve precedence between them.
- A Cursor session may load one file based on its project configuration and omit the other.
- A code review can update one file while leaving the other pointer or nested assumptions stale.
- A new agent can mistake `README.md` or an archived readiness document for a current release source.

### Recommended canonical hierarchy

Use one root instruction file and make compatibility paths resolve to the same bytes:

```text
/Users/jackwallner/skat/CLAUDE.md                         canonical root agent rules
/Users/jackwallner/skat/AGENTS.md -> CLAUDE.md            compatibility symlink
/Users/jackwallner/skat/SkatTrainer/Views/Drills/CLAUDE.md subtree addendum
/Users/jackwallner/skat/README.md                         human setup and product guide
/Users/jackwallner/skat/archive/                         historical material only
```

This recommendation follows the current fleet convention that root `CLAUDE.md` is the full project guide. If the fleet standard later chooses `AGENTS.md` as canonical, invert the symlink once, but never maintain two independent instruction bodies.

The root guide should contain an explicit precedence section:

1. Root canonical agent rules.
2. Nested `CLAUDE.md` addenda for files below their directory.
3. Executable project configuration and scripts for build and product identifiers.
4. Current README documentation for human workflow.
5. Archive documents are historical and never override current files.

The root guide should also contain a small discovery contract that each client can follow:

- Cursor: load repository agent instructions, then verify they resolve to the root canonical file.
- Claude Code: load root `CLAUDE.md`, then any nested `CLAUDE.md` below the working file.
- Codex: load root `AGENTS.md`, which must resolve to the same canonical content, then nested rules.

### Acceptance test for the documentation fix

From each Cursor, Claude, and Codex environment, start a fresh session in `/Users/jackwallner/skat` and ask it to report, without reading app source first:

- bundle ID
- App Store ID
- canonical instruction file path
- simulator name
- whether production RevenueCat may be used on the simulator
- required post-change validation commands

The three answers should match. Add a CI or preflight check that fails if `AGENTS.md` and `CLAUDE.md` are both regular files with different content.

## 2. Local source and configuration

### Build and packaging

Evidence from `project.yml`:

- XcodeGen is the project source.
- Deployment target is iOS 17.0.
- Swift version is 6.0.
- Bundle ID is `com.jackwallner.skat`.
- Version is 1.2.2, build 30.
- iPhone and iPad are targeted.
- The main `SkatTrainer` scheme attaches `SkatTrainer/SkatTrainer.storekit`.
- The unit test target is `SkatTrainerTests`.
- A separate `Screenshots` scheme exists.
- RevenueCat SPM is sourced from `https://github.com/RevenueCat/purchases-ios-spm.git`, from version 5.72.0.

`SkatTrainer/Info.plist` linted successfully. `SkatTrainer/SkatTrainer.storekit` is JSON StoreKit configuration, not an XML plist. A plist validator rejects it because of its format, so validation must use a JSON parser or Xcode's StoreKit tooling rather than `plutil -lint`.

`SkatTrainer/SkatTrainerApp.swift` creates subscription, progress, settings, and routing state objects. It calls `subscriptions.start()` and records an app launch. `RootView.swift` uses `progress.hasOnboarded` to choose onboarding versus home. `AppRouter.swift` owns the local notification delegate and game-night route.

### Product structure

`Shared/Content/DrillLibrary.swift` defines four free rooms, each with two free drills and additional `isPlus` drills, plus a locked Meistertisch room. `HomeView.swift` exposes a free Quick Session and routes locked rooms, drills, Endless, Skat Minute, Game Night, 90 seconds, and error review to the paywall when the user is not pro.

`Shared/Content/SessionBuilder.swift` builds quick and game-night sessions. `QuickSessionView.swift` is the primary first-run free activation path. `PracticeRunView.swift` handles generated, timed, and review runs. `PracticeRecordStore.swift` persists spaced-repetition and practice history locally.

This is a good value structure for conversion: a user can experience real play before paying, while paid content expands repetition and depth. The current onboarding does not use that free value moment early enough.

## 3. App Store acquisition and metadata

### Metadata validation

`python3 scripts/validate_metadata.py` passed:

```text
Metadata valid: 50 locales, limits and fallback fields present
```

The `fastlane/metadata` tree contains 50 locale folders plus `review_information`. Every expected locale has name, subtitle, keywords, description, promotional text, release notes, support URL, marketing URL, and privacy URL.

The current en-US fields are:

- Name: `Skat Trainer: Learn Skat`
- Subtitle: `Learn Skat, Hand by Hand`
- Keywords: `skat,cards,german card game,learn,bidding,trump,grand,null,discard,tricks,quiz,strategy,rules`
- Description: explains the free app, seven-day trial, paid plans, and regional pricing.

The current de-DE fields are:

- Name: `Skat Trainer: Skat üben`
- Subtitle: `Skat lernen, Runde für Runde`
- German description and release notes.

### Acquisition issues and opportunities

#### ASO-01, metadata coverage is wider than product localization, P2

Evidence: ASC metadata has 50 locale folders, while the live listing reports German as the app language and the local project uses German as its development language.

Inference: many localized metadata entries may be useful for indexing but can reduce conversion if screenshots, landing pages, and the in-app experience remain German. Metadata translation alone is not a localized funnel.

Recommendation:

- Treat de-DE, de-AT, de-CH, and other German-speaking regions as the primary conversion cohort.
- Keep other locales only where the title, subtitle, keywords, description, screenshots, and support experience are genuinely localized.
- If English acquisition is intentional, test a fully English onboarding and screenshot path rather than relying on English metadata over a German UI.
- In ASC, compare impressions, product-page views, downloads, and trial starts by storefront and metadata locale before expanding localization.

#### ASO-02, no current search and page-conversion baseline, P2

Evidence: ASC acquisition surfaces were available, but numeric values were not visible in this read-only pass. Product Pages and In-App Events were shown as disabled.

Recommendation:

- Export the last 28 and 90 days for impressions, product-page views, downloads, redownloads, proceeds, and conversion by source.
- Segment by Germany, Austria, Switzerland, the United States, and other locales with enough traffic.
- Establish the baseline before changing title or subtitle.
- Create custom product pages only after the current listing has a baseline. Candidate pages are beginner learning, tournament practice, and game-night preparation.
- Test one message at a time: `learn Skat`, `improve bidding`, `practice in 90 seconds`, or `prepare for game night`.

#### ASO-03, the metadata generator can reintroduce old prices, P1

Evidence: `scripts/generate_metadata_all.py` explicitly warns that it is stale, but it still contains old price strings such as `$1.99`, `$9.99`, and `$29.99`. `docs/research/aso-skat.md` also uses old prices. The current project guide and local product configuration describe $6.99 monthly, $29.99 yearly, and $69.99 lifetime.

Inference: a release operator following the README and running the generator can overwrite currently correct metadata with inaccurate pricing.

Recommendation:

- Make the generator fail closed until its source data is updated.
- Remove hardcoded price claims from generated copy, or generate only from a versioned pricing source with explicit storefront and currency.
- Add validation that rejects old prices, stale version values, mismatched App Store IDs, and non-canonical URLs.
- Add a test that runs generation into a temporary directory and compares the result with the checked-in metadata.

#### ASO-04, current ASO research is useful but stale, P1

Evidence: `docs/research/aso-skat.md` is marked final and dated 2026-08-01, but its pricing section uses the old $1.99, $9.99, and $29.99 values. Its claim that the generator is reproducible conflicts with the generator's own stale warning.

Recommendation: retain the research as historical context, add a current version, and label every price, ranking, keyword, and competitor observation with storefront and observation date.

## 4. Website, legal pages, and consistency

### Live website evidence

Both of these URLs served the Skat Trainer landing page during the read-only check:

- `https://jackwallner.github.io/skat/`
- `https://jackwallner.com/ios/skat/`

The landing page has a clear App Store CTA, six screenshots, four practice-room explanations, Skat+ positioning, offline messaging, and no-account/no-cloud messaging. It describes the product as a German practice app and links privacy, terms, and support pages.

### WEB-01, unsupported structured-data rating, P1

Evidence: `docs/index.html` contains JSON-LD `aggregateRating` with `ratingValue` 5 and `ratingCount` 1. The public App Store listing says the app has not received enough ratings or reviews to display an overview.

This is the clearest web trust issue in the audit. Even if the rating came from a legitimate source, it is not currently consistent with the public store's visible social proof.

Recommendation:

- Remove the aggregate rating until it is sourced from an authoritative, current rating feed.
- If a rating is retained, display the source, storefront, count, and last-updated date and ensure the landing page is not implying App Store review volume that the store does not support.
- Add a link-check and schema consistency test to release validation.

### WEB-02, stale version and device claims, P1

Evidence:

- `docs/index.html` JSON-LD has `softwareVersion: "1.2.0"`.
- The live app and `project.yml` are version 1.2.2.
- The page says `iPhone · Four Practice Rooms · Offline nutzbar`.
- The project and live listing support iPhone and iPad.

Recommendation: derive the website version and device claims from the release source or update them as part of the release checklist. The short claim should say iPhone and iPad if both are supported.

### WEB-03, canonical URL mismatch, P1

Evidence: local `docs/index.html` canonical and Open Graph URLs point to `https://jackwallner.com/ios/skat/`, while App Store metadata and the GitHub Pages deployment use `https://jackwallner.github.io/skat/`. Both were reachable and showed the same page.

Inference: search engines and link previews may split canonical signals, and future edits may update one host but not the other.

Recommendation:

- Choose one canonical public URL.
- Make the other host redirect to it.
- Use the chosen host consistently in canonical, Open Graph, JSON-LD, App Store marketing URLs, and support links.
- Add a CI check that fetches both URLs and verifies one redirect target and matching legal links.

### WEB-04, fixed global prices in schema, P2

Evidence: the landing page JSON-LD uses fixed USD offers for monthly, yearly, and lifetime products. The app's paywall uses localized live product prices and the store description says prices vary by region.

Recommendation: avoid presenting fixed USD prices in global structured data unless the page is explicitly US-only. Prefer `priceCurrency` and amounts from an authoritative current source, or describe prices as shown in the app.

### WEB-05, duplicated legal pages, P2

Evidence: `docs/privacy-policy.html` and `docs/privacy-policy/index.html` contain the same privacy content with different relative links. Terms has the same duplication. The live privacy, terms, and support pages load successfully.

Recommendation: keep one source document and generate the pretty URL mirror, or redirect the duplicate. Add a content hash or link test so the two copies cannot drift.

### Legal and support assessment

The in-app paywall links to the Apple standard EULA and the repository's privacy page. The legal pages are dated 2026-08-17 and cover subscription cancellation, restore, support, and the App Store standard terms. This is broadly consistent with the purchase flow.

Per request, this audit does not treat RevenueCat purchase or anonymous entitlement data as an App Privacy disclosure inconsistency. That separate privacy review is out of scope here.

The support page would be more useful for purchase and crash triage if it asked users to include:

- app version and build
- iOS version and device model
- paywall source
- product selected
- approximate time of failure and storefront
- a copyable error code, if available

## 5. Onboarding and activation

### Current flow

Evidence from `SkatTrainer/Views/OnboardingView.swift`:

1. A fresh install enters onboarding because `RootView.swift` sees `progress.hasOnboarded == false`.
2. The `TabView` presents three value pages, a skill-level page, and a trial page.
3. `ensureOfferings` is called on every onboarding page.
4. The onboarding paywall impression is tracked once per session with ID `skat_onboarding_trial`.
5. The trial screen offers a monthly package only.
6. If the monthly package cannot be loaded, the flow presents the full custom paywall as a fallback.
7. A successful purchase starts the primer or feature tour.
8. The free `Loslegen` action on the trial page also starts the tour.
9. Finishing the primer or tour writes the onboarding baseline and `progress.hasOnboarded`.

The main free value path is elsewhere: `HomeView.swift` exposes `QuickSessionView`, which gives a short free practice session and records progress.

### UX-01, trial appears before a real free value moment, P1

Evidence: onboarding presents five pages and a trial CTA before the user completes a Quick Session or drill. The free Quick Session exists but is reached only after onboarding.

Inference: the user is being asked to evaluate a subscription before experiencing the product's strongest proof of value. This may reduce both onboarding completion and trial starts.

Recommendation: test a free-first sequence:

1. Explain the product briefly.
2. Let the user complete one short Quick Session or a representative drill.
3. Show immediate result feedback and a clear next-step value.
4. Present the trial or paid upgrade in the context of the content the user just tried.

Keep the current five-page flow as a control. Do not decide from paywall conversion alone. Measure activation and retained trial starts together.

### UX-02, skill selection adds a required step, P2

Evidence: the skill page requires a selection before progressing. Options are new, basics, and played.

Recommendation: test a default or skip path. Keep the selection for personalization only if it changes content or messaging. If it does not change the first session, make it optional and collect it after the first value moment.

### UX-03, onboarding and full paywall have different plan architecture, P1

Evidence:

- onboarding selects monthly and uses `7 Tage kostenlos starten`.
- `PaywallView.swift` defaults to yearly and presents yearly, monthly, and lifetime plans.
- onboarding has no plan cards before purchase.

Inference: users entering through onboarding and users entering through a locked feature receive different anchors, plan choices, and likely different conversion behavior. This makes the funnel harder to interpret and can create a mismatch when a user sees monthly first and yearly later.

Recommendation: test these deliberately:

- onboarding monthly-only versus all plans with yearly recommended
- yearly-first versus monthly-first
- lifetime shown as a clear alternative versus an anchor card
- the same paywall component after free value versus a dedicated onboarding paywall

Record the source and selected plan for every attempt.

### UX-04, product loading failure can present an unready CTA, P1

Evidence: the onboarding and custom paywall have placeholder price states such as `Preis wird geladen …`. The purchase CTA remains present, and `purchase(nil)` later produces a generic products-unavailable error. `ensureOfferings` errors are swallowed.

Recommendation:

- Disable the purchase CTA until the selected package has a valid localized price.
- Provide a visible retry action and an offline explanation.
- Keep restore available when it can work, but distinguish no network, product unavailable, and no previous purchase.
- Log product-load failure by paywall source and app version.

### UX-05, free escape should be tested for visibility and accessibility, P2

Evidence: `Loslegen` is available only on the onboarding trial page and the layout reserves the CTA area even when the free path is not shown. The current layout uses opacity and conditional content.

Recommendation: validate the free path with Dynamic Type, VoiceOver, landscape iPad, small iPhone widths, and reduced motion. Ensure the free action is discoverable without visually competing with the paid CTA.

### Activation events to measure

At minimum, measure these transitions by app version, storefront, onboarding variant, and skill selection:

- onboarding shown
- each page completed
- skill selected
- free path selected
- first Quick Session started
- first drill completed
- first correct answer or first completed room
- trial paywall shown
- trial CTA tapped
- trial started
- onboarding completed
- second session within 24 hours
- third positive practice moment

The current app has local progress and review tracking, but no evidence of this complete activation funnel being exported.

## 6. Purchase, trial, and entitlement flow

### Current implementation

`Shared/Services/SubscriptionService.swift`:

- hardcodes the public RevenueCat App Store key and protects the simulator with `#if targetEnvironment(simulator)`.
- starts RevenueCat on device, refreshes customer info, and loads offerings.
- maps monthly, yearly, and lifetime plans to current offering packages.
- calls `trackCustomPaywallImpression` with a paywall ID.
- purchases a selected package and polls entitlement confirmation three times at 1.2-second intervals.
- supports restore.
- treats any active entitlement as pro: `!info.entitlements.active.isEmpty || override`.

`SkatTrainer/SkatTrainer.storekit` and `CLAUDE.md` describe monthly, yearly, and lifetime products with seven-day trials on subscription products. `scripts/verify-store-config.py` was run read-only and reported:

```text
$rc_annual   -> com.jackwallner.skat.yearly   APPROVED
$rc_lifetime -> com.jackwallner.skat.lifetime APPROVED
$rc_monthly  -> com.jackwallner.skat.monthly APPROVED
OK: 3 packages, every product fetchable
```

### PAY-01, production conversion needs immediate investigation, P0

Evidence from the production RevenueCat dashboard, project `e0bf13d7`, 28-day window 2026-07-27 through 2026-08-23, production mode:

| RevenueCat metric | Observed value |
| --- | ---: |
| Active trials | 1 |
| Active subscriptions | 0 |
| MRR | $0 |
| Revenue | $0 |
| New customers | 18 |
| Active customers | 31 |

The recent transaction list showed one German Skat+ monthly customer purchased three days earlier, expiring in four days, with `Trial Canceled`, and one German Skat+ yearly customer purchased 13 days earlier, expired six days earlier, with `Trial Ended`.

Inference: this could be a low-volume sample, a legitimate lack of conversion, a product/trial configuration issue, an entitlement mismatch, a reporting delay, or a failed user experience. It must not be interpreted as a confirmed outage without ASC sales/subscription data and a real purchase trace.

Immediate validation:

1. Export ASC sales and subscription reports for App Store ID `6796913722` and compare product identifiers with RevenueCat.
2. Confirm that the monthly and yearly products have the intended seven-day introductory offer in the live storefronts.
3. Execute one real device Sandbox purchase for monthly, yearly, lifetime, cancel, and restore.
4. Capture the exact sequence from package load through entitlement confirmation.
5. Compare the transaction's entitlement IDs to both `pro` and `Skat+`.
6. Check whether the zero-revenue window is expected because all customers are still trialing or because purchases are not entering RevenueCat.

Do not change pricing or entitlement configuration until this reconciliation is complete.

### PAY-02, simulator success masks production failures, P1

Evidence: `SubscriptionService.configureIfNeeded()` returns before configuring RevenueCat on the simulator. The simulator purchase path calls `setLocalOverride(isPro: true)` and returns purchased, including when the package is nil. The attached StoreKit configuration therefore does not exercise the same product and entitlement path as a device build.

Impact:

- product identifiers can be wrong while local tests still pass
- offerings can be unavailable while purchase appears successful
- restore and trial transitions are not tested realistically
- RevenueCat entitlement mapping errors are invisible in local smoke tests
- a broken production paywall can be approved by the current simulator workflow

Recommendation:

- Keep the production RevenueCat key out of simulator runs.
- Add a separate deterministic StoreKit test path that does not fake a successful purchase.
- Add injectable purchase outcomes for unavailable products, cancellation, pending purchase, transaction success without entitlement, restore success, restore failure, and network timeout.
- Require one device Sandbox or TestFlight validation before a monetization release.
- Add a review checklist item that a simulator local override is not evidence of a production purchase success.

### PAY-03, entitlement allowlist should be explicit, P2

Evidence: `apply(_:)` sets `isPro` when any active entitlement exists. The repository has both `pro` and `Skat+` entitlements.

Inference: a customer with an unrelated future or legacy entitlement could receive Skat+ access if that entitlement is active in the same RevenueCat project.

Recommendation: allowlist the intended identifiers, for example `pro` and `Skat+`, and add a unit test proving that an unrelated active entitlement does not unlock the app. Confirm the exact canonical identifier casing in RevenueCat before implementation.

### PAY-04, errors are not observable enough, P1

Evidence: offerings and customer-info refresh errors are frequently swallowed with `try?`. The paywall has user-facing error text but no visible evidence of a structured event for package load, purchase start, cancellation, purchase failure, entitlement timeout, or restore result.

Recommendation: retain friendly German copy but classify errors into stable, non-PII categories:

- offerings unavailable
- package unavailable
- user cancelled
- network unavailable
- StoreKit product error
- purchase pending
- purchase succeeded but entitlement pending
- restore found nothing
- restore failed

Include app version, build, storefront, paywall source, and product ID only in internal diagnostics. Never include receipt, email, or raw customer identifiers in a client event.

## 7. RevenueCat configuration and measurement

### Live configuration evidence

RevenueCat showed:

- one active `default` offering named `Skat+`
- monthly, yearly, and lifetime packages
- all three App Store products approved and attached
- `Skat+` and `pro` entitlements
- no configured RevenueCat Paywall
- no experiments
- no funnels
- analytics categories for paywall encounters, conversion, trial conversion, retention, and cohorts

The product catalog appears structurally complete. The absence of native paywalls, experiments, and funnels means the current custom SwiftUI flow is doing all presentation and much of the measurement work.

### Existing paywall measurement

`SubscriptionService.trackPaywallImpression` calls RevenueCat's custom paywall impression API. It is used by:

- `OnboardingView.swift`: `skat_onboarding_trial`
- `PaywallView.swift`: the source values `skat_paywall_sheet`, `skat_onboarding_fallback`, `skat_home_sheet`, `skat_settings_sheet`, and `skat_room_sheet`

This is a useful starting point, but an impression alone cannot explain the zero-conversion snapshot.

### Proposed RevenueCat custom attributes

No RevenueCat custom-attribute calls were found in the local source. Add only low-cardinality, non-PII state attributes. These should describe the current customer context, not act as a high-volume event log.

| Attribute | Values | Set or update at |
| --- | --- | --- |
| `app_version` | `1.2.2` | configured startup |
| `build` | `30` | configured startup |
| `device_family` | `iphone`, `ipad` | configured startup |
| `skill_level` | `new`, `basics`, `played` | onboarding selection |
| `onboarding_completed` | `true`, `false` | onboarding completion |
| `paywall_source` | `onboarding`, `home`, `room`, `settings`, `fallback` | paywall presentation |
| `trial_surface` | `onboarding`, `locked_room`, `locked_drill`, `release_note` | trial entry |
| `selected_plan` | `monthly`, `yearly`, `lifetime` | plan selection or purchase start |
| `first_value_completed` | `true`, `false` | first Quick Session or drill completion |
| `completed_sessions_bucket` | `0`, `1`, `2-3`, `4-9`, `10+` | session completion |
| `last_room` | stable room identifier | room completion |
| `last_drill_kind` | stable drill kind | drill completion |
| `review_prompt_state` | `not_eligible`, `eligible`, `deferred`, `feedback`, `review_link_opened` | review funnel transitions |

Set attributes through the current RevenueCat attribution API after RevenueCat is configured. Do not set names, emails, device identifiers, exact free-form text, or per-answer data. If a value changes frequently, use an analytics event instead.

### Proposed event schema

Use RevenueCat's paywall impression mechanism for impressions and a suitable analytics or diagnostics sink for events. Do not assume RevenueCat custom attributes are an event stream.

Required event names and properties:

```text
paywall_impression       source, placement, app_version, build
paywall_cta_tapped       source, selected_plan
offerings_load_started   source
offerings_load_succeeded source, package_count
offerings_load_failed    source, error_class
purchase_started         source, product_id, selected_plan
purchase_cancelled       source, product_id
purchase_failed          source, product_id, error_class
purchase_pending         source, product_id
purchase_succeeded       source, product_id
entitlement_confirmed    source, entitlement_id, confirmation_latency_bucket
entitlement_timeout      source, product_id
restore_started          source
restore_succeeded        source
restore_empty            source
restore_failed            source, error_class
trial_started             source, product_id
trial_cancelled          product_id, days_since_start_bucket
trial_converted          product_id
```

The event properties should be stable, enumerated, and free of PII. Add a schema version so the later watchdog can compare releases.

## 8. Paywall UX and A/B test backlog

### Current custom paywall

`SkatTrainer/Views/PaywallView.swift` is a custom SwiftUI paywall. It:

- defaults to yearly selection
- presents yearly, monthly, and lifetime plan cards
- shows live localized product prices
- shows an annual per-month equivalent and savings badge
- includes four benefits
- includes restore, Apple standard EULA, and privacy links
- tracks a custom paywall impression
- calls `ensureOfferings` on task start
- polls entitlement confirmation after purchase

The CTA copy is `7-Tage-Test starten` for subscriptions and `Skat+ dauerhaft freischalten` for lifetime. The onboarding paywall uses a different, monthly-only flow.

### Native RevenueCat paywall status

RevenueCat's Paywalls page showed `No paywalls yet`, and the Experiments page showed `No experiments yet`. The app is not currently using the native RevenueCat Paywall builder.

There are two valid paths:

1. Keep the custom SwiftUI paywall and add a small remote configuration or server-controlled variant layer. This preserves the current German design and supports experiments that need app-specific context.
2. Adopt a RevenueCat native paywall for a controlled surface where placement, offerings, and experiment assignment should be managed centrally. First verify that legal links, German copy, accessibility, lifetime treatment, and the trial disclosure are all supported.

Do not adopt native paywalls merely to create more variants. First fix product readiness, instrumentation, and the simulator masking issue.

### Experiment backlog

| Test | Control | Variant | Primary metric | Guardrails |
| --- | --- | --- | --- | --- |
| Free-first timing | Trial during onboarding | Trial after first completed free drill | trial starts per activated user | onboarding completion, D1 return, refund/cancel |
| Plan architecture | onboarding monthly only | all plans with yearly recommended | paid conversion and plan mix | trial starts, revenue per install |
| Annual anchor | yearly first | monthly first or lifetime first | trial start and paid conversion | cancellation, refund, LTV |
| Paywall source | same generic paywall | contextual copy for room, drill, or game night | paywall-to-CTA rate | downstream completion and retention |
| Value proof | four static benefits | result-specific benefits based on completed drill | trial start after value moment | page exit, support contacts |
| CTA copy | `7-Tage-Test starten` | copy naming the selected plan and renewal | CTA-to-purchase rate | cancellation and complaints |
| Locked content | all locked tiles open paywall | contextual preview then paywall | upgrade conversion per locked feature | session continuation |
| Lifetime presentation | lifetime third card | lifetime as a clearly labeled alternative | lifetime share and total revenue | subscription starts and refunds |
| Error recovery | generic error | retry, offline explanation, and support path | recovered purchase attempt | repeated failures |
| Restore placement | footer restore | visible restore action after failed entitlement | successful restores | paywall clutter and abandonment |

Every experiment must record assignment, source, package availability, selected plan, product outcome, trial outcome, and at least D1 and D7 retention. Do not optimize only for CTA taps.

## 9. Ratings and review funnel

### Current implementation

`Shared/Services/ReviewPromptTracker.swift`:

- uses App Store ID `6796913722`
- has a direct App Store review URL with `action=write-review`
- has a support email path
- requires three positive moments and two launches
- has a 120-day cooldown
- has a 30-day soft-defer cooldown

`ReviewPromptSheet.swift` first asks whether the user likes the app. Positive users receive the review path. Users who are not positive are routed to feedback instead of the rating request. `DrillCompleteView.swift` delays the prompt by about 1.4 seconds after completion. Settings provides manual rating and feedback actions. Skat Minute results also participate in the review flow.

This is a thoughtful sentiment gate. It avoids asking immediately after a failed or frustrating exercise and gives unhappy users a support route.

### REVIEW-01, review-link opening is not a rating, P2

Evidence: the tracker marks the review path as opened after opening the App Store URL. There is no evidence that an actual rating was submitted, because the app cannot reliably observe that outcome.

Impact: a user who opens the store and does nothing may be treated as terminal and not asked again for 120 days.

Recommendation:

- Treat `review_link_opened` as a soft state, not proof of a review.
- Retain an eligibility path after a longer cooldown if no independent rating count improves.
- Compare 30, 60, and 120-day cooldown cohorts by prompt volume, support sentiment, and store rating trend.
- Keep the feedback diversion for negative sentiment.

### REVIEW-02, add funnel observability, P2

Measure:

- prompt eligible
- prompt shown
- positive selection
- negative selection
- review link opened
- feedback composer opened
- feedback submitted or mail client unavailable
- native review request attempted
- later retention and rating trend at the aggregate level

Do not log review text, email addresses, or user identity. Do not show a rating request during a purchase failure or immediately after a product-load error.

### Store rating baseline

Evidence: the live store says there are not enough ratings or reviews to display an overview. This is not a numeric rating and should not be converted into a zero-rating assumption.

The first goal should be a healthy, low-pressure review funnel after successful value moments, not maximizing prompt volume.

## 10. User experience and retention loops

### Strengths to protect

- Quick Session provides a one-tap free entry point from home.
- Drill completion records progress and supports spaced repetition.
- Error review converts mistakes into a return reason.
- Skat Minute provides a daily five-question habit.
- Game Night Prep gives a social or event-driven entry point.
- Offline practice is a clear differentiator.
- Four free rooms demonstrate the product before the paywall.
- Locked content previews communicate the paid expansion.

### Potential friction

- A user must pass a relatively long onboarding sequence before trying the core loop.
- The skill choice may be friction without immediate personalization benefit.
- A paywall can be shown with a loading price and generic error fallback.
- Home has several locked destinations. Repeated paywall encounters can feel like a catalog before habit formation.
- The live listing and website do not currently provide a strong visible review signal, so screenshots and first-session quality carry more acquisition weight.

### Retention experiments

- Compare a fixed daily Quick Session with a personalized error-review session.
- Test a post-session explanation of why the next paid room is useful.
- Use `Skat Minute` as the default return-to-app reminder only after a user completes a first session.
- Test a weekly progress summary without adding social pressure.
- Measure whether the Game Night Prep flow drives higher trial starts than generic locked-room entry.
- Test an explicit “continue your last room” home card against the current tile grid.

Guard against notifications becoming the solution for a weak first session. The first three completed exercises and the first return session are the strongest near-term retention checkpoints.

## 11. Crash, regression, and production watchdog assessment

### Current state

No MetricKit, Crashlytics, Sentry, `Logger`, or `os_log` integration was found in the repository. No crash, hang, launch-time, memory, or purchase-failure watchdog script is present. ASC exposes analytics and app-usage surfaces, and RevenueCat exposes purchase and trial analytics, but there is no repository automation that compares a new build to a baseline and alerts an operator.

This matters most around build 30 and the recent purchase, onboarding, screenshot, and iPad changes. Historical archive notes report earlier tests and smoke checks, but they are not evidence that the current 1.2.2 build is healthy.

### Signals a later Mac watchdog should observe

Crash and runtime:

- crash-free sessions and crash-free users by version and build
- distinct users affected by the same exception or termination reason
- crash count in the first 1, 6, and 24 hours after release
- hang rate and launch duration p50/p95
- memory pressure, jetsam, watchdog termination, and repeated relaunches
- first launch and onboarding completion failures
- iPad-specific crashes and layout failures

Commerce:

- offerings load failure rate
- product unavailable rate by product ID and storefront
- purchase starts, cancellations, failures, pending transactions, and successes
- entitlement confirmation timeout rate
- restore success and empty-restore rate
- trial starts, cancellations, conversions, and expiry
- RevenueCat active customers versus ASC subscription transactions

UX regression:

- paywall impressions with no product loaded
- CTA taps with no purchase attempt
- repeated paywall loops in one session
- onboarding exits by page
- free Quick Session starts and completions
- review prompt shown after an error or purchase failure
- local notification schedule and delivery failures, if observable

### Suggested release-window alert policy

The later watchdog should compare the new build with a seven-day pre-release baseline and the previous released build. Suggested alerts are:

- any crash-free user drop of more than 2 percentage points
- any crash signature affecting at least two distinct users within one hour
- any new crash signature in the first 24 hours
- offerings unavailable for more than 5% of paywall impressions
- purchase success below baseline while CTA taps remain normal
- entitlement confirmation timeout above 1% of successful StoreKit transactions
- a trial-start count with no corresponding RevenueCat or ASC record
- a sudden increase in trial cancellations or refunds

These are starting thresholds, not final policy. A later script should make every threshold configurable and should scaffold email output without sending notifications until explicitly enabled.

### Local validation matrix

Before the next monetization or onboarding release, validate on a real device Sandbox or TestFlight build:

1. Fresh install, no network, and slow network.
2. Existing free customer with local progress.
3. Monthly trial start, cancellation, renewal or expiry, and restore.
4. Yearly trial start, cancellation, and restore.
5. Lifetime purchase and restore.
6. User cancellation at the StoreKit sheet.
7. Product unavailable response.
8. RevenueCat unavailable response.
9. Purchase success with delayed entitlement.
10. Restore with another Apple account and with no purchase.
11. iPhone portrait and iPad orientations.
12. First launch, tour completion, Quick Session completion, error review, Skat Minute, and Game Night Prep.

Simulator tests must use no production RevenueCat key and must not count a local override as commerce evidence.

## 12. Documentation and release hygiene

| File | Observed stale or risky content | Priority |
| --- | --- | --- |
| `AGENTS.md` | Separate regular file with only a prose pointer to `CLAUDE.md` | P1 |
| `CLAUDE.md` | Full current guide, but its prices and product rules must be checked against live configuration on each release | P2 |
| `README.md` | Reports version 1.0 while the project and store are 1.2.2 | P1 |
| `.asc-state.json` | `draftVersion` 1.2.1 and `liveVersion` 1.2.0 while live ASC is 1.2.2 | P1 |
| `docs/index.html` | JSON-LD version 1.2.0, rating 5/1, iPhone-only short claim, and a competing canonical host | P1 |
| `Shared/WhatsNew.swift` | Release table has 1.2.0, 1.0, and 1.1, but no 1.2.2 | P1 |
| `scripts/generate_metadata_all.py` | Stale old prices remain runnable despite a warning | P1 |
| `scripts/asc-setup-release.py` | Old price specifications and release setup assumptions | P1 |
| `scripts/asc-set-prices.py` | Old price specifications | P1 |
| `scripts/asc-create-lifetime.py` | Old lifetime price specification | P1 |
| `scripts/asc-attach-build.py` | Historical examples use old version/build values | P2 |
| `docs/research/aso-skat.md` | Old prices and a stale generator reproducibility claim | P1 |
| `archive/release-readiness-2026-08-01.md` | Historical build 21/version 1.0 and old ASC state | P3, retain as archive |
| `archive/ios27SkatTrainer.md` | Historical test and warning evidence, not current build 30 evidence | P3, retain as archive |
| `docs/privacy-policy.html` plus pretty URL copy | Duplicated legal content can drift | P2 |
| `docs/terms.html` plus pretty URL copy | Duplicated legal content can drift | P2 |

### DOC-01, missing current release note entry, P1

Evidence: `Shared/WhatsNew.swift` derives the current release from the bundle version but contains no 1.2.2 entry. `HomeView.swift` presents the sheet only when a current release exists.

Inference: users upgrading to 1.2.2 will not see the current Skat Minute, Game Night Prep, and iPad release explanation through the in-app What’s New surface.

Recommendation: add a 1.2.2 entry or replace the mechanism with a release manifest generated from the release source. Validate first launch after upgrade and fresh install behavior.

### DOC-02, release state has multiple sources, P1

The current version appears in `project.yml`, `Info.plist` substitutions, ASC, public App Store metadata, `.asc-state.json`, README, website JSON-LD, research notes, release scripts, and `WhatsNew.swift`. These values have already drifted.

Recommendation: define one current release manifest containing:

- version and build
- App Store ID and bundle ID
- release date
- product IDs and current price source
- supported devices and minimum OS
- canonical marketing, support, terms, and privacy URLs
- release notes key

Have metadata, website, scripts, and What’s New consume that manifest or fail when they disagree. Historical documents should be stamped with `historical` and excluded from active validation.

## 13. Recommended implementation order for the next agent

### P0, confirm live commerce health

- Reconcile RevenueCat, ASC sales, and App Store subscription data.
- Test all three products on a real device Sandbox or TestFlight build.
- Verify trial eligibility and seven-day offers by storefront.
- Capture exact product, package, entitlement, and error outcomes.

### P1, remove false confidence and stale release signals

- Make `CLAUDE.md` and `AGENTS.md` one source of truth.
- Remove or disable stale price-writing scripts until corrected.
- Add the 1.2.2 What’s New entry.
- Correct website version, device claim, canonical host, and rating schema.
- Refresh README and `.asc-state.json` or make them generated.
- Add explicit entitlement allowlisting.

### P1, make the purchase surface failure-safe

- Do not show an enabled purchase CTA without a loaded package and localized price.
- Add retry and error classification.
- Add structured purchase and entitlement events.
- Create a real-device commerce gate in the release checklist.

### P1/P2, improve activation and trial starts

- Test free-first onboarding against the current five-page control.
- Test optional skill selection.
- Test a consistent plan architecture across onboarding and contextual paywalls.
- Measure activation through D1 return, not just trial CTA taps.

### P2, create the measurement layer

- Add the low-cardinality RevenueCat attributes in Section 7.
- Add the commerce and activation event schema.
- Build ASC and RevenueCat baseline exports.
- Add review-prompt funnel states.

### P2/P3, automate release safety and site consistency

- Add a configurable Mac watchdog scaffold.
- Add a fleet static scanner for stale versions, product IDs, URLs, legal copies, and metadata prices.
- Add website link/schema checks.
- Add a current-build smoke matrix and release-window comparison.

## 14. Validation checklist

### Static checks

- `python3 scripts/validate_metadata.py` passed during this audit.
- `python3 scripts/validate_aso_brief.py --brief docs/research/aso-skat.md --product-name "Skat Trainer"` passed during this audit.
- `python3 scripts/verify-store-config.py` passed during this audit and confirmed three fetchable approved packages.
- `SkatTrainer/Info.plist` passed `plutil -lint`.
- `SkatTrainer/SkatTrainer.storekit` must be parsed as JSON, not plist, before validation.
- Add a check for stale prices and stale versions before running metadata or ASC scripts.
- Add a check that `AGENTS.md` resolves to the canonical instruction file.
- Add a check that website schema version, device support, rating source, and canonical URL match the release manifest.

### Runtime checks

- Use the shared headless simulator only with local/non-production purchase behavior.
- Lease `agent-skat` according to the iOS fleet instructions.
- Do not configure the production `appl_` key for simulator runs.
- Use a real device Sandbox or TestFlight build for commerce evidence.
- Run the full onboarding, free value, paywall, trial, restore, review, offline, iPad, and error matrix.
- Capture build number and storefront in every test result.

### Data checks

- Compare ASC downloads and proceeds with RevenueCat new customers and transactions.
- Compare product IDs exactly, including case.
- Compare trial eligibility and introductory offer state by storefront.
- Separate trial cancellation, trial expiry, billing retry, refund, and paid conversion.
- Do not infer downloads or rating count from the public App Store page when the value is not displayed.

## 15. What this audit did not verify

- Numeric ASC downloads, product-page conversion, retention, crash, and app-usage values were not visible in the read-only browser session.
- No live App Store purchase was performed.
- No ASC or RevenueCat setting was changed.
- No local simulator or TestFlight runtime session was launched during this audit.
- The public App Store rating count is not known beyond the store's “not enough ratings” message.
- RevenueCat's production snapshot is not enough to diagnose whether the zero-revenue period is a bug.
- No customer identity, receipt, email, or private RevenueCat data is included here.

## Bottom line

The product fundamentals are promising, but the next agent should start with commerce reconciliation and source-of-truth cleanup. The current simulator override, zero-revenue production snapshot, stale release tooling, and inconsistent website schema create too much false confidence to optimize paywall copy first. Once those are controlled, the highest-value experiment is a free-first onboarding flow with consistent plan presentation, measured through first-session completion, trial start, paid conversion, and D7 retention.
