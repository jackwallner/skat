import SwiftUI
import StoreKit
import UIKit

/// How the funnel ended, so the host knows whether to fire `requestReview()`.
enum ReviewPromptDismissOutcome: Sendable {
    case notNow
    case feedbackSubmitted
    case openedWriteReview
    /// Said yes, then "Maybe later": the host may fire `requestReview()` once.
    case enjoyedMaybeLater
}

/// The three-step review funnel: enjoying it? -> yes, please rate / no, tell us
/// what's wrong. Nobody who says "not really" is ever shown a rating prompt;
/// they get a feedback box that mails us instead. That's the whole trick, and
/// it's why the App Store rating only ever hears from happy players.
struct ReviewPromptSheet: View {
    @Environment(\.requestReview) private var requestReview

    enum Step: Identifiable {
        case enjoyment, reviewPitch, feedback

        var id: Self { self }
    }

    let initialStep: Step
    let onFinish: (ReviewPromptDismissOutcome) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var step: Step
    @State private var feedbackText = ""
    @State private var mailFailed = false
    @FocusState private var feedbackFocused: Bool

    init(initialStep: Step = .enjoyment, onFinish: @escaping (ReviewPromptDismissOutcome) -> Void) {
        self.initialStep = initialStep
        self.onFinish = onFinish
        _step = State(initialValue: initialStep)
    }

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case .enjoyment: enjoymentContent
                case .reviewPitch: reviewPitchContent
                case .feedback: feedbackContent
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Theme.background)
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Nicht jetzt") {
                        ReviewPromptTracker.markShown()
                        finish(.notNow)
                    }
                    .foregroundStyle(Theme.inkSecondary)
                }
            }
        }
        .presentationDetents(step == .feedback ? [.large] : [.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var navigationTitle: String {
        switch step {
        case .enjoyment: "Gefällt dir Skat Trainer?"
        case .reviewPitch: "Eine unabhängige App unterstützen"
        case .feedback: "Hilf uns, besser zu werden"
        }
    }

    private var enjoymentContent: some View {
        VStack(spacing: 20) {
            icon("checkmark.seal.fill", Theme.jade)
            Text("Du hast \(ReviewPromptTracker.positiveMomentCount) Übungen abgeschlossen. Wenn Skat Trainer dir zwischen den Runden mehr Sicherheit gibt, hilft eine kurze Bewertung anderen Spielern, die App zu finden.")
                .font(.subheadline)
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            VStack(spacing: 10) {
                Button { step = .reviewPitch } label: {
                    Text("Ja, ich mag die App").primaryCTA()
                }
                Button { step = .feedback } label: {
                    Text("Noch nicht wirklich")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.inkSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
            }
        }
        .padding(24)
    }

    private var reviewPitchContent: some View {
        VStack(spacing: 18) {
            icon("star.fill", Theme.gold)
            Text("Skat Trainer wird von einer Person entwickelt. Keine Werbung, kein Konto, und deine Übungshistorie verlässt dein Gerät nicht.")
                .font(.subheadline)
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text("Eine ehrliche Bewertung im App Store dauert nur wenige Sekunden und hilft einer kleinen App wie dieser am meisten, neue Spieler zu erreichen.")
                .font(.footnote)
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            VStack(spacing: 10) {
                Button {
                    ReviewPromptTracker.markOpenedWriteReview()
                    if let url = AppStoreLinks.writeReviewURL {
                        UIApplication.shared.open(url)
                    } else {
                        requestReview()
                    }
                    finish(.openedWriteReview)
                } label: {
                    Text("Im App Store bewerten").primaryCTA()
                }
                Button {
                    ReviewPromptTracker.markSoftDeferred()
                    finish(.enjoyedMaybeLater)
                } label: {
                    Text("Vielleicht später")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.inkSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
            }
        }
        .padding(24)
    }

    private var feedbackContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Was würde Skat Trainer für dich besser machen?")
                .font(.headline)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            TextEditor(text: $feedbackText)
                .font(.body)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 140)
                .padding(10)
                .themedCard(corner: 14)
                .focused($feedbackFocused)
            if mailFailed {
                // Plenty of people never set up Apple Mail. Telling them it
                // "sent" when nothing opened is worse than saying nothing.
                VStack(alignment: .leading, spacing: 6) {
                    Text("Deine Mail-App wurde nicht geöffnet. Du kannst uns direkt schreiben:")
                        .font(.caption)
                        .foregroundStyle(Theme.ink)
                    Button {
                        UIPasteboard.general.string = AppStoreLinks.feedbackEmail
                        Haptics.success()
                    } label: {
                        Label("\(AppStoreLinks.feedbackEmail) kopieren", systemImage: "doc.on.doc")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.jade)
                    }
                }
            } else {
                Text("Öffnet deine Mail-App mit einem Entwurf an den Entwickler. Die Nachricht geht an eine echte Person.")
                    .font(.caption)
                    .foregroundStyle(Theme.inkSecondary)
            }
            Button {
                sendFeedback()
            } label: {
                Text("Feedback senden").primaryCTA()
            }
            .disabled(trimmedFeedback.isEmpty)
            .opacity(trimmedFeedback.isEmpty ? 0.5 : 1)
            Spacer(minLength: 0)
        }
        .padding(24)
        .onAppear { feedbackFocused = true }
    }

    private func icon(_ name: String, _ color: Color) -> some View {
        Image(systemName: name)
            .font(.system(size: 28, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: 68, height: 68)
            .background(color.opacity(0.13), in: Circle())
            .padding(.top, 6)
    }

    private var trimmedFeedback: String {
        feedbackText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Only claim the feedback was sent if a mail app actually opened.
    private func sendFeedback() {
        guard !trimmedFeedback.isEmpty, let url = Self.feedbackMailURL(body: trimmedFeedback) else { return }
        UIApplication.shared.open(url, options: [:]) { opened in
            Task { @MainActor in
                guard opened else {
                    mailFailed = true
                    return
                }
                ReviewPromptTracker.markFeedbackSubmitted()
                finish(.feedbackSubmitted)
            }
        }
    }

    private func finish(_ outcome: ReviewPromptDismissOutcome) {
        onFinish(outcome)
        dismiss()
    }

    static func feedbackMailURL(body: String) -> URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = AppStoreLinks.feedbackEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: "Feedback zu Skat Trainer"),
            URLQueryItem(name: "body", value: body),
        ]
        return components.url
    }
}
