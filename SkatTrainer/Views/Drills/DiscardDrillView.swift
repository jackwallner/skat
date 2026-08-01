import SwiftUI

struct DiscardDrillView: View {
    let drill: Drill
    let scenarios: [DiscardScenario]

    @EnvironmentObject private var progress: ProgressStore

    @State private var index = 0
    @State private var selected: Set<Int> = []
    @State private var submitted = false
    @State private var score = 0
    @State private var finished = false
    @State private var confettiTrigger = 0
    @State private var shineTrigger = 0

    var body: some View {
        if finished {
            DrillCompleteView(drill: drill, score: score, total: scenarios.count * 2)
        } else {
            drillBody
        }
    }

    private var scenario: DiscardScenario { scenarios[index] }
    private var orderedDeal: [PlayingCard] { scenario.deal.racked }

    private var drillBody: some View {
        VStack(spacing: 16) {
            ProgressView(value: Double(index), total: Double(scenarios.count))
                .tint(Theme.jade)
            ScrollView {
                VStack(spacing: 18) {
                    Text(scenario.situation)
                        .font(Theme.display(20, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                    CardHandView(
                        tiles: orderedDeal,
                        tileWidth: 48,
                        highlightedIndices: selected,
                        onTap: { index in toggle(index) }
                    )
                    .padding(.vertical, 6)
                    if submitted {
                        coachCard
                            .shine(trigger: shineTrigger, corner: 16)
                            .winGlow(Theme.gold, active: matchCount == 2)
                            .transition(.scale(scale: 0.94).combined(with: .opacity))
                    } else {
                        Text("\(selected.count) von 2 ausgewählt")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            footer
        }
        .padding()
        .background(Theme.background)
        .overlay { ConfettiBurst(trigger: confettiTrigger, origin: .init(x: 0.5, y: 0.35)) }
        .navigationTitle(drill.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var coachCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: matchCount == 2 ? "star.fill" : "graduationcap.fill")
                    .foregroundStyle(Theme.gold)
                Text(headline)
                    .font(.headline)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Lehrentscheidung für den Skat:")
                    .font(.subheadline.weight(.semibold))
                HStack(spacing: 6) {
                    ForEach(Array(scenario.recommendedDiscard.enumerated()), id: \.offset) { _, card in
                        PlayingCardView(tile: card, width: 42)
                    }
                }
            }
            Text(scenario.reasoning)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(Theme.gold)
                Text(scenario.tip)
                    .font(.footnote.weight(.medium))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.gold.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .themedCard(corner: 16)
    }

    private var headline: String {
        switch matchCount {
        case 2: return "Perfekt gedrückt, 2 von 2"
        case 1: return "Fast, 1 von 2 getroffen"
        default: return "Die Lehrentscheidung war anders"
        }
    }

    private var matchCount: Int {
        var pool = scenario.recommendedDiscard
        var matches = 0
        for index in selected {
            if let hit = pool.firstIndex(of: orderedDeal[index]) {
                pool.remove(at: hit)
                matches += 1
            }
        }
        return matches
    }

    private var footer: some View {
        Group {
            if submitted {
                Button {
                    advance()
                } label: {
                    Text(index + 1 < scenarios.count ? "Nächste Entscheidung" : "Fertig").primaryCTA()
                }
            } else {
                Button {
                    submit()
                } label: {
                    Text("Diese 2 drücken").primaryCTA()
                }
                .disabled(selected.count != 2)
                .opacity(selected.count == 2 ? 1 : 0.4)
            }
        }
    }

    private func toggle(_ cardIndex: Int) {
        guard !submitted else { return }
        if selected.contains(cardIndex) {
            selected.remove(cardIndex)
        } else if selected.count < 2 {
            selected.insert(cardIndex)
        }
    }

    private func submit() {
        guard selected.count == 2 else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { submitted = true }
        score += matchCount
        let correct = matchCount == 2
        progress.recordItem(id: scenario.id, correct: correct)
        PracticeRecordStore.shared.record(itemID: scenario.id, roomID: DrillLibrary.roomID(forDrillID: drill.id), correct: correct)
        if correct {
            confettiTrigger += 1
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 350_000_000)
                shineTrigger += 1
            }
            Haptics.correctAnswer()
            SoundPlayer.play(.success)
        } else {
            Haptics.wrongAnswer()
            SoundPlayer.play(.miss)
        }
    }

    private func advance() {
        if index + 1 < scenarios.count {
            selected = []
            submitted = false
            index += 1
        } else {
            finished = true
        }
    }
}
