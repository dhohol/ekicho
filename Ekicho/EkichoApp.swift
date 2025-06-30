//
//  EkichoApp.swift
//  Ekicho
//
//  Created by Daniele Hohol on 6/10/25.
//

import SwiftUI
import FirebaseCore

// Step 1: Create AppDelegate class
class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    print("✅ Firebase configured via AppDelegate")
    return true
  }
}

// Step 2: Use @UIApplicationDelegateAdaptor to register it
@main
struct EkichoApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

  var body: some Scene {
    WindowGroup {
        SignInView() // Your root view
    }
  }
}
