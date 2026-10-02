import Foundation
import CoreGraphics

/// Central place for every LED size number so the sign can be
/// tuned without digging through view code.
///
/// All dimensions derive from the selected dot diameter so the
/// rendered dots and the measured width always agree.
enum LEDStyle {
    /// Fixed character grid. 5 wide x 7 tall reads well at sign size.
    static let columns = 5
    static let rows = 7

    /// Center-to-center distance between neighbouring dots.
    /// Keeps a 5pt gutter so dots never touch at any size.
    static func dotPitch(for dotSize: CGFloat) -> CGFloat {
        dotSize + 5
    }

    /// Space between two characters (edge to edge, in points).
    static func characterSpacing(for dotSize: CGFloat) -> CGFloat {
        dotSize + 7
    }

    /// Width of one fixed-width character cell for a dot size.
    /// = (columns - 1) * pitch + dotSize + spacing
    static func characterWidth(for dotSize: CGFloat) -> CGFloat {
        CGFloat(columns - 1) * dotPitch(for: dotSize)
            + dotSize
            + characterSpacing(for: dotSize)
    }

    /// Height of one character cell for a dot size.
    static func characterHeight(for dotSize: CGFloat) -> CGFloat {
        CGFloat(rows - 1) * dotPitch(for: dotSize) + dotSize
    }

    /// Exact rendered width of a normalized LED message at a dot size.
    /// Matches LEDMessageView: N chars x width minus one spacing.
    static func messageWidth(for message: String, dotSize: CGFloat) -> CGFloat {
        let normalized = LEDFont.normalized(message)
        guard !normalized.isEmpty else { return 0 }
        return CGFloat(normalized.count) * characterWidth(for: dotSize)
            - characterSpacing(for: dotSize)
    }
}
