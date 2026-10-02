import SwiftUI

/// The first screen of the app: type a message, pick a speed, press START.
///
/// Phase 3: input + speed + validation + navigation to DisplayView.
/// Still no scrolling — DisplayView is static in this phase.
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
                        .accessibilityValue(settings.formattedDotSize)

                        HStack {
                            Text("8")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("28")
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
                        .accessibilityValue(settings.formattedGap)

                        HStack {
                            Text("50")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("500")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 8)
                }

                // MARK: - Start button

                // Navigates to DisplayView, passing a copy of settings.
                // Disabled when the message is empty or whitespace-only.
                NavigationLink {
                    DisplayView(settings: settings)
                } label: {
                    Text("START")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!settings.isValid)

                Spacer()
            }
            .padding()
            .navigationTitle("SeeMyMessage")
            .navigationBarTitleDisplayMode(.inline)
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
