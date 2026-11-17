import Foundation

extension Calendar {
    /// A zone tests pin so day keys can be checked across zones. The app
    /// leaves it nil and follows the device. Setting `NSTimeZone.default` no
    /// longer moves `TimeZone.current`, so tests cannot switch zones that way.
    nonisolated(unsafe) static var zoneOverride: TimeZone?

    /// Gregorian in the device's time zone.
    ///
    /// Shared identities (the month's challenge, the day's Skat-Minute) and
    /// stored day keys use it instead of `.current`, so a Buddhist, Hebrew or
    /// Japanese system calendar cannot hand a player different questions from
    /// everyone else, orphan their saved results, or stretch the challenge
    /// archive back thousands of "months". Months and days still turn over at
    /// local midnight.
    static var gregorianLocal: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zoneOverride ?? .current
        return calendar
    }
}
