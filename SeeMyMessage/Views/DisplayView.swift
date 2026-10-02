import SwiftUI
import UIKit

/// Full-width scrolling row. Gets containerWidth as a plain
/// value from the parent GeometryReader, so the frame is
/// exactly the landscape screen width.
private struct ScrollContentView: View {
    let displayMessage: String
    let speed: Double
    let segmentStart: Date
    let playedElapsed: TimeInterval
    let isPaused: Bool
    let containerWidth: CGFloat
    let containerHeight: CGFloat
    let textWidth: CGFloat
    let gap: CGFloat
    let dotSize: CGFloat

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
                    LEDMessageView(message: displayMessage, dotSize: dotSize)
                }
            }
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
        guard period > 0, !displayMessage.isEmpty else {
            return containerWidth
        }
        let origin = containerWidth - period * CGFloat(leadCopies)
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
        ZStack {
            Color.black
                .ignoresSafeArea()

            GeometryReader { geo in
                // Configurable gap + dot size from Advanced Settings.
                let gap = CGFloat(settings.gap)
                let dotSize = CGFloat(settings.dotSize)
                // Measured LED width: exact math for the dot-matrix
                // message, so scrolling matches what is rendered.
                let textWidth = LEDStyle.messageWidth(
                    for: displayMessage,
                    dotSize: dotSize
                )
                ScrollContentView(
                    displayMessage: displayMessage,
                    speed: settings.speed,
                    segmentStart: segmentStart,
                    playedElapsed: playedElapsed,
                    isPaused: isPaused,
                    containerWidth: geo.size.width,
                    containerHeight: geo.size.height,
                    textWidth: textWidth,
                    gap: gap,
                    dotSize: dotSize
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
