import SwiftUI

/// The first screen of the app: type a message, pick a speed, press START.
///
/// Phase 2 scope only: input + speed + validation.
/// No navigation, no scrolling, no display screen yet.
struct HomeView: View {

    // Single source of truth for everything on this screen.
    // Because DisplaySettings is a struct (value type), @State can own it
    // and re-render this view whenever any of its fields change.
    @State private var settings = DisplaySettings()

    var body: some View {
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

            // MARK: - Start button

            Button("START") {
                // Phase 3 will navigate to the display screen.
                // For now this just proves the button was enabled.
                print("START pressed: \"\(settings.trimmedMessage)\" at \(settings.formattedSpeed)")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            // Disabled when the message is empty or whitespace-only.
            .disabled(!settings.isValid)

            Spacer()
        }
        .padding()
    }
}

#Preview {
    HomeView()
}
