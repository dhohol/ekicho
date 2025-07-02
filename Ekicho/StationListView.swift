import SwiftUI

struct StationListView: View {
    let line: Line
    @EnvironmentObject var store: FirebaseDataStore
    
    private var visitedCount: Int {
        store.visitedStationCount(for: line)
    }
    
    private var progress: Double {
        guard !line.station_ids.isEmpty else { return 0 }
        return Double(visitedCount) / Double(line.station_ids.count)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text(line.name)
                    .font(.title2)
                    .bold()
                Text("\(visitedCount) of \(line.station_ids.count) visited")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                ProgressView(value: progress)
                    .accentColor(line.color)
            }
            .padding(.horizontal)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
            
            // Station List
            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(spacing: 0) {
                    ForEach(line.station_ids, id: \.self) { stationID in
                        if let station = store.stations[stationID] {
                            Button(action: {
                                store.toggleVisited(station: station)
                            }) {
                                HStack {
                                    if store.visitedStationIDs.contains(station.station_id) {
                                        Text(station.name)
                                            .strikethrough()
                                            .foregroundColor(.secondary)
                                    } else {
                                        Text(station.name)
                                            .foregroundColor(.primary)
                                    }
                                    Spacer()
                                    if store.visitedStationIDs.contains(station.station_id) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color(.systemBackground))
                            }
                            .buttonStyle(PlainButtonStyle())
                            Divider()
                                .padding(.leading, 56)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle(line.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if DEBUG
struct StationListView_Previews: PreviewProvider {
    static var previews: some View {
        let firebaseService = FirebaseService()
        let store = FirebaseDataStore(firebaseService: firebaseService)
        let sampleLine = Line(
            line_id: "sample",
            name: "Sample Line",
            company: "Sample Company",
            city_id: "tokyo",
            line_symbol: "SL",
            color_name: "blue",
            color_hex: "#007AFF",
            shape: "circle",
            icon_asset_name: "",
            station_ids: ["station1", "station2"],
            is_active: true
        )
        return NavigationView {
            StationListView(line: sampleLine)
                .environmentObject(store)
        }
    }
}
#endif 