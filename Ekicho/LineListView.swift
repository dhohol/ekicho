import SwiftUI

// MARK: - LineListView
struct LineListView: View {
    @StateObject private var store = EkichoDataStore()
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(spacing: 20) {
                    ForEach(store.lines) { line in
                        NavigationLink(destination: StationListView(line: line, store: store)) {
                            LineCardView(
                                line: line,
                                visitedCount: store.visitedStationCount(for: line)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.vertical, 24)
                .padding(.horizontal, 20)
            }
            .navigationTitle("Ekicho")
        }
    }
}

// MARK: - LineCardView
struct LineCardView: View {
    let line: TrainLine
    let visitedCount: Int
    
    private var progress: Double {
        guard line.stationIDs.count > 0 else { return 0 }
        return Double(visitedCount) / Double(line.stationIDs.count)
    }
    
    var body: some View {
        HStack(spacing: 20) {
            if let iconName = line.iconAssetName {
                Image(iconName)
                    .resizable()
                    .scaledToFit()
                    .padding(4) // Add spacing inside the 36x36 frame
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.white)) // optional
                    .clipShape(Circle())
                    .shadow(radius: 2)
            } else {
                ZStack {
                    Circle()
                        .fill(line.color)
                        .frame(width: 36, height: 36)
                        .shadow(radius: 2)
                    Text(line.symbol ?? "")
                        .font(.caption2)
                        .bold()
                        .foregroundColor(.white)
                }
            }
            VStack(alignment: .leading, spacing: 8) {
                Text(line.name)
                    .font(.headline)
                Text("\(visitedCount) of \(line.stationIDs.count) stations visited")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                ProgressView(value: progress)
                    .accentColor(line.color)
            }
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color(.black).opacity(0.07), radius: 6, x: 0, y: 2)
    }
}

#Preview {
    LineListView()
} 
