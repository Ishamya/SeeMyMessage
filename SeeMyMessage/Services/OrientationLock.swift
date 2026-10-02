import Foundation
import UIKit

/// Controls which orientations the app allows right now.
///
/// Home = all iPhone orientations (portrait + landscape).
/// Display = landscape only. Restored on exit.
enum OrientationLock {
    /// Current mask read by the AppDelegate.
    static var mask: UIInterfaceOrientationMask = .allButUpsideDown

    /// Restrict to the given mask and ask the window scene to rotate.
    static func lock(to mask: UIInterfaceOrientationMask) {
        Self.mask = mask
        apply(mask)
    }

    /// Restore normal behavior (portrait + landscape, no upside-down).
    static func unlock() {
        lock(to: .allButUpsideDown)
    }

    /// Asks the active window scene to rotate to the new mask.
    /// Uses the modern UIWindowScene API (no deprecated UIDevice hack).
    private static func apply(_ mask: UIInterfaceOrientationMask) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return
        }
        let prefs = UIWindowScene.GeometryPreferences.iOS(
            interfaceOrientations: mask
        )
        scene.requestGeometryUpdate(prefs)
    }
}
