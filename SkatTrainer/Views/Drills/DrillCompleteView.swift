import SwiftUI
import StoreKit

struct DrillCompleteView: View {
    let drill: Drill
    let score: Int?
    let total: Int
    /// Supplied when there is no navigation stack to pop (the onboarding
    /// tour's cover); otherwise Done just dismisses.
    var onDone: (() -> Void)?

    @EnvironmentObject private var progress: ProgressStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview
    @State private var showReviewPrompt = false
    @State private var recorded = false
    @State private var celebrate = false
    @State private var confettiTrigger = 0
    @State private var pendingNativeReviewAfterDismiss = false

    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Theme.jade.opacity(0.12))
                    .frame(width: 132, height: 132)
                    .scaleEffect(celebrate ? 1 : 0.6)
                if let score {
                    VStack(spacing: 2) {
                        Text("\(score)/\(total)")
                            .font(Theme.display(34))
                            .foregroundStyle(Theme.jade)
                            .monospacedDigit()
                        Text("richtig")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.inkSecondary)
                    }
                } else {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 58))
                        .foregroundStyle(Theme.jade)
                }
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: celebrate)
            VStack(spacing: 8) {
                Text(headline)
                    .font(Theme.display(30))
                    .foregroundStyle(Theme.ink)
                Text(subheadline)
                    .font(.body)
                    .foregroundStyle(Theme.inkSecondary)
                    .multilineTextAlignment(.center)
            }
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(Theme.coral)
                Text("\(progress.streakCount) Tage am Stück")
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .themedCard(corner: 22)
            Spacer()
            Button {
                if let onDone { onDone() } else { dismiss() }
            } label: {
                Text("Fertig").primaryCTA()
            }
        }
        .padding()
        .background(Theme.background)
        .overlay { ConfettiBurst(trigger: confettiTrigger, origin: .init(x: 0.5, y: 0.3), particleCount: 44) }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            celebrate = true
            confettiTrigger += 1
            guard !recorded else { return }
            recorded = true
            Haptics.success()
            SoundPlayer.play(.complete)
            progress.recordSession(drillID: drill.id)
            recordPositiveMoment()
        }
        .sheet(isPresented: $showReviewPrompt, onDismiss: requestPendingNativeReview) {
            ReviewPromptSheet(onFinish: handleReviewOutcome)
        }
    }

    /// A finished drill is the positive moment the funnel waits for. Let the
    /// celebration land first: a sheet that lands on top of the confetti reads
    /// as an interruption, not a thank-you.
    private func recordPositiveMoment() {
        ReviewPromptTracker.recordPositiveMoment()
        guard ReviewPromptTracker.shouldShowAfterPositiveMoment() else { return }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_400_000_000)
            showReviewPrompt = true
        }
    }

    private func handleReviewOutcome(_ outcome: ReviewPromptDismissOutcome) {
        pendingNativeReviewAfterDismiss = outcome == .enjoyedMaybeLater
    }

    private func requestPendingNativeReview() {
        guard pendingNativeReviewAfterDismiss else { return }
        pendingNativeReviewAfterDismiss = false
        requestReview()
    }

    private var headline: String {
        guard let score else { return "Stapel geschafft!" }
        let fraction = Double(score) / Double(max(total, 1))
        if fraction >= 1 { return "Perfekte Runde!" }
        if fraction >= 0.7 { return "Sehr gut!" }
        return "Gute Übung!"
    }

    private var subheadline: String {
        if score == nil {
            return "Alle \(total) Karten sind eingeordnet. Mit jeder Runde sitzt es ein wenig besser."
        }
        return "Jede Entscheidung, die du hier übst, liest du am Tisch schneller."
    }
}
