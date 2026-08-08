import SwiftUI
import StoreKit
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var subscriptions: SubscriptionService
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var progress: ProgressStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview
    @State private var showPaywall = false
    @State private var showWhatsNew = false
    @State private var showResetConfirm = false
    @State private var restoreMessage: String?
    /// Non-nil while the review funnel is up; the value is where it opens.
    @State private var reviewPromptStep: ReviewPromptSheet.Step?
    @State private var pendingNativeReviewAfterDismiss = false

    var body: some View {
        NavigationStack {
            Form {
                appearanceSection
                practiceSection
                proSection
                dataSection
                supportSection
                aboutSection
                #if DEBUG
                debugSection
                #endif
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .tint(Theme.jade)
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") { dismiss() }
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showWhatsNew) {
                if let release = WhatsNew.currentRelease {
                    WhatsNewSheet(release: release) {
                        showWhatsNew = false
                        Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 350_000_000)
                            showPaywall = true
                        }
                    }
                }
            }
            .sheet(item: $reviewPromptStep, onDismiss: requestPendingNativeReview) { step in
                ReviewPromptSheet(initialStep: step) { outcome in
                    pendingNativeReviewAfterDismiss = outcome == .enjoyedMaybeLater
                }
            }
            .alert("Wiederherstellen", isPresented: .init(
                get: { restoreMessage != nil },
                set: { if !$0 { restoreMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(restoreMessage ?? "")
            }
            .alert("Mitteilungen sind deaktiviert", isPresented: $settings.reminderPermissionDenied) {
                Button("Einstellungen öffnen") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Später", role: .cancel) {}
            } message: {
                Text("Skat Trainer kann dich erst täglich erinnern, wenn Mitteilungen für die App in den iOS-Einstellungen aktiviert sind.")
            }
            .alert("Fortschritt zurücksetzen?", isPresented: $showResetConfirm) {
                Button("Zurücksetzen", role: .destructive) {
                    progress.resetAll()
                    PracticeRecordStore.shared.resetAll()
                }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Deine Serie, abgeschlossenen Übungen und Übungshistorie werden gelöscht. Käufe bleiben erhalten.")
            }
        }
    }

    private func requestPendingNativeReview() {
        guard pendingNativeReviewAfterDismiss else { return }
        pendingNativeReviewAfterDismiss = false
        requestReview()
    }

    private var appearanceSection: some View {
        Section("Darstellung") {
            Picker("Erscheinungsbild", selection: $settings.appearance) {
                ForEach(AppSettings.Appearance.allCases) { appearance in
                    Text(appearance.displayName).tag(appearance)
                }
            }
        }
    }

    private var practiceSection: some View {
        Section("Üben") {
            Toggle("Haptisches Feedback", isOn: $settings.hapticsEnabled)
            Toggle("Töne", isOn: $settings.soundEnabled)
            Toggle("Tägliche Erinnerung", isOn: $settings.reminderEnabled)
            if settings.reminderEnabled {
                DatePicker("Erinnerungszeit", selection: $settings.reminderTime, displayedComponents: .hourAndMinute)
            }
        }
    }

    /// Reset gets its own section. A destructive red button sitting between
    /// Haptics and Sound Effects is a trap for anyone who taps to see what
    /// something does.
    private var dataSection: some View {
        Section("Deine Übungshistorie") {
            NavigationLink {
                StatsView()
            } label: {
                Label("Dein Fortschritt", systemImage: "chart.bar.fill")
            }
            Button("Fortschritt zurücksetzen", role: .destructive) {
                showResetConfirm = true
            }
        }
    }

    private var proSection: some View {
        Section("Mitgliedschaft") {
            if subscriptions.isPro {
                Label("\(Membership.name) freigeschaltet", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(Theme.jade)
                Link("Abonnement verwalten", destination: PaywallLinks.manageSubscriptions)
            } else {
                Button {
                    showPaywall = true
                } label: {
                    Label("\(Membership.name) entdecken", systemImage: "sparkles")
                }
            }
            Button("Käufe wiederherstellen") {
                Task {
                    do {
                        try await subscriptions.restore()
                        restoreMessage = subscriptions.isPro
                            ? "\(Membership.name) wurde wiederhergestellt."
                            : "Für diesen Apple Account wurde kein früherer Kauf gefunden."
                    } catch {
                        restoreMessage = error.localizedDescription
                    }
                }
            }
        }
    }

    private var supportSection: some View {
        Section("Hilfe") {
            NavigationLink {
                HowToPlayView()
            } label: {
                Label("So geht Skat", systemImage: "book.fill")
            }
            if WhatsNew.currentRelease != nil {
                Button {
                    showWhatsNew = true
                } label: {
                    Label("Neu in dieser Version", systemImage: "sparkle")
                }
            }
            Button {
                reviewPromptStep = .reviewPitch
            } label: {
                Label("Skat Trainer bewerten", systemImage: "star.fill")
            }
            Button {
                reviewPromptStep = .feedback
            } label: {
                Label("Feedback senden", systemImage: "envelope.fill")
            }
        }
    }

    private var aboutSection: some View {
        Section("Über Skat Trainer") {
            LabeledContent("Version", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")
            Text("Skat Trainer ist eine unabhängige Übungs-App mit eigenen Lehrbeispielen. Regeln können am Tisch variieren, spiele nach den Regeln, die ihr vereinbart habt.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    #if DEBUG
    private var debugSection: some View {
        Section("Entwicklung") {
            Toggle("Lokale Mitgliedschaft aktivieren", isOn: .init(
                get: { subscriptions.isPro },
                set: { subscriptions.setLocalOverride(isPro: $0) }
            ))
        }
    }
    #endif
}
