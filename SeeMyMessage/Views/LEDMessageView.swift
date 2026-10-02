import SwiftUI

/// One LED dot: bright red circle with a soft glow.
/// Unlit positions render as an extremely dim dot so the
/// board keeps a physical panel feel without hurting contrast.
struct LEDDotView: View {
    let isLit: Bool
    let dotSize: CGFloat

    var body: some View {
        Circle()
            .fill(isLit ? Color.red : Color.red.opacity(0.07))
            .frame(width: dotSize, height: dotSize)
            .shadow(
                color: isLit ? Color.red.opacity(0.65) : Color.clear,
                radius: isLit ? dotSize * 0.45 : 0
            )
    }
}

/// One fixed-width 5x7 character built from LED dots.
struct LEDCharacterView: View {
    let character: Character
    let dotSize: CGFloat

    var body: some View {
        let rows = LEDFont.rows(for: character)
        let pitch = LEDStyle.dotPitch(for: dotSize)
        VStack(spacing: pitch - dotSize) {
            ForEach(0..<LEDStyle.rows, id: \.self) { row in
                HStack(spacing: pitch - dotSize) {
                    ForEach(0..<LEDStyle.columns, id: \.self) { col in
                        LEDDotView(
                            isLit: isRowLit(rows, row: row, col: col),
                            dotSize: dotSize
                        )
                    }
                }
            }
        }
    }

    private func isRowLit(_ rows: [String], row: Int, col: Int) -> Bool {
        guard row < rows.count else { return false }
        let line = Array(rows[row])
        guard col < line.count else { return false }
        return line[col] == "1"
    }
}

/// One full single-line LED message: fixed-width characters in a row.
struct LEDMessageView: View {
    let message: String
    let dotSize: CGFloat

    var body: some View {
        let chars = Array(LEDFont.normalized(message))
        HStack(spacing: LEDStyle.characterSpacing(for: dotSize)) {
            ForEach(0..<chars.count, id: \.self) { index in
                LEDCharacterView(character: chars[index], dotSize: dotSize)
            }
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}
