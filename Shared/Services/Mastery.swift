import Foundation

/// How well a room is known, as opposed to how much of it was opened. An item
/// counts as known after two correct answers in a row, and stops counting once
/// it is a full review interval overdue.
enum MasteryLevel: Int, Comparable, Sendable {
    case untouched
    case learning
    case solid
    case sharp

    static func < (lhs: MasteryLevel, rhs: MasteryLevel) -> Bool { lhs.rawValue < rhs.rawValue }

    var title: String {
        switch self {
        case .untouched: return "Neu"
        case .learning: return "Im Aufbau"
        case .solid: return "Sicher"
        case .sharp: return "Souverän"
        }
    }

    var icon: String {
        switch self {
        case .untouched: return "circle.dotted"
        case .learning: return "book.fill"
        case .solid: return "checkmark.seal.fill"
        case .sharp: return "star.fill"
        }
    }

    var nextStep: String {
        switch self {
        case .untouched: return "Beantworte ein paar Fragen, dann zählt der Raum mit."
        case .learning: return "Beantworte jede Frage zweimal hintereinander richtig, um sie zu festigen."
        case .solid: return "Weiter so. Souverän heißt: fast alles sitzt."
        case .sharp: return "Schau ab und zu vorbei, damit es so bleibt."
        }
    }

    /// Coverage thresholds, not raw accuracy: three perfect answers do not
    /// mean the room is known.
    static func level(known: Int, total: Int, attempted: Int = 0) -> MasteryLevel {
        guard total > 0 else { return .untouched }
        guard known > 0 else { return attempted > 0 ? .learning : .untouched }
        switch Double(known) / Double(total) {
        case 0.85...: return .sharp
        case 0.4..<0.85: return .solid
        default: return .learning
        }
    }
}

struct RoomMastery: Identifiable, Sendable {
    let roomID: String
    let known: Int
    let total: Int
    let level: MasteryLevel

    var id: String { roomID }
    var fraction: Double { total == 0 ? 0 : Double(known) / Double(total) }
}

extension PracticeRecord {
    func isKnown(now: Date = Date()) -> Bool {
        guard streak >= 2 else { return false }
        guard intervalDays > 0 else { return true }
        return now < dueDate.addingTimeInterval(intervalDays * 86_400)
    }
}

extension PracticeRecordStore {
    /// Measured against the items this player can open, so a free player's
    /// ring is never held open by Skat+ sets they cannot reach.
    func mastery(for room: Room, isMember: Bool, now: Date = Date()) -> RoomMastery {
        let ids = Set(Self.trackableItemIDs(in: room, isMember: isMember))
        guard !ids.isEmpty else {
            return RoomMastery(roomID: room.id, known: 0, total: 0, level: .untouched)
        }
        let known = ids.filter { records[$0]?.isKnown(now: now) == true }.count
        let attempted = ids.filter { records[$0] != nil }.count
        return RoomMastery(
            roomID: room.id,
            known: known,
            total: ids.count,
            level: MasteryLevel.level(known: known, total: ids.count, attempted: attempted)
        )
    }

    func masteryByRoom(isMember: Bool, now: Date = Date()) -> [RoomMastery] {
        DrillLibrary.rooms.map { mastery(for: $0, isMember: isMember, now: now) }
    }

    /// The started, not yet sharp room with the lowest coverage. A room never
    /// opened is new, not weak.
    func roomToWorkOn(isMember: Bool, now: Date = Date()) -> RoomMastery? {
        masteryByRoom(isMember: isMember, now: now)
            .filter { $0.level != .untouched && $0.level != .sharp }
            .min { $0.fraction < $1.fraction }
    }

    static func trackableItemIDs(in room: Room, isMember: Bool) -> [String] {
        var ids: [String] = []
        for drill in room.drills where !room.isLocked(drill, isMember: isMember) {
            switch drill.kind {
            case .quiz(let questions): ids += questions.map(\.id)
            case .handMatch(let questions): ids += questions.map(\.id)
            case .flashcards(let cards): ids += cards.map(\.id)
            case .discard(let scenarios): ids += scenarios.map(\.id)
            }
        }
        return ids
    }
}
