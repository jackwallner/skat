import SwiftUI

/// Onboarding: three value pages, a skill-level question, then the OT710-style
/// trial step. The primary button keeps IDENTICAL geometry on every page (the
/// zero-shift rule): the thumb rides Continue the whole way, and on the last
/// page the same button becomes "Start 7-day free trial", one tap straight
/// to Apple's confirm. No plan cards here; the full paywall is only a fallback
/// when products failed to load.
///
/// After the trial decision (either way), brand-new players get the How to
/// Play quick start FIRST, then everyone gets the feature tour, whose finale
/// runs a real Quick Session. The primer has to come before that session:
    /// answering questions about cards you have not met yet is not an onboarding.
/// Only once the tour is done does `hasOnboarded` flip and Home appear.
struct OnboardingView: View {
    @EnvironmentObject private var progress: ProgressStore
    @EnvironmentObject private var subscriptions: SubscriptionService
    @State private var page = 0
    @State private var purchasing = false
    @State private var showPaywallFallback = false
    @State private var purchaseError: String?
    @AppStorage("skat.skillLevel") private var skillLevel = ""

    private enum Stage: Equatable { case pages, tour, howToPlay }
    @State private var stage: Stage = .pages

    private let lastPage = 4
    private let skillPage = 3

    var body: some View {
        Group {
            switch stage {
            case .pages:
                pagesBody
            case .howToPlay:
                // Skip lands on Home, not on the next onboarding step: the
                // whole point of an escape hatch is that it escapes.
                HowToPlayView(onDone: { stage = .tour }, onSkip: { finish() })
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .tour:
                FeatureTourView { finish() }
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: stage)
    }

    private var pagesBody: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                infoPage(
                    icon: "rectangle.portrait.on.rectangle.portrait.angled",
                    title: "Zwischen den Runden sicherer werden",
                    body: "Skat gerät zwischen zwei Runden schnell aus dem Kopf. Skat Trainer gibt dir fünfminütige Übungen für Karten, Reizen, Drücken und Stiche.",
                    tiles: [.c(7), .d(10), .h(14), .s(11)]
                ).tag(0)
                infoPage(
                    icon: "rectangle.stack.fill",
                    title: "Üben ohne Druck",
                    body: "Wische durch Karteikarten, erkenne Trumpfstrukturen, entscheide über den Skat und spiele Stichsituationen durch, immer mit der Erklärung dahinter.",
                    tiles: [.c(11), .d(14), .h(10), .s(8)]
                ).tag(1)
                infoPage(
                    icon: "figure.walk",
                    title: "Sicher an den Tisch",
                    body: "Kenne die Kartenwerte, erkenne Trumpf, Grand und Null schneller und drücke mit einem Plan. Übe in deinem Tempo, ohne Gegner und ohne Zeitdruck.",
                    tiles: [.c(14), .d(11), .h(7)]
                ).tag(2)
                skillLevelPage.tag(3)
                trialPage.tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: page)
            footer
        }
        .background(Theme.background)
        // Resolve the product before the price slot is on screen. `start()`
        // already asks at launch, but on a cold or slow network the answer can
        // still be in flight when someone swipes through four pages in three
        // seconds, and the trial step has to show a real billed amount by the
        // time it appears - it no longer has an invented one to fall back on.
        .task(id: page) {
            await subscriptions.ensureOfferings()
        }
        .onChange(of: page) { _, newPage in
            guard newPage == lastPage else { return }
            subscriptions.trackPaywallImpression(id: "skat_onboarding_trial", oncePerSession: true)
        }
        .sheet(isPresented: $showPaywallFallback, onDismiss: paywallDismissed) {
            PaywallView(source: "skat_onboarding_fallback")
        }
        .alert("Kaufproblem", isPresented: .init(
            get: { purchaseError != nil },
            set: { if !$0 { purchaseError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(purchaseError ?? "")
        }
    }

    private func infoPage(icon: String, title: String, body bodyText: String, tiles: [PlayingCard]) -> some View {
        VStack(spacing: 26) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(Theme.jade)
                .frame(width: 92, height: 92)
                .background(Theme.jade.opacity(0.12), in: Circle())
            Text(title)
                .font(Theme.display(32))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            CardHandView(tiles: tiles, tileWidth: 54)
            Text(bodyText)
                .font(.body)
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 28)
    }

    // MARK: - Skill level

    private struct SkillOption {
        let id: String
        let title: String
        let detail: String
    }

    private let skillOptions: [SkillOption] = [
        SkillOption(id: "new", title: "Ganz neu", detail: "Ich lerne gerade, was die Karten bedeuten"),
        SkillOption(id: "basics", title: "Grundlagen bekannt", detail: "Das Geben kenne ich, beim Reizen bin ich noch langsam"),
        SkillOption(id: "played", title: "Schon gespielt", detail: "Ich kenne Skat und möchte bessere Entscheidungen treffen"),
    ]

    private var skillLevelPage: some View {
        VStack(spacing: 22) {
            Spacer()
            Text("Wo startest du?")
                .font(Theme.display(30))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text("Wir zeigen dir die passenden Übungen.")
                .font(.subheadline)
                .foregroundStyle(Theme.inkSecondary)
            VStack(spacing: 12) {
                ForEach(skillOptions, id: \.id) { option in
                    skillCard(option)
                }
            }
            Text(skillLevel.isEmpty ? "Wähle eine Option, um fortzufahren." : " ")
                .font(.footnote)
                .foregroundStyle(Theme.inkSecondary)
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 28)
    }

    private func skillCard(_ option: SkillOption) -> some View {
        let selected = skillLevel == option.id
        return Button {
            skillLevel = option.id
            Haptics.impact(.light, intensity: 0.6)
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(option.title)
                        .font(.headline)
                        .foregroundStyle(Theme.ink)
                    Text(option.detail)
                        .font(.subheadline)
                        .foregroundStyle(Theme.inkSecondary)
                        // Wrap rather than truncate. Skat's strings fit today,
                        // but the HStack will compress this to one line and
                        // clip it on a narrow phone or at larger type sizes.
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(selected ? Theme.jade : Theme.inkTertiary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                selected ? Theme.jade.opacity(0.08) : Theme.card,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(selected ? Theme.jade : Theme.rule, lineWidth: selected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Trial step (OT710: hero + bullets, zero plan cards)

    private var trialPage: some View {
        VStack(spacing: 22) {
            Spacer()
            Image(systemName: "sparkles")
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(Theme.gold)
                .frame(width: 92, height: 92)
                .background(Theme.gold.opacity(0.14), in: Circle())
            // Not "kostenlos testen". App Review 3.1.2(c) rejected this screen
            // for promoting the free trial more conspicuously than the billed
            // amount, and a 30pt headline saying "free" was the largest such
            // element on it. The trial is still offered - once, on the button,
            // under the price - which is where it converts anyway.
            Text("\(Membership.name) freischalten")
                .font(Theme.display(30))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            VStack(alignment: .leading, spacing: 12) {
                trialBenefit("Alle vier Einstiegsräume bleiben dauerhaft frei")
                trialBenefit("Endlos üben gibt dir jedes Mal ein neues Kartenmuster")
                trialBenefit("Fehler wiederholen bringt unsichere Fragen zurück")
                trialBenefit("Extra-Runden in allen Räumen plus der Meistertisch")
            }
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 28)
    }

    private func trialBenefit(_ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Theme.jade)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Theme.ink)
                // Wrap rather than truncate: three of these four lines were
                // clipped mid-word ("bleibt dauerh...") in the review build.
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// The billed amount, shown prominently at the point of purchase (App Review
    /// 3.1.2(c) flagged that it wasn't clearly and conspicuously displayed).
    private var monthlyPrice: String {
        PaywallPricing.priceText(subscriptions, .monthly)
    }

    /// One concise line, matching the approved fleet pattern (StatScout): trial
    /// length, price, that it renews, how to cancel. The EULA behind the Terms
    /// link carries the full legalese; this is the point-of-purchase micro copy.
    private var monthlyDisclosure: String {
        guard let price = PaywallPricing.price(subscriptions, .monthly) else {
            return "Inklusive 7 Tagen kostenlos. Verlängert sich automatisch, bis du kündigst."
        }
        return "Abrechnung: \(price), inklusive 7 Tagen kostenlos. Verlängert sich automatisch, bis du kündigst."
    }

    // MARK: - Footer (identical geometry on every page: zero-shift CTA)

    private var footer: some View {
        let onTrialPage = page == lastPage
        return VStack(spacing: 8) {
            pageDots
            // Soft free exit sits ABOVE the primary so the trial CTA owns the
            // Continue slot. "Get Started" (not "Skip"/"No trial") on purpose,
            // matching the approved fleet apps: it's the free way in, worded so
            // it doesn't read as a loud "escape the offer" button. Height
            // reserved on every page.
            Button {
                startTour()
            } label: {
                Text("Loslegen")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.inkSecondary)
            }
            .frame(height: 30)
            .opacity(onTrialPage ? 1 : 0)
            .disabled(!onTrialPage)
            // Pricing slot, also reserved. The billed amount is the conspicuous
            // element (App Review 3.1.2(c) flagged that it wasn't clearly
            // displayed); the disclosure under it stays small and tertiary.
            // minHeight, not a fixed height: the German disclosure wraps to two
            // or three lines depending on the device, and the slot renders on
            // every page anyway, so the CTA still never shifts.
            VStack(spacing: 2) {
                Text(monthlyPrice)
                    .font(Theme.display(26).weight(.bold))
                    .foregroundStyle(Theme.ink)
                Text(monthlyDisclosure)
                    .font(.caption2)
                    .foregroundStyle(Theme.inkTertiary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(minHeight: 48)
            .opacity(onTrialPage ? 1 : 0)
            Button {
                primaryAction()
            } label: {
                Group {
                    if purchasing {
                        ProgressView().tint(.white)
                    } else {
                        Text(onTrialPage ? "7 Tage kostenlos starten" : "Weiter")
                    }
                }
                .primaryCTA()
            }
            .disabled(purchasing || (page == skillPage && skillLevel.isEmpty))
            .opacity(page == skillPage && skillLevel.isEmpty ? 0.5 : 1)
            // Legal footer slot, reserved on every page.
            HStack(spacing: 14) {
                Link("Nutzungsbedingungen", destination: PaywallLinks.terms)
                Link("Datenschutz", destination: PaywallLinks.privacy)
                Button("Wiederherstellen") {
                    Task { try? await subscriptions.restore() }
                }
            }
            .font(.caption2)
            .foregroundStyle(Theme.inkTertiary)
            .frame(height: 20)
            .opacity(onTrialPage ? 1 : 0)
            .disabled(!onTrialPage)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 10)
    }

    private var pageDots: some View {
        HStack(spacing: 6) {
            ForEach(0...lastPage, id: \.self) { dot in
                Capsule()
                    .fill(dot == page ? Theme.jade : Theme.jade.opacity(0.22))
                    .frame(width: dot == page ? 20 : 7, height: 7)
                    .animation(.snappy(duration: 0.22), value: page)
            }
        }
        .padding(.bottom, 2)
    }

    /// The trial CTA is the Apple purchase trigger, nothing else. One tap goes
    /// straight to StoreKit's confirm sheet.
    ///
    /// It must NOT open a second paywall. Backing out of Apple's sheet leaves
    /// the player exactly where they were (they can still tap Get Started, or
    /// the CTA again); the full plan-picker fallback is reserved for the one
    /// case it was designed for, products that genuinely failed to load, so
    /// the button is never dead.
    private func primaryAction() {
        if page < lastPage {
            page += 1
            return
        }
        purchasing = true
        Task {
            defer { purchasing = false }
            await subscriptions.ensureOfferings()
            guard let monthly = subscriptions.package(for: .monthly) else {
                showPaywallFallback = true
                return
            }
            do {
                let outcome = try await subscriptions.purchase(monthly)
                switch outcome {
                case .purchased:
                    startTour()
                case .cancelled:
                    break // They said no to Apple, not to the app. Stay put.
                }
            } catch {
                purchaseError = error.localizedDescription
            }
        }
    }

    /// Both exits from the trial page land here. Brand-new players take the
    /// primer first so the tour's closing Quick Session isn't the first time
    /// they see an unfamiliar card; everyone else goes straight to the tour.
    private func startTour() {
        stage = skillLevel == "new" ? .howToPlay : .tour
    }

    /// A successful purchase in the products-failed fallback must rejoin the
    /// onboarding path instead of dropping the player back on the trial page.
    private func paywallDismissed() {
        guard subscriptions.isPro else { return }
        startTour()
    }

    private func finish() {
        // RootView branches on this key, so setting it swaps Home in.
        // A brand-new player has never run an older version, so there is
        // nothing "new" to tell them. Stamping the baseline here is what keeps
        // the update sheet off a fresh install.
        WhatsNew.markCurrentAsBaseline()
        progress.hasOnboarded = true
    }
}
