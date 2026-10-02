import SwiftUI

/// Full-screen LED board. Phase 3 is static only: no scrolling,
/// no timers, no animation. Just a centered red message on black.
struct DisplayView: View {

    /// A copy of the settings from HomeView. `let` because the
    /// display never edits them in Phase 3 — it only reads them.
    let settings: DisplaySettings

    var body: some View {
        ZStack {
            // Layer 1 (back): solid black that fills the whole screen,
            // including under the notch / home indicator.
            Color.black
                .ignoresSafeArea()

            // Layer 2 (front): the message, centered by the ZStack.
            Text(settings.trimmedMessage)
                .font(.system(size: 72, weight: .heavy, design: .monospaced))
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
                // Shrink very long messages instead of clipping them.
                .minimumScaleFactor(0.3)
                .padding()
        }
        // Keep the standard iOS Back button so the user can return
        // to HomeView. Custom controls come in Phase 5.
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    DisplayView(settings: DisplaySettings(message: "HELLO WORLD", speed: 80))
}
