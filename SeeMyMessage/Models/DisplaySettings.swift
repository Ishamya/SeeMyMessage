import Foundation
import SwiftUI

/// Available LED dot colors. Raw values are stable identifiers.
enum LEDColor: String, CaseIterable, Identifiable {
    case red
    case green
    case blue
    case amber
    case purple
    case white

    var id: String { rawValue }

    /// User-friendly display name shown in the Home picker.
    var displayName: String {
        switch self {
        case .red: return "Red"
        case .green: return "Green"
        case .blue: return "Blue"
        case .amber: return "Amber"
        case .purple: return "Purple"
        case .white: return "White"
        }
    }

    /// Bright LED-style dot color (not muted pastels).
    var color: Color {
        switch self {
        case .red: return Color(red: 1.0, green: 0.13, blue: 0.13)
        case .green: return Color(red: 0.13, green: 1.0, blue: 0.31)
        case .blue: return Color(red: 0.13, green: 0.5, blue: 1.0)
        case .amber: return Color(red: 1.0, green: 0.69, blue: 0.13)
        case .purple: return Color(red: 0.75, green: 0.25, blue: 1.0)
        case .white: return Color.white
        }
    }
}

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
    static let defaultSpeed: Double = 160

    /// The full range the Slider is allowed to pick from.
    static let speedRange: ClosedRange<Double> = minSpeed...maxSpeed

    // Thresholds that decide the human-readable label.
    // These are not magic numbers scattered in logic — they live here
    // so they are easy to find and tune later.
    static let slowUpperBound: Double = 70
    static let normalUpperBound: Double = 140

    // MARK: - Gap constants (pixels between repeated messages)

    /// Minimum gap in pixels.
    static let minGap: Double = 50

    /// Maximum gap in pixels.
    static let maxGap: Double = 500

    /// Default gap in pixels.
    static let defaultGap: Double = 280

    /// The full range the gap Slider is allowed to pick from.
    static let gapRange: ClosedRange<Double> = minGap...maxGap

    // MARK: - Dot size constants (LED text size in pixels)

    /// Minimum LED dot diameter.
    static let minDotSize: Double = 8

    /// Maximum LED dot diameter.
    static let maxDotSize: Double = 32
    

    /// Default LED dot diameter.
    static let defaultDotSize: Double = 28

    /// The full range the dot-size Slider is allowed to pick from.
    static let dotSizeRange: ClosedRange<Double> = minDotSize...maxDotSize

    // MARK: - Stored values

    /// The raw text the user typed. May contain leading/trailing spaces
    /// while typing — we only trim when validating.
    var message: String = ""

    /// Scrolling speed in pixels per second. Set via a Slider in HomeView.
    var speed: Double = defaultSpeed

    /// Empty horizontal space in pixels between repeated messages.
    var gap: Double = defaultGap

    /// Diameter of one LED dot. Drives dot pitch and spacing.
    var dotSize: Double = defaultDotSize

    /// Color of the lit LED dots and their glow. Default red.
    var ledColor: LEDColor = .red

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

    /// Human-readable gap value, e.g. "280 px".
    var formattedGap: String {
        "\(Int(gap)) px"
    }

    /// Human-readable dot size, e.g. "18 px".
    var formattedDotSize: String {
        "\(Int(dotSize)) px"
    }
}
