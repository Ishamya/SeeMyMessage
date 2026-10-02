import Foundation
import UIKit

/// Desired orientation policy for the whole app.
///
/// - normal: Home policy (portrait + landscape, no upside-down).
/// - landscape: Display policy (landscape only).
enum AppOrientationMode {
    case normal
    case landscape
}

/// Controls which orientations the app allows right now.
///
/// Home = normal policy. Display = landscape policy.
/// The AppDelegate returns `mask` for the current `mode`.
/// Rotation requests use the modern UIWindowScene API only.
enum OrientationLock {
    /// Current desired policy. Single source of truth.
    static var mode: AppOrientationMode = .normal

    /// Current mask read by the AppDelegate. Derived from `mode`
    /// so policy and mask can never disagree.
    static var mask: UIInterfaceOrientationMask {
        switch mode {
        case .normal:
            return .allButUpsideDown
        case .landscape:
            return .landscape
        }
    }

    /// Enter landscape: set policy AND request landscape.
    /// Called from DisplayView.onAppear (already visible, so honored).
    static func lock(to mask: UIInterfaceOrientationMask) {
        if mask == .landscape {
            mode = .landscape
        } else {
            mode = .normal
        }
        requestRotation(to: mask)
    }

    /// Record that we left Display WITHOUT requesting rotation.
    /// The real portrait request happens from HomeView.onAppear,
    /// after the navigation transition has finished.
    static func noteReturnedToNormalPolicy() {
        mode = .normal
    }

    /// Restore Home: set permissive policy AND request portrait.
    /// Called from HomeView.onAppear (deferred one runloop).
    /// Mask stays .allButUpsideDown so Home remains freely rotatable.
    static func restoreHomeOrientation() {
        mode = .normal
        requestRotation(to: .portrait)
    }

    /// Backwards-compatible alias. Prefer restoreHomeOrientation()
    /// from Home, and noteReturnedToNormalPolicy() from Display.
    static func unlock() {
        restoreHomeOrientation()
    }

    /// Requests rotation on the foreground-active window scene.
    /// Must run on the main thread. Logs geometry errors via print
    /// so physical-device failures are diagnosable.
    private static func requestRotation(to orientations: UIInterfaceOrientationMask) {
        let applyRequest = {
            let scenes = UIApplication.shared.connectedScenes
            let scene = (scenes.first(where: { $0.activationState == .foregroundActive })
                ?? scenes.first) as? UIWindowScene
            guard let scene else {
                print("[OrientationLock] no window scene for \(orientations)")
                return
            }
            let prefs = UIWindowScene.GeometryPreferences.iOS(
                interfaceOrientations: orientations
            )
            scene.requestGeometryUpdate(prefs) { error in
                print("[OrientationLock] requestGeometryUpdate to \(orientations) failed: \(error)")
            }
        }
        if Thread.isMainThread {
            applyRequest()
        } else {
            DispatchQueue.main.async(execute: applyRequest)
        }
    }
}

