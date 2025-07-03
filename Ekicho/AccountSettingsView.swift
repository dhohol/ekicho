import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct AccountSettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var dataStore: FirebaseDataStore
    @State private var selectedCity = "tokyo"
    @State private var isSigningOut = false
    
    private let cities = [
        ("tokyo", "Tokyo")
    ]
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Location")) {
                    Picker("City", selection: $selectedCity) {
                        ForEach(cities, id: \.0) { city in
                            Text(city.1).tag(city.0)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: selectedCity) { newCity in
                        updateUserCity(cityId: newCity)
                    }
                }
                
                Section {
                    Button(action: signOut) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                            Text("Sign Out")
                                .foregroundColor(.red)
                            Spacer()
                            if isSigningOut {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .disabled(isSigningOut)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private func updateUserCity(cityId: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let userRef = dataStore.firebaseService.db.collection("users").document(userId)
        userRef.updateData([
            "current_city_id": cityId,
            "last_updated_at": FieldValue.serverTimestamp()
        ]) { error in
            // print("❌ Error updating user city: \(error)")
        }
    }
    
    private func signOut() {
        isSigningOut = true
        
        // Update last_signed_out_at in Firestore
        if let userId = Auth.auth().currentUser?.uid {
            let userRef = dataStore.firebaseService.db.collection("users").document(userId)
            userRef.updateData([
                "last_signed_out_at": FieldValue.serverTimestamp()
            ]) { error in
                // print("❌ Error updating last_signed_out_at: \(error)")
                
                // Sign out from Firebase Auth
                DispatchQueue.main.async {
                    authViewModel.signOut()
                    isSigningOut = false
                }
            }
        } else {
            // If no user ID, just sign out
            authViewModel.signOut()
            isSigningOut = false
        }
    }
}

#if DEBUG
struct AccountSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        let firebaseService = FirebaseService()
        let authViewModel = AuthViewModel(firebaseService: firebaseService)
        let dataStore = FirebaseDataStore(firebaseService: firebaseService)
        
        AccountSettingsView()
            .environmentObject(authViewModel)
            .environmentObject(dataStore)
    }
}
#endif 