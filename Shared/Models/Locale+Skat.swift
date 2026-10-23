import Foundation

extension Locale {
    /// The locale every visible date and time is formatted in.
    ///
    /// The app ships German only, but SwiftUI formats `DatePicker`s and
    /// `Text(date, format:)` with the device locale, so a US-region phone
    /// showed "5:00 PM" inside German copy. Pinning German (Germany) keeps
    /// the 24-hour clock and German day and month names on every device.
    static let skat = Locale(identifier: "de_DE")
}
