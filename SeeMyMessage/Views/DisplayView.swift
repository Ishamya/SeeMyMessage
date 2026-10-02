import SwiftUI
import UIKit

/// One copy of the LED message with the glow applied ONCE for the
/// whole copy (not per dot). The old code put .shadow on every one
/// of the 35 dots per character; this is one shadow per message,
/// which is dramatically cheaper on the GPU for the same look.
private struct LEDCopyView: View {
    let message: String
    let dotSize: CGFloat
    let ledColor: LEDColor
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        LEDMessageView(message: message, dotSize: dotSize, ledColor: ledColor)
            .frame(width: width, height: height)
            .shadow(color: ledColor.color.opacity(0.5), radius: dotSize * 0.45)
    }
}

/// Static scrolling strip: all repeated copies in one HStack.
/// Built ONCE per settings/message (outside TimelineView) so the
/// 60fps animation only changes .offset, never rebuilds dots.
private struct LEDStripView: View {
    let message: String
    let repeatCount: Int
    let gap: CGFloat
    let dotSize: CGFloat
    let ledColor: LEDColor
    let copyWidth: CGFloat
    let copyHeight: CGFloat

    var body: some View {
        HStack(spacing: gap) {
            ForEach(0..<repeatCount, id: \.self) { _ in
                LEDCopyView(
                    message: message,
                    dotSize: dotSize,
                    ledColor: ledColor,
                    width: copyWidth,
                    height: copyHeight
                )
            }
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}

/// Full-width scrolling row. Gets containerWidth as a plain
/// value from the parent GeometryReader, so the frame is
/// exactly the landscape screen width.
private struct ScrollContentView: View {
    let message: String
    let charCount: Int
    let speed: Double
    let segmentStart: Date
    let playedElapsed: TimeInterval
    let isPaused: Bool
    let containerWidth: CGFloat
    let containerHeight: CGFloat
    let textWidth: CGFloat
    let gap: CGFloat
    let dotSize: CGFloat
    let ledColor: LEDColor
    let repeatCount: Int
    let period: CGFloat
    let leadCopies: Int
    let origin: CGFloat
    let copyWidth: CGFloat
    let copyHeight: CGFloat

    var body: some View {
        TimelineView(.animation) { context in
            LEDStripView(
                message: message,
                repeatCount: repeatCount,
                gap: gap,
                dotSize: dotSize,
                ledColor: ledColor,
                copyWidth: copyWidth,
                copyHeight: copyHeight
            )
            .offset(x: xOffset(
                now: context.date,
                period: period,
                leadCopies: leadCopies
            ))
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
    /// While paused, elapsed stays frozen so xOffset is constant.
    private func xOffset(now: Date, period: CGFloat, leadCopies: Int) -> CGFloat {
        guard period > 0, charCount > 0 else {
            return containerWidth
        }
        let elapsed = effectiveElapsed(at: now)
        let traveled = CGFloat(speed) * CGFloat(elapsed)
        let wrapped = traveled.truncatingRemainder(dividingBy: period)
        return origin - wrapped
    }

    /// Total played seconds as of `now`: accumulated time from past
    /// play segments plus the current open segment (zero when paused).
    private func effectiveElapsed(at now: Date) -> TimeInterval {
        if isPaused {
            return playedElapsed
        }
        return playedElapsed + max(0, now.timeIntervalSince(segmentStart))
    }
}

/// Full-screen landscape LED board with continuous scrolling.
struct DisplayView: View {
    let settings: DisplaySettings

    /// Dismiss action from the NavigationStack (Exit button).
    @Environment(\.dismiss) private var dismiss

    /// Seconds of played (non-paused) time banked in past segments.
    @State private var playedElapsed: TimeInterval = 0

    /// Start of the current open play segment. Ignored while paused.
    @State private var segmentStart = Date()

    /// True while the LED position is frozen.
    @State private var isPaused = false

    /// True while the Pause/Exit overlay is on screen.
    @State private var controlsVisible = false

    /// Bumps on every show/interaction; stale hide tasks exit early.
    @State private var hideToken = 0

    /// Nanoseconds of no interaction before the overlay auto-hides (3s).
    private static let autoHideDelay: UInt64 = 3_000_000_000

    private var displayMessage: String {
        settings.message.replacingOccurrences(of: "\n", with: " ")
    }

    var body: some View {
        // Normalized count for measurement (cheap Int math).
        // Full chars are normalized inside LEDMessageView per copy.
        let charCount = LEDFont.normalized(displayMessage).count
        let dotSize = CGFloat(settings.dotSize)
        let gap = CGFloat(settings.gap)
        let textWidth = LEDStyle.messageWidth(forChars: charCount, dotSize: dotSize)
        let copyWidth = textWidth
        let copyHeight = LEDStyle.characterHeight(for: dotSize)

        ZStack {
            Color.black
                .ignoresSafeArea()

            GeometryReader { geo in
                // Geometry-dependent values computed OUTSIDE the
                // TimelineView closure: period/copies/origin are fixed
                // for a given message + settings + container size.
                // The 60fps animation only recomputes xOffset.
                let containerWidth = geo.size.width
                let period: CGFloat = textWidth + gap
                let leadCopies: Int = {
                    guard period > 0 else { return 2 }
                    return Int(ceil(containerWidth / period)) + 1
                }()
                let repeatCount: Int = {
                    guard period > 0 else { return 6 }
                    let needed = Int(ceil((containerWidth + textWidth + gap) / period)) + leadCopies + 2
                    return min(max(needed, 6), 20)
                }()
                let origin = containerWidth - period * CGFloat(leadCopies)
                ScrollContentView(
                    message: displayMessage,
                    charCount: charCount,
                    speed: settings.speed,
                    segmentStart: segmentStart,
                    playedElapsed: playedElapsed,
                    isPaused: isPaused,
                    containerWidth: containerWidth,
                    containerHeight: geo.size.height,
                    textWidth: textWidth,
                    gap: gap,
                    dotSize: dotSize,
                    ledColor: settings.ledColor,
                    repeatCount: repeatCount,
                    period: period,
                    leadCopies: leadCopies,
                    origin: origin,
                    copyWidth: copyWidth,
                    copyHeight: copyHeight
                )
            }
            .ignoresSafeArea()

            // Tap anywhere to reveal controls (or reset hide timer).
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    if controlsVisible {
                        pokeHideTimer()
                    } else {
                        showControls()
                    }
                }

            // Minimal overlay: Exit top-right, Pause bottom-center.
            if controlsVisible {
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            pokeHideTimer()
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.title2.weight(.bold))
                                .foregroundStyle(.white)
                                .frame(width: 48, height: 48)
                                .background(.black.opacity(0.55))
                                .clipShape(Circle())
                        }
                        .accessibilityLabel("Exit display")
                    }
                    .padding(.top, 12)
                    .padding(.trailing, 16)

                    Spacer()

                    Button {
                        togglePause()
                    } label: {
                        Label(
                            isPaused ? "Resume" : "Pause",
                            systemImage: isPaused ? "play.fill" : "pause.fill"
                        )
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(.black.opacity(0.55))
                        .clipShape(Capsule())
                    }
                    .accessibilityLabel(isPaused ? "Resume" : "Pause")
                    .padding(.bottom, 24)
                }
                .transition(.opacity)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(controlsVisible ? .visible : .hidden, for: .navigationBar)
        .animation(.easeInOut(duration: 0.2), value: controlsVisible)
        .onAppear {
            segmentStart = Date()
            OrientationLock.lock(to: .landscape)
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            // Policy only: physical rotation is requested from
            // HomeView.onAppear, after the transition finishes.
            OrientationLock.noteReturnedToNormalPolicy()
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    // MARK: - Controls + pause timing

    /// Reveals the overlay and (re)starts the 3-second auto-hide.
    private func showControls() {
        controlsVisible = true
        pokeHideTimer()
    }

    /// Resets the 3-second auto-hide window. Old tasks carry a stale
    /// token and exit without hiding, so no polling is needed.
    private func pokeHideTimer() {
        hideToken += 1
        let token = hideToken
        Task {
            try? await Task.sleep(nanoseconds: Self.autoHideDelay)
            if !Task.isCancelled, token == hideToken {
                controlsVisible = false
            }
        }
    }

    /// Freezes or resumes the LED. Pausing banks the open segment
    /// into playedElapsed; resuming opens a fresh segment from now.
    /// Paused time is never added, so resume has zero jump.
    private func togglePause() {
        if isPaused {
            segmentStart = Date()
            isPaused = false
        } else {
            playedElapsed += max(0, Date().timeIntervalSince(segmentStart))
            isPaused = true
        }
        pokeHideTimer()
    }
}

#Preview {
    DisplayView(settings: DisplaySettings(message: "HELLO WORLD", speed: 80))
}
