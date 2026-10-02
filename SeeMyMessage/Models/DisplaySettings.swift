import Foundation

/// The user-configurable settings for the LED display.
///
/// This is intentionally a `struct` (a value type) with no dependencies,
/// so it can be owned directly by SwiftUI view state and passed around
/// by copying — fully offline, no backend needed.
struct DisplaySettings {

    // MARK: - Speed constants (pixels per second)

    /// Minimum scrolling speed in pixels per second.
    static let minSpeed: Double = 30

    /// Maximum scrolling speed in pixels per second.
    static let maxSpeed: Double = 250

    /// Default scrolling speed in pixels per second.
    static let defaultSpeed: Double = 80

    /// The full range the Slider is allowed to pick from.
    static let speedRange: ClosedRange<Double> = minSpeed...maxSpeed

    // Thresholds that decide the human-readable label.
    // These are not magic numbers scattered in logic — they live here
    // so they are easy to find and tune later.
    static let slowUpperBound: Double = 70
    static let normalUpperBound: Double = 140

    // MARK: - Stored values

    /// The raw text the user typed. May contain leading/trailing spaces
    /// while typing — we only trim when validating.
    var message: String = ""

    /// Scrolling speed in pixels per second. Set via a Slider in HomeView.
    var speed: Double = defaultSpeed

    // MARK: - Derived helpers

    /// The message without surrounding whitespace/newlines.
    var trimmedMessage: String {
        message.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// True when there is something to display.
    /// Used to enable/disable the START button.
    var isValid: Bool {
        !trimmedMessage.isEmpty
    }

    /// Human-readable speed category.
    var speedCategory: String {
        if speed < Self.slowUpperBound {
            return "Slow"
        } else if speed < Self.normalUpperBound {
            return "Normal"
        } else {
            return "Fast"
        }
    }

    /// Human-readable speed value, e.g. "80 px/s".
    var formattedSpeed: String {
        "\(Int(speed)) px/s"
    }
}
