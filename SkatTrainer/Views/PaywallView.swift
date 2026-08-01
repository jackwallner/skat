import SwiftUI
import RevenueCat

enum PaywallPlan: String, CaseIterable {
    case yearly, lifetime, monthly

    var ctaTitle: String {
        self == .lifetime ? "\(Membership.name) dauerhaft freischalten" : "7-Tage-Test starten"
    }
}

enum PaywallLinks {
    /// Apple's standard EULA. If the app ever ships a custom EULA, this is the
    /// one place to swap it; App Review requires a functional Terms link here.
    static let terms = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    static let privacy = URL(string: "https://jackwallner.github.io/skat/privacy-policy")!
    static let manageSubscriptions = URL(string: "https://apps.apple.com/account/subscriptions")!
}

/// Shared paywall content used by the locked-drill sheet and Settings.
///
/// App Review 3.1.2 wants all of this ON the purchase screen, not buried:
/// the membership name, what each plan costs, the billing period, an explicit
/// auto-renew statement, Restore, and working Terms + Privacy links. Every one
/// of those lives in this file; don't trim them for layout.
struct PaywallContent: View {
    @EnvironmentObject private var subscriptions: SubscriptionService
    @Binding var selectedPlan: PaywallPlan

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 6) {
                Text("\(Membership.name) freischalten")
                    .font(Theme.display(28))
                    .foregroundStyle(Theme.ink)
                Text("Alles, was du hast, bleibt frei. \(Membership.name) ergänzt Übungen ohne Ende.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSecondary)
                    .multilineTextAlignment(.center)
            }
            // Leads with the endless modes on purpose. Selling "more drills"
            // is what let a motivated player finish the membership in two
            // sittings; what they are actually buying now is practice that
            // does not end.
            VStack(alignment: .leading, spacing: 9) {
                benefit("Endlos üben: jedes Mal ein frisches Kartenmuster")
                benefit("Fehler wiederholen: Unsicheres kommt zurück, bis es sitzt")
                benefit("Zeitprüfung: 90 Sekunden für deinen Bestwert")
                benefit("Extra-Runden in jedem Raum plus der Meistertisch")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            planCards
        }
    }

    private func benefit(_ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Theme.jade)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var planCards: some View {
        VStack(spacing: 10) {
            planCard(.yearly, title: "Jährlich", price: PaywallPricing.price(subscriptions, .yearly),
                     detail: "7 Tage kostenlos, danach jährliche Abrechnung. Verlängert sich automatisch.", badge: "BESTER WERT")
            planCard(.lifetime, title: "Dauerhaft", price: PaywallPricing.price(subscriptions, .lifetime),
                     detail: "Einmalige Zahlung. Kein Abonnement, keine Verlängerung.", badge: "EINMALIG")
            planCard(.monthly, title: "Monatlich", price: PaywallPricing.price(subscriptions, .monthly),
                     detail: "7 Tage kostenlos, danach monatliche Abrechnung. Verlängert sich automatisch.", badge: nil)
        }
    }

    private func planCard(_ plan: PaywallPlan, title: String, price: String, detail: String, badge: String?) -> some View {
        let isSelected = selectedPlan == plan
        return Button {
            selectedPlan = plan
            Haptics.impact(.light, intensity: 0.6)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(Theme.ink)
                        if let badge {
                            Text(badge)
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Theme.gold.opacity(0.18), in: Capsule())
                                .foregroundStyle(Theme.gold)
                        }
                    }
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(Theme.inkSecondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 8)
                Text(price)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.ink)
            }
            .padding(14)
            .background(
                isSelected ? Theme.jade.opacity(0.08) : Theme.card,
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(isSelected ? Theme.jade : Theme.rule, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

/// Price and terms strings, live from StoreKit when RevenueCat has loaded and
/// falling back to the configured prices so the screen is never blank.
@MainActor
enum PaywallPricing {
    static func price(_ subscriptions: SubscriptionService, _ plan: PaywallPlan) -> String {
        let base = subscriptions.package(for: plan)?.storeProduct.localizedPriceString
        switch plan {
        case .yearly: return "\(base ?? "$9.99") / Jahr"
        case .monthly: return "\(base ?? "$1.99") / Monat"
        case .lifetime: return base ?? "$29.99 einmalig"
        }
    }

    /// One concise point-of-purchase line: price, trial, auto-renew, cancel.
    /// The full legalese lives in the EULA behind the Terms link.
    static func terms(_ subscriptions: SubscriptionService, _ plan: PaywallPlan) -> String {
        let amount = price(subscriptions, plan)
        switch plan {
        case .lifetime:
            return "\(amount) einmalig. Kein Abonnement, keine automatische Verlängerung."
        case .yearly, .monthly:
            return "7 Tage kostenlos, danach \(amount). Verlängert sich automatisch. Kündige mindestens 24 Stunden vor Ablauf."
        }
    }
}

/// Standalone paywall sheet (locked drills, locked rooms, Settings upgrade).
struct PaywallView: View {
    // CardPort parity markers: Restore, Terms of Use, Privacy Policy.
    @EnvironmentObject private var subscriptions: SubscriptionService
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: PaywallPlan = .yearly
    @State private var purchasing = false
    @State private var restoring = false
    @State private var message: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                PaywallContent(selectedPlan: $selectedPlan)
                    .padding()
            }
            .background(Theme.background)
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 8) {
                    Text(PaywallPricing.terms(subscriptions, selectedPlan))
                        .font(.caption)
                        .foregroundStyle(Theme.inkSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    Button {
                        purchase()
                    } label: {
                        Group {
                            if purchasing {
                                ProgressView().tint(.white)
                            } else {
                                Text(selectedPlan.ctaTitle)
                            }
                        }
                        .primaryCTA()
                    }
                    .disabled(purchasing)
                    footerLinks
                }
                .padding()
                .background(.thinMaterial)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Schließen") { dismiss() }
                        .foregroundStyle(Theme.inkSecondary)
                }
            }
            .alert("Skat Trainer", isPresented: .init(
                get: { message != nil },
                set: { if !$0 { message = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(message ?? "")
            }
            .onChange(of: subscriptions.isPro) { _, isPro in
                if isPro { dismiss() }
            }
        }
    }

    private var footerLinks: some View {
        HStack(spacing: 16) {
            Button("Wiederherstellen") { restore() }
                .disabled(restoring)
            Link("Nutzungsbedingungen", destination: PaywallLinks.terms)
            Link("Datenschutz", destination: PaywallLinks.privacy)
        }
        .font(.caption)
        .foregroundStyle(Theme.inkSecondary)
    }

    private func purchase() {
        purchasing = true
        Task {
            defer { purchasing = false }
            do {
                await subscriptions.ensureOfferings()
                let outcome = try await subscriptions.purchase(subscriptions.package(for: selectedPlan))
                guard outcome == .purchased else { return }
                Haptics.success()
                // The sheet dismisses itself the moment `isPro` flips. If the
                // entitlement hasn't landed after a few seconds, say so and
                // point at Restore, rather than leaving someone who just paid
                // looking at the paywall that charged them.
                if await !subscriptions.confirmEntitlement() {
                    message = "Dein Kauf wurde abgeschlossen, aber \(Membership.name) ist noch nicht freigeschaltet. Warte einen Moment und tippe dann auf Wiederherstellen. Es wird nichts doppelt berechnet."
                }
            } catch {
                // A cancel never lands here (it's an outcome, not a throw), so
                // anything that does is worth telling the player about.
                message = error.localizedDescription
            }
        }
    }

    private func restore() {
        restoring = true
        Task {
            defer { restoring = false }
            do {
                try await subscriptions.restore()
                if !subscriptions.isPro {
                    message = "Für diesen Apple Account wurde kein früherer Kauf gefunden."
                }
            } catch {
                message = error.localizedDescription
            }
        }
    }
}
