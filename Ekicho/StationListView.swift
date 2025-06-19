import SwiftUI

struct StationListView: View {
    let lineName: String
    let stations: [String]
    @State private var visitedStationNames: Set<String> = []
    private let userDefaultsKey = "visitedStations"
    
    var visitedCount: Int {
        visitedStationNames.intersection(stations).count
    }
    
    var progress: Double {
        guard !stations.isEmpty else { return 0 }
        return Double(visitedCount) / Double(stations.count)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text(lineName)
                    .font(.title2)
                    .bold()
                Text("\(visitedCount) of \(stations.count) visited")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                ProgressView(value: progress)
            }
            .padding(.horizontal)
            
            // Station List
            List {
                ForEach(Array(stations.enumerated()), id: \.offset) { index, name in
                    Button(action: {
                        toggleVisited(stationName: name)
                    }) {
                        HStack {
                            Text("\(index + 1). ")
                                .foregroundColor(.secondary)
                            if visitedStationNames.contains(name) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text(name)
                                    .strikethrough()
                                    .foregroundColor(.secondary)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.gray)
                                Text(name)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .animation(.default, value: visitedStationNames)
        }
        .onAppear(perform: loadVisitedStations)
        .navigationTitle(lineName)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func loadVisitedStations() {
        if let saved = UserDefaults.standard.array(forKey: userDefaultsKey) as? [String] {
            visitedStationNames = Set(saved)
        }
    }
    
    private func saveVisitedStations() {
        UserDefaults.standard.set(Array(visitedStationNames), forKey: userDefaultsKey)
    }
    
    private func toggleVisited(stationName: String) {
        if visitedStationNames.contains(stationName) {
            visitedStationNames.remove(stationName)
        } else {
            visitedStationNames.insert(stationName)
        }
        saveVisitedStations()
    }
}

#if DEBUG
struct StationListView_Previews: PreviewProvider {
    static var previews: some View {
        StationListView(
            lineName: "JR Yamanote Line",
            stations: ["Shibuya", "Ebisu", "Meguro", "Shinagawa"]
        )
    }
}
#endif 
