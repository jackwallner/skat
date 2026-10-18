---
paths:
  - "android/**"
  - "docs/android-*.html"
  - "scripts/android-export/**"
  - "scripts/sync-android-content.sh"
  - "scripts/play_screenshot_compositor.py"
  - "scripts/play-products.py"
  - "scripts/play-upload.sh"
  - "scripts/make_android_icon.py"
---

# Skat Trainer Android rules

## Identity and products

- Native Android code is in `android/`, a screen-for-screen port of the iOS app
  (same German copy, tokens, flows, product IDs). When iOS changes, port the
  change. It started from `~/cribbage/android`; every Cribbage screen, string
  and asset was replaced.
- Package `com.jackwallner.skat`, launcher label "Skat Trainer", Play title
  "Skat Trainer: Learn Skat", paid tier "Skat+". Feedback and Play contact
  email `jackwallner+m@gmail.com` (same as iOS).
- Products (same IDs as iOS): subscriptions `com.jackwallner.skat.monthly` and
  `com.jackwallner.skat.yearly` (base plans `monthly` / `yearly`, 7-day
  `trial-7d` new-customer offer), lifetime one-time product
  `com.jackwallner.skat.lifetime` (purchase option `lifetime`). Android US
  ladder $5.49 / $23.99 / $55.99, about 20% under iOS ($6.99 / $29.99 /
  $69.99); local prices are Play's conversion plus the fleet PPP curve. Never
  put prices in listing copy or app literals (`TrialCopyTest` pins the
  fallback strings).
- RevenueCat project `proje0bf13d7`: Test Store app `app899597ca5a` (Debug key
  `apikey945bd8402a`), Play app `app640c959455` (`goog_` key
  `apikey5ebf5bf00e`, release only), App Store app `app0f92f1ad50`.
  Entitlements `pro` (`entl38278f192f`) and `Skat+` (`entlf5c769d98b`); either
  unlocks, and each holds the Play, App Store and Test Store products. The app
  reads offering `android` (`ofrnga39ba017d2`, not current; iOS keeps
  `default`) with `$rc_monthly` (`pkge5454dbfa2b`), `$rc_annual`
  (`pkge69f0c0322f`) and `$rc_lifetime` (`pkgef8abf7eca2`), each holding the
  Play product (`...monthly:monthly`, `...yearly:yearly`, `...lifetime`) and
  the Test Store twin (`monthly`, `yearly`, `lifetime`).
- Play reviewers unlock Skat+ with a code (long-press Settings > Version).
  Only its SHA-256 is in the build (`PLAY_REVIEW_CODE_SHA256` in
  `local.properties`); the code is `SKAT_PLAY_REVIEW_CODE` in
  `~/.skat_credentials` and goes in Play Console App access. Never commit it.

## Content and parity

- Content and engine fixtures come from Swift, never hand-edited:
  `scripts/sync-android-content.sh` runs `scripts/android-export/` and writes
  `app/src/main/resources/skat-content.json` and the test fixture
  `skat-parity.json`. Rerun it after changing `Shared/Models`,
  `Shared/Content`, `WhatsNew.swift` or `ChoiceShuffle.swift`.
- `SeededRandom.kt` is the Swift RNG bit for bit (FNV-1a seed, xorshift64*,
  Lemire bounded draw, forward Fisher-Yates, `Bool.random` from bit 17), so
  generated hands, choice order and the daily Skat Minute match iOS. The
  parity unit tests compare against the exported fixtures.

## Deliberate differences from iOS

- Purchase copy names Google Play and has no "24 Stunden vor Ende" clause
  (Play has no such rule).
- The review prompt keeps the iOS gates (second launch on, 30-day cooldown) and
  calls `launchReviewFlow` with no enjoyment question. Settings "Skat Trainer
  bewerten" opens the Play listing.

## Build

- JDK 17, checked-in Gradle wrapper, AGP 9.4.1, Kotlin 2.4.20, minSdk 26,
  target/compile 36.
- `android/local.properties` (ignored, mode 600) holds `REVENUECAT_TEST_KEY`,
  `REVENUECAT_PLAY_KEY`, `PLAY_REVIEW_CODE_SHA256` and `PLAY_UPLOAD_*` (upload
  keystore `~/.android/keystores/skat-upload.p12`, backup in
  `~/.android/keystores/backups/`, alias `upload`, password
  `SKAT_PLAY_UPLOAD_PASSWORD` in `~/.skat_credentials`). Release builds fail
  without them. Upload cert SHA-256
  `9F:57:C8:1A:7C:D3:73:99:3F:FC:03:E3:CE:51:7C:5B:DE:DD:A0:1E:CA:9F:D5:2B:04:52:83:A9:8E:BC:B0:F4`.
- `scripts/make_android_icon.py` derives the adaptive icon layers, legacy and
  round icons and `play-assets/icon-512.png` from the iOS AppIcon.
- Increment `versionCode` on every Play upload. 1.2.4 is versionCode 1.
- `scripts/play-upload.sh [validate|internal|internal-draft|production-draft]`
  and `scripts/play-products.py [--dry-run]` need `PLAY_SERVICE_ACCOUNT_JSON`.
  Neither has been run yet.

## Emulator (remote MacBook Pro only)

Follow the `android-dev` skill's Remote MacBook Pro section. Host
`jackwallner@192.168.4.25` (strict host keys), SDK
`/Users/jackwallner/Library/Android/sdk`. The Pro has no cmdline-tools and no
JDK 17: sync `android/` (minus `build/`, `.gradle/`, `local.properties`,
`play-assets/`) to `~/skat-agent-test/android`, write a debug-only
`local.properties` (sdk.dir, Test Store key, review digest), and unpack a
temporary Temurin 17 (Adoptium mac x64 tarball) into `~/skat-agent-test/jdk`.
Create the temporary AVD `skat_agent_test` by hand (`.ini` plus a
`config.ini` cloned from another agent AVD, `android-36`
`google_apis_playstore` x86_64, `hw.lcd.height = 2400`), boot it headless on
port 5568:

```sh
ssh jackwallner@192.168.4.25 'nohup ~/Library/Android/sdk/emulator/emulator -avd skat_agent_test -port 5568 -no-window -no-audio -no-boot-anim -no-metrics -gpu swiftshader_indirect > ~/skat-agent-test/emulator.log 2>&1 &'
ssh jackwallner@192.168.4.25 '~/Library/Android/sdk/platform-tools/adb -s emulator-5568 shell getprop sys.boot_completed'
```

Disable Digital Wellbeing (`pm disable-user --user 0
com.google.android.apps.wellbeing`) and the three animation scales before
testing; Wellbeing otherwise throws an "isn't responding" dialog over
captures. Run connected tests there with `ANDROID_SERIAL=emulator-5568`
`./gradlew --no-daemon --max-workers=2 connectedDebugAndroidTest`. Afterwards
`adb -s emulator-5568 emu kill`, then delete only
`~/.android/avd/skat_agent_test.{avd,ini}` and `~/skat-agent-test`. Never
touch `small_phone` (emulator-5554) or other agents' AVDs. The Pro is a 2-core
2015 i7: a cold boot takes about 5 minutes; let it settle before a connected
run.

Debug launch extras (`DebugLaunchOptions`, debug builds only): `resetAll`,
`onboarded`, `skillLevel`, `seedProgress`, `forcePro`, `appearance`, `uiTest`.
Test tags are exposed as resource ids.

## Store assets

`StoreScreenshotTest` (excluded from the connected suite; run it with
`am instrument -w -e class com.jackwallner.skat.StoreScreenshotTest com.jackwallner.skat.test/androidx.test.runner.AndroidJUnitRunner`)
writes the six raw 1080x2400 captures to
`/sdcard/Android/data/com.jackwallner.skat/files/screens/`, the same six
screens as the App Store set. Turn System UI demo mode on first. Pull them
into `android/play-assets/raw/` and run
`python3 scripts/play_screenshot_compositor.py` for the 1080x1920 frames (the
German App Store headlines from `scripts/appstore_screenshot_compositor.py`)
and the 1024x500 feature graphic. Listing text and the changelog are in
`android/play-assets/metadata/android/en-US/` (English, says the app is in
German, no prices, no em dashes). Privacy and terms pages are
`docs/android-privacy.html` and `docs/android-terms.html` (German, like the
app) on GitHub Pages.

## Play state (2026-10-17)

Staged, not sent for review. Play app id `4976373559372140451` (E3 Apps). versionCode 1
(1.2.4) uploaded with `~/docs/android/tools/play_stage.py`; listing, icon,
feature graphic and 6 screenshots committed by API; draft releases on
internal and production, production targets all 178 countries. Products from
`scripts/play-products.py` are active (two subscriptions with `trial-7d`, one
lifetime). App content is complete: privacy policy, no ads, no ad ID, not a
government app, no financial features, App access (instructions only),
18 and over, data safety (RevenueCat: purchase history, app interactions,
device IDs), IARC, category Education. Publishing overview shows
"Submit 11 changes for review".

Left for Jack: paste `SKAT_PLAY_REVIEW_CODE` from `~/.skat_credentials`
into App access > Skat+ review unlock > Password, then press Send for review
when this app's pacing slot comes. Review codes: `~/docs/android/tools/play_handoff.py review-codes`. RevenueCat Play
credentials were uploaded with `play_handoff.py rc-credentials --apply`
on  2026-10-17. The RevenueCat service account already has
account-wide Play permissions, so no per-app grant is needed.
