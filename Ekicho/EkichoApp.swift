//
//  EkichoApp.swift
//  Ekicho
//
//  Created by Daniele Hohol on 6/10/25.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth

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
  @State private var isFirebaseReady = false

  var body: some Scene {
    WindowGroup {
      if isFirebaseReady {
        EkichoRootView()
      } else {
        ProgressView("Loading...")
          .onAppear {
            DispatchQueue.main.async {
              self.isFirebaseReady = true
            }
          }
      }
    }
  }
}

struct EkichoRootView: View {
  @StateObject private var firebaseService = FirebaseService()
  @StateObject private var authViewModel: AuthViewModel
  @StateObject private var dataStore: FirebaseDataStore

  init() {
    let firebaseService = FirebaseService()
    _firebaseService = StateObject(wrappedValue: firebaseService)
    _authViewModel = StateObject(wrappedValue: AuthViewModel(firebaseService: firebaseService))
    _dataStore = StateObject(wrappedValue: FirebaseDataStore(firebaseService: firebaseService))
  }

  var body: some View {
    if authViewModel.isSignedIn {
      MainTabView()
        .environmentObject(dataStore)
        .environmentObject(authViewModel)
    } else {
      SignInView(authViewModel: authViewModel)
    }
  }
}
