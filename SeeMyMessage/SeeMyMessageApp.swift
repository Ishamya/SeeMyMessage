//
//  SeeMyMessageApp.swift
//  SeeMyMessage
//
//  Created by Ishamya Fernando on 2026-10-02.
//

import SwiftUI
import UIKit

/// Receives `supportedInterfaceOrientationsFor` callbacks and
/// returns whatever OrientationLock currently allows.
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        OrientationLock.mask
    }
}

@main
struct SeeMyMessageApp: App {
    // Bridges the AppDelegate above into SwiftUI.
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
    }
}


