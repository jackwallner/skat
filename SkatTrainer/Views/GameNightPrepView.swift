import SwiftUI
import UIKit

struct GameNightPrepView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var progress: ProgressStore
    @StateObject private var records = PracticeRecordStore.shared

    private var sessionItems: [QuickItem] {
        SessionBuilder.gameNightPrep(
            seen: progress.seenItems,
            missed: progress.missedItems,
            dueIDs: records.reviewQueue(),
            weakestRoomID: records.weakestRoom()?.id
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                hero
                scheduleCard
                personalizedCard
                NavigationLink {
                    QuickSessionView(gameNightPrep: sessionItems)
                } label: {
                    Text("Fünf Minuten vorbereiten").primaryCTA(color: Theme.plum)
                }
            }
            .padding()
            .frame(maxWidth: Theme.readableContentWidth)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.background)
        .navigationTitle("Skatabend-Vorbereitung")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Mitteilungen sind aus", isPresented: $settings.reminderPermissionDenied) {
            Button("Einstellungen öffnen") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Jetzt nicht", role: .cancel) {}
        } message: {
            Text("Skat Trainer kann keine Erinnerungen senden, solange Mitteilungen in den iOS-Einstellungen aus sind.")
        }
    }

    private var hero: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Theme.plum)
                .frame(width: 68, height: 68)
                .background(Theme.plum.opacity(0.13), in: Circle())
            Text("Vorbereitet an den Tisch")
                .font(Theme.display(28))
                .foregroundStyle(Theme.ink)
            Text("Lege deinen üblichen Skatabend fest. Die Erinnerung öffnet eine frische Runde aus deinen Fehlern, deinem schwächsten Raum und Material, das du noch nicht gesehen hast.")
                .font(.subheadline)
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .themedCard()
    }

    private var scheduleCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("WÖCHENTLICHE ERINNERUNG")
                        .font(.caption.weight(.heavy))
                        .kerning(1.4)
                        .foregroundStyle(Theme.inkSecondary)
                    Text(settings.gameNightReminderEnabled ? "Vorbereitung ist geplant" : "Wähle deinen Skatabend")
                        .font(.headline)
                        .foregroundStyle(Theme.ink)
                }
                Spacer()
                Toggle("Wöchentliche Erinnerung an den Skatabend", isOn: $settings.gameNightReminderEnabled)
                    .labelsHidden()
            }
            Divider().overlay(Theme.rule)
            Picker("Skatabend", selection: $settings.gameNightDay) {
                ForEach(AppSettings.GameNightDay.allCases) { day in
                    Text(day.displayName).tag(day)
                }
            }
            DatePicker(
                "Erinnerung",
                selection: $settings.gameNightReminderTime,
                displayedComponents: .hourAndMinute
            )
            Text("Zu dieser Zeit öffnet die Mitteilung jeden \(settings.gameNightDay.displayName) direkt deine persönliche Übungsrunde.")
                .font(.caption)
                .foregroundStyle(Theme.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .themedCard(corner: 16)
    }

    private var personalizedCard: some View {
        let weakest = records.weakestRoom()
        return HStack(alignment: .top, spacing: 12) {
            Image(systemName: "scope")
                .font(.body.weight(.semibold))
                .foregroundStyle(Theme.coral)
                .frame(width: 40, height: 40)
                .background(Theme.coral.opacity(0.13), in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text("Darauf zielt die Vorbereitung")
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                Text(personalizationCopy(weakest))
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .themedCard(corner: 16)
    }

    private func personalizationCopy(_ weakest: PracticeRecordStore.RoomStat?) -> String {
        if records.dueCount > 0, let weakest {
            return "\(records.dueCount) fällige\(records.dueCount == 1 ? "r Fehler" : " Fehler") zuerst, danach Extra-Übung in \(weakest.name)."
        }
        if records.dueCount > 0 {
            return "\(records.dueCount) fällige\(records.dueCount == 1 ? "r Fehler" : " Fehler") zuerst, danach Material, das du noch nicht gesehen hast."
        }
        if let weakest {
            return "Extra-Übung in \(weakest.name), danach eine ausgewogene Mischung aus den anderen Räumen."
        }
        return "Jetzt eine ausgewogene Mitglieder-Mischung. Je mehr Fragen du beantwortest, desto genauer trifft diese Runde deine echten Schwachstellen."
    }
}
