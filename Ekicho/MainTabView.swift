import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            LineListView()
                .tabItem {
                    Image(systemName: "tram.fill")
                    Text("Lines")
                }
            
            DiscoverView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Discover")
                }
            
            AccountSettingsView()
                .tabItem {
                    Image(systemName: "person.crop.circle")
                    Text("Settings")
                }
        }
    }
}

#if DEBUG
struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        let firebaseService = FirebaseService()
        let authViewModel = AuthViewModel(firebaseService: firebaseService)
        let dataStore = FirebaseDataStore(firebaseService: firebaseService)
        
        MainTabView()
            .environmentObject(dataStore)
            .environmentObject(authViewModel)
    }
}
#endif 