import SwiftUI

/// The first screen of the app: type a message, pick a speed, press START.
struct HomeView: View {

    // Single source of truth for everything on this screen.
    // Because DisplaySettings is a struct (value type), @State can own it
    // and re-render this view whenever any of its fields change.
    @State private var settings = DisplaySettings()

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // MARK: - Title

                Text("SeeMyMessage")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Turn your iPhone into a scrolling LED display")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                // MARK: - Message input

                TextField(
                    "Type your message...",
                    text: $settings.message,
                    axis: .vertical
                )
                .lineLimit(3...5)
                .textFieldStyle(.roundedBorder)
                .font(.title3)
                // Submit button on the keyboard dismisses it.
                .submitLabel(.done)
                .accessibilityLabel("Message")

                // MARK: - Speed control

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Scroll speed")
                            .font(.headline)
                        Spacer()
                        // e.g. "Normal • 80 px/s"
                        Text("\(settings.speedCategory) • \(settings.formattedSpeed)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }

                    Slider(
                        value: $settings.speed,
                        in: DisplaySettings.speedRange,
                        step: 1
                    )
                    // Accessibility label so VoiceOver reads the value.
                    .accessibilityLabel("Scroll speed")
                    .accessibilityValue(settings.formattedSpeed)

                    HStack {
                        Text("Slow")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("Fast")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // MARK: - Advanced settings

                DisclosureGroup("Advanced Settings") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("LED Text Size")
                                .font(.headline)
                            Spacer()
                            Text(settings.formattedDotSize)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }

                        Slider(
                            value: $settings.dotSize,
                            in: DisplaySettings.dotSizeRange,
                            step: 1
                        )
                        .accessibilityLabel("LED text size")
                        .accessibilityValue(settings.formattedDotSize)

                        HStack {
                            Text("\(Int(DisplaySettings.minDotSize))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(Int(DisplaySettings.maxDotSize))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 8)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Message Gap")
                                .font(.headline)
                            Spacer()
                            Text(settings.formattedGap)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }

                        Slider(
                            value: $settings.gap,
                            in: DisplaySettings.gapRange,
                            step: 10
                        )
                        .accessibilityLabel("Message gap")
                        .accessibilityValue(settings.formattedGap)

                        HStack {
                            Text("\(Int(DisplaySettings.minGap))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(Int(DisplaySettings.maxGap))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 8)
                }

                // MARK: - Start button (top-right toolbar)

                // The in-body START button was removed: START now lives
                // in the navigation toolbar (top-right) below. It uses
                // the same destination + validation, so behavior is
                // unchanged — only the position is intentional.
                // Extra breathing room now that the in-body START is gone.
                Spacer(minLength: 12)
            }
            .padding()
            .navigationTitle("SeeMyMessage")
            .navigationBarTitleDisplayMode(.inline)
            // START top-right: always visible, proper touch target,
            // same navigation + disabled(!isValid) validation.
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        DisplayView(settings: settings)
                    } label: {
                        Text("START")
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                    .disabled(!settings.isValid)
                }
            }
            .onAppear {
                // Runs after returning from Display (post-transition).
                // Deferred one runloop so the navigation animation has
                // finished before iOS is asked to rotate.
                DispatchQueue.main.async {
                    OrientationLock.restoreHomeOrientation()
                }
            }
        }
    }
}

#Preview {
    HomeView()
}
