import Foundation

import RevenueCat

/// Everything RevenueCat can change without a release, read from the current
/// offering's metadata (a running Experiment's variant included). Every variant ships in the binary; a missing or unknown
/// value is the control, which is what the app shipped before this existed.
/// Keys that a switch reads must be set the same on every offering, or an
/// Experiment arm would flip them as a side effect.
///
/// DEBUG builds can pin any key for captures: `-skat.rc.<key> <value>`.

/// The trial button's wording. The control is what each surface has always
/// shipped: "7 Tage kostenlos starten" on the onboarding trial page and
/// "7-Tage-Test starten" on the paywall. The two arms read the same on both.
enum TrialCTA: String, CaseIterable, Sendable {
    static let metadataKey = "trial_cta"

    /// Control, as shipped since 1.0.
    case sevenDay = "seven_day"
    /// First person: "Meine Probewoche starten".
    case my
    /// Second person: "Deine Probewoche starten".
    case your

    enum Surface {
        case onboarding, paywall
    }

    static func from(metadata: [String: Any]?) -> TrialCTA {
        RemoteConfig.value(metadataKey, in: metadata, default: .sevenDay)
    }

    func title(_ surface: Surface) -> String {
        switch (self, surface) {
        case (.sevenDay, .onboarding): return "7 Tage kostenlos starten"
        case (.sevenDay, .paywall): return "7-Tage-Test starten"
        case (.my, _): return "Meine Probewoche starten"
        case (.your, _): return "Deine Probewoche starten"
        }
    }
}

/// Remote off switches, for what is worth pausing without a release. On
/// unless the metadata says "off".
enum RemoteSwitch: String, CaseIterable, Sendable {
    /// Apple's tracking prompt for Meta ads.
    case attPrompt = "att_prompt"
    /// Apple's rating prompt after a good drill.
    case ratingPrompt = "rating_prompt"
    /// A future remotely switchable feature (a challenge with its own Home card
    /// and deep link). Nothing reads it yet; Skat-Minute is not behind it.
    case challenge = "challenge"
}

enum RemoteConfig {
    /// The value for `key`, or `fallback` when it is missing, not a string,
    /// or not one of the shipped variants.
    static func value<T: RawRepresentable>(_ key: String, in metadata: [String: Any]?, default fallback: T) -> T
    where T.RawValue == String {
        #if DEBUG
        if let pinned = launchOverride(key).flatMap(T.init(rawValue:)) { return pinned }
        #endif
        guard let raw = metadata?[key] as? String else { return fallback }
        return T(rawValue: raw) ?? fallback
    }

    static func isOn(_ remoteSwitch: RemoteSwitch, in metadata: [String: Any]?) -> Bool {
        #if DEBUG
        if let pinned = launchOverride(remoteSwitch.rawValue) { return pinned != "off" }
        #endif
        return (metadata?[remoteSwitch.rawValue] as? String) != "off"
    }

    #if DEBUG
    private static func launchOverride(_ key: String) -> String? {
        let args = ProcessInfo.processInfo.arguments
        guard let index = args.firstIndex(of: "-skat.rc.\(key)"), index + 1 < args.count else { return nil }
        return args[index + 1]
    }
    #endif
}

extension SubscriptionService {
    private var remoteMetadata: [String: Any]? { offerings?.current?.metadata }

    var trialCTAArm: TrialCTA { TrialCTA.from(metadata: remoteMetadata) }

    func trialCTA(_ surface: TrialCTA.Surface) -> String { trialCTAArm.title(surface) }

    func isOn(_ remoteSwitch: RemoteSwitch) -> Bool { RemoteConfig.isOn(remoteSwitch, in: remoteMetadata) }

    /// Every variant this customer saw, for reading tests by attribute too.
    var remoteVariantAttributes: [String: String] {
        [TrialCTA.metadataKey: trialCTAArm.rawValue]
    }
}
