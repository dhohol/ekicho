import SwiftUI

struct DiscoverView: View {
    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)
                
                Text("Under Construction 🚧")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Come back soon!")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .navigationTitle("Discover")
        .navigationBarTitleDisplayMode(.large)
    }
}

#if DEBUG
struct DiscoverView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DiscoverView()
        }
    }
}
#endif 