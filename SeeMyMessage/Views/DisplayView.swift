import SwiftUI
import UIKit

/// Reads the natural width of one LED message copy.
private struct TextWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

/// Full-width scrolling row. Gets containerWidth as a plain
/// value from the parent GeometryReader, so the frame is
/// exactly the landscape screen width (fixes half-screen bug).
private struct ScrollContentView: View {
    let displayMessage: String
    let speed: Double
    let startDate: Date
    let containerWidth: CGFloat
    let containerHeight: CGFloat
    let textWidth: CGFloat
    let font: Font
    let gap: CGFloat

    var body: some View {
        // One copy = message + trailing gap. The strip repeats this
        // period, so wrapping by exactly one period is invisible.
        let period: CGFloat = textWidth + gap
        // Copies placed LEFT of the entering copy at t=0, so the
        // viewport is never blank — even for tiny messages like "HI".
        // Dynamic: enough to reach back past the left edge.
        let leadCopies: Int = {
            guard period > 0 else { return 2 }
            return Int(ceil(containerWidth / period)) + 1
        }()
        // Total copies: enough to span the screen + full travel.
        let repeatCount: Int = {
            guard period > 0 else { return 6 }
            let needed = Int(ceil((containerWidth + textWidth + gap) / period)) + leadCopies + 2
            return min(max(needed, 6), 20)
        }()

        TimelineView(.animation) { context in
            HStack(spacing: gap) {
                ForEach(0..<repeatCount, id: \.self) { _ in
                    Text(displayMessage)
                        .font(font)
                        .foregroundStyle(.red)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
            }
            .offset(x: xOffset(now: context.date, period: period, leadCopies: leadCopies))
            .frame(
                width: containerWidth,
                height: containerHeight,
                alignment: .leading
            )
            .clipped()
        }
    }

    /// position(t) = origin - speed * elapsed, wrapped by one period.
    /// origin = containerWidth - (textWidth + gap) * leadCopies places
    /// copy #1 fully right of the screen at t=0 while lead copies
    /// keep the viewport covered for seamless entry.
    private func xOffset(now: Date, period: CGFloat, leadCopies: Int) -> CGFloat {
        guard period > 0, !displayMessage.isEmpty else {
            return containerWidth
        }
        let origin = containerWidth - period * CGFloat(leadCopies)
        let elapsed = max(0, now.timeIntervalSince(startDate))
        let traveled = CGFloat(speed) * CGFloat(elapsed)
        let wrapped = traveled.truncatingRemainder(dividingBy: period)
        return origin - wrapped
    }
}

/// Full-screen landscape LED board with continuous scrolling.
struct DisplayView: View {
    let settings: DisplaySettings

    private static let ledFont: Font = .system(size: 120, weight: .heavy, design: .monospaced)

    @State private var textWidth: CGFloat = 0
    @State private var startDate = Date()

    private var displayMessage: String {
        settings.message.replacingOccurrences(of: "\n", with: " ")
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            GeometryReader { geo in
                // Configurable gap from Home's Advanced Settings.
                let gap = CGFloat(settings.gap)
                ScrollContentView(
                    displayMessage: displayMessage,
                    speed: settings.speed,
                    startDate: startDate,
                    containerWidth: geo.size.width,
                    containerHeight: geo.size.height,
                    textWidth: textWidth,
                    font: Self.ledFont,
                    gap: gap
                )
            }
            .ignoresSafeArea()

            Text(displayMessage)
                .font(Self.ledFont)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .hidden()
                .background(
                    GeometryReader { textGeo in
                        Color.clear.preference(
                            key: TextWidthKey.self,
                            value: textGeo.size.width
                        )
                    }
                )
                .onPreferenceChange(TextWidthKey.self) { newWidth in
                    textWidth = newWidth
                }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            startDate = Date()
            OrientationLock.lock(to: .landscape)
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            OrientationLock.unlock()
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
}

#Preview {
    DisplayView(settings: DisplaySettings(message: "HELLO WORLD", speed: 80))
}
