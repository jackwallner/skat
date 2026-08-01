import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Warm-modern design system: cream surfaces, jade primary, coral energy,
/// serif display type. Every color adapts to dark mode via dynamic providers.
enum Theme {
    // MARK: Brand

    /// Deep jade , primary actions, progress, selected states.
    static let jade = Color(light: (0.09, 0.42, 0.36), dark: (0.36, 0.71, 0.62))
    /// Terracotta coral , energy moments: streaks, celebration, badges.
    static let coral = Color(light: (0.86, 0.42, 0.31), dark: (0.94, 0.56, 0.45))
    /// Soft gold , locks, "best value", coach highlights.
    static let gold = Color(light: (0.76, 0.57, 0.18), dark: (0.88, 0.72, 0.38))
    /// Plum , Discard room identity.
    static let plum = Color(light: (0.48, 0.28, 0.52), dark: (0.72, 0.53, 0.76))

    // MARK: Surfaces

    /// Warm cream app background (never pure white / pure black).
    static let background = Color(light: (0.97, 0.945, 0.90), dark: (0.11, 0.10, 0.09))
    /// Raised card surface.
    static let card = Color(light: (1.0, 0.99, 0.965), dark: (0.17, 0.155, 0.14))
    /// Slightly sunken surface for wells inside cards.
    static let well = Color(light: (0.945, 0.915, 0.86), dark: (0.14, 0.13, 0.115))
    /// Hairline stroke on cards.
    static let rule = Color(light: (0.86, 0.82, 0.75), dark: (0.28, 0.26, 0.235))

    // MARK: Ink

    // Contrast is not a style knob here. This app's readers skew 50+ and read
    // it on a couch in bad light, and tertiary ink carries the money disclosure
    // and the swipe instructions. Every level below clears WCAG AA (4.5:1) on
    // both backgrounds; tertiary used to sit at 2.8:1, which is decorative-text
    // territory. Re-check with a contrast calculator before darkening the cream.
    static let ink = Color(light: (0.16, 0.14, 0.12), dark: (0.94, 0.92, 0.88))
    /// 6.3:1 light / 7.6:1 dark.
    static let inkSecondary = Color(light: (0.38, 0.35, 0.31), dark: (0.72, 0.69, 0.64))
    /// 4.6:1 light / 6.0:1 dark.
    static let inkTertiary = Color(light: (0.46, 0.42, 0.38), dark: (0.62, 0.59, 0.55))

    // MARK: Playing cards

    static let cardEdge = Color(light: (0.76, 0.70, 0.61), dark: (0.53, 0.48, 0.42))
    static let cardRed = Color(light: (0.72, 0.16, 0.15), dark: (0.96, 0.49, 0.43))

    // MARK: Compatibility aliases for shared drill effects

    static var felt: Color { jade }
    static var cardBackground: Color { card }
    static var tileIvory: Color { card }
    static var tileEdge: Color { cardEdge }
    static var ivory: Color { card }
    static var ivoryShadow: Color { cardEdge }
    static var crakRed: Color { cardRed }
    static var bamGreen: Color { jade }
    static var dotBlue: Color { coral }
    static var jokerPurple: Color { plum }
    static var flowerPink: Color { coral }

    // MARK: Type

    /// Serif display for titles , the "skat club" voice.
    static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    static let cardCorner: CGFloat = 20
    static let deckCorner: CGFloat = 26
}

/// Room identity: each room keeps its own accent so the four doors feel like
/// four places, not four list rows.
extension Room {
    var accent: Color {
        switch id {
        case "card-room": return Theme.jade
        case "scoring-room": return Theme.coral
        case "discard-room": return Theme.plum
        case "pegging-room": return Theme.jade
        default: return Theme.gold
        }
    }

    /// Bundled room illustration (see `scripts/generate_room_art.py`). Purely
    /// decorative: never carries information a player has to read.
    var artName: String { "room-\(id)" }
}

/// The membership brand. The RevenueCat entitlement is still `pro`; this is
/// only what players read.
enum Membership {
    static let name = "Skat+"
}

/// The gold pill that marks anything behind the membership.
struct PlusBadge: View {
    var text: String = Membership.name

    var body: some View {
        Text(text)
            .font(.caption.weight(.heavy))
            .foregroundStyle(Theme.gold)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Theme.gold.opacity(0.15), in: Capsule())
    }
}

extension Color {
    /// Adaptive color from light/dark RGB triples.
    init(light: (Double, Double, Double), dark: (Double, Double, Double)) {
        #if canImport(UIKit)
        self.init(uiColor: UIColor { traits in
            let c = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: c.0, green: c.1, blue: c.2, alpha: 1)
        })
        #else
        self.init(red: light.0, green: light.1, blue: light.2)
        #endif
    }
}

// MARK: - Shared styles

extension View {
    /// Standard raised card: warm surface, hairline, soft shadow.
    func themedCard(corner: CGFloat = Theme.cardCorner) -> some View {
        self
            .background(Theme.card, in: RoundedRectangle(cornerRadius: corner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .strokeBorder(Theme.rule, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
    }

    func primaryCTA(color: Color = Theme.jade) -> some View {
        self
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(color, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: color.opacity(0.35), radius: 8, y: 4)
    }
}

/// Press-scale feedback for card-shaped buttons.
struct PressableCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Haptics

enum Haptics {
    enum Impact { case soft, light, rigid, heavy }

    /// Settings gate: reads the same key AppSettings writes, defaulting on.
    private static var enabled: Bool {
        UserDefaults.standard.object(forKey: "settings.haptics") as? Bool ?? true
    }

    static func impact(_ style: Impact, intensity: CGFloat = 1.0) {
        #if canImport(UIKit)
        guard enabled else { return }
        let uiStyle: UIImpactFeedbackGenerator.FeedbackStyle
        switch style {
        case .soft: uiStyle = .soft
        case .light: uiStyle = .light
        case .rigid: uiStyle = .rigid
        case .heavy: uiStyle = .heavy
        }
        UIImpactFeedbackGenerator(style: uiStyle).impactOccurred(intensity: intensity)
        #endif
    }

    static func success() {
        #if canImport(UIKit)
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }

    static func error() {
        #if canImport(UIKit)
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        #endif
    }

    /// Grading haptics have to feel like OPPOSITES in the hand, not like two
    /// versions of the same buzz. Apple's `.success` and `.error` notification
    /// patterns are both stutters and are easy to confuse mid-drill, so:
    /// right = a crisp light tap rising into the success chime; wrong = a
    /// single dull heavy thud, no chime, nothing bright about it.
    static func correctAnswer() {
        #if canImport(UIKit)
        guard enabled else { return }
        impact(.light, intensity: 0.75)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 70_000_000)
            success()
        }
        #endif
    }

    static func wrongAnswer() {
        #if canImport(UIKit)
        guard enabled else { return }
        impact(.heavy, intensity: 0.85)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 110_000_000)
            impact(.heavy, intensity: 0.45)
        }
        #endif
    }
}
