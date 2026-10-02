import SwiftUI

/// One full single-line LED message, drawn as a single Canvas.
///
/// Replaces the old per-dot Circle view hierarchy: one Canvas draws
/// every dot with fillCircle, so a 60fps scroll costs one lightweight
/// draw per copy instead of thousands of view updates.
/// Glow is applied once per copy by LEDCopyView in DisplayView.
struct LEDMessageView: View {
    let message: String
    let dotSize: CGFloat
    let ledColor: LEDColor

    var body: some View {
        let chars = LEDFont.normalizedChars(message)
        let width = LEDStyle.messageWidth(
            forChars: chars.count,
            dotSize: dotSize
        )
        let height = LEDStyle.characterHeight(for: dotSize)
        let pitch = LEDStyle.dotPitch(for: dotSize)
        let charWidth = LEDStyle.characterWidth(for: dotSize)
        // Resolve once per body evaluation (static while scrolling),
        // not per dot or per frame — keeps the 60fps path cheap.
        let lit = ledColor.color
        let unlit = ledColor.color.opacity(0.07)
        Canvas { context, _ in
            for (index, char) in chars.enumerated() {
                let mask = LEDFont.mask(forNormalized: char)
                let baseX = CGFloat(index) * charWidth
                for row in 0..<LEDStyle.rows {
                    for col in 0..<LEDStyle.columns {
                        let bit = (mask >> (row * LEDStyle.columns + col)) & 1
                        let circle = Path(ellipseIn: CGRect(
                            x: baseX + CGFloat(col) * pitch,
                            y: CGFloat(row) * pitch,
                            width: dotSize,
                            height: dotSize
                        ))
                        if bit == 1 {
                            context.fill(circle, with: .color(lit))
                        } else {
                            context.fill(circle, with: .color(unlit))
                        }
                    }
                }
            }
        }
        .frame(width: max(width, 0), height: height)
        .fixedSize(horizontal: true, vertical: false)
    }
}
