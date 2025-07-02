import Foundation
import FirebaseAuth
import Combine

class AuthViewModel: ObservableObject {
    @Published var isSignedIn: Bool = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var error: String?

    private var handle: AuthStateDidChangeListenerHandle?
    private let firebaseService: FirebaseService
    private let migrationService = MigrationService()

    init(firebaseService: FirebaseService) {
        self.firebaseService = firebaseService
        // Listen for auth state changes
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.isSignedIn = (user != nil)
            if user != nil {
                self?.handleUserSignIn()
            } else {
                self?.currentUser = nil
            }
        }
        // Set initial state
        self.isSignedIn = Auth.auth().currentUser != nil
        // Do NOT call handleUserSignIn() here!
    }

    deinit {
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    private func handleUserSignIn() {
        isLoading = true
        error = nil
        
        // First create user if needed, then check for cloud visits before migrating
        firebaseService.createUserIfNeeded { [weak self] success in
            guard success else {
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.error = "Failed to initialize user account"
                }
                return
            }
            // Check if user already has visits in Firestore
            self?.firebaseService.hasAnyUserVisits { hasVisits in
                if hasVisits {
                    // Cloud data exists, do not migrate
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        print("✅ User already has cloud visits, skipping migration.")
                    }
                } else {
                    // Only migrate if there are no cloud visits
                    self?.migrationService.migrateLocalVisitsToFirebase { migrationSuccess in
                        DispatchQueue.main.async {
                            self?.isLoading = false
                            if migrationSuccess {
                                print("✅ User setup and migration completed successfully")
                            } else {
                                print("⚠️ User setup completed but migration failed or no data to migrate")
                            }
                        }
                    }
                }
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            self.error = "Failed to sign out: \(error.localizedDescription)"
        }
    }
} 