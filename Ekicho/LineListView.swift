import SwiftUI

// MARK: - TrainLine Model
struct TrainLine: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let colorName: String // Store color as a string identifier
    var visitedStations: Int
    let totalStations: Int
    
    var color: Color {
        switch colorName {
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        default: return .gray
        }
    }
    
    static func == (lhs: TrainLine, rhs: TrainLine) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - UserDefaults Data Manager
class TrainLineStore: ObservableObject {
    @Published var lines: [TrainLine] = []
    private let userDefaultsKey = "trainLines"
    
    init() {
        load()
    }
    
    func load() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([TrainLine].self, from: data) {
            self.lines = decoded
        } else {
            // Initial data for first launch
            self.lines = [
                TrainLine(id: UUID(), name: "JR Yamanote Line", colorName: "green", visitedStations: 5, totalStations: 30),
                TrainLine(id: UUID(), name: "Tokyo Metro Ginza Line", colorName: "orange", visitedStations: 12, totalStations: 19),
                TrainLine(id: UUID(), name: "JR Chuo Line", colorName: "red", visitedStations: 8, totalStations: 24)
            ]
            save()
        }
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(lines) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
    
    func updateVisitedStations(for line: TrainLine, visited: Int) {
        if let idx = lines.firstIndex(of: line) {
            lines[idx].visitedStations = visited
            save()
        }
    }
}

// Example data for lines and their stations
struct DemoData {
    static let lines: [(lineName: String, colorName: String, stations: [String])] = [
        ("JR Yamanote Line", "green", ["Shibuya", "Ebisu", "Meguro", "Shinagawa", "Tamachi", "Hamamatsucho", "Shimbashi", "Yurakucho", "Tokyo", "Kanda", "Akihabara", "Okachimachi", "Ueno", "Uguisudani", "Nippori", "Nishi-Nippori", "Tabata", "Komagome", "Sugamo", "Otsuka", "Ikebukuro", "Mejiro", "Takadanobaba", "Shin-Okubo", "Shinjuku", "Yoyogi", "Harajuku", "Shibuya"]),
        ("Tokyo Metro Ginza Line", "orange", ["Asakusa", "Tawaramachi", "Inaricho", "Ueno", "Ueno-hirokoji", "Suehirocho", "Kanda", "Mitsukoshimae", "Nihombashi", "Kyobashi", "Ginza", "Shimbashi", "Toranomon", "Akasaka-mitsuke", "Aoyama-itchome", "Gaiemmae", "Omotesando", "Shibuya"]),
        ("JR Chuo Line", "red", ["Tokyo", "Kanda", "Ochanomizu", "Suidobashi", "Iidabashi", "Ichigaya", "Yotsuya", "Shinanomachi", "Sendagaya", "Shinjuku", "Nakano", "Koenji", "Asagaya", "Ogikubo", "Nishi-Ogikubo", "Kichijoji", "Mitaka"])
    ]
}

// MARK: - LineListView
struct LineListView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(Array(DemoData.lines.enumerated()), id: \.offset) { index, line in
                        NavigationLink(
                            destination: StationListView(
                                lineName: line.lineName,
                                stations: line.stations
                            )
                        ) {
                            LineCardView(
                                line: TrainLine(
                                    id: UUID(),
                                    name: line.lineName,
                                    colorName: line.colorName,
                                    visitedStations: 0,
                                    totalStations: line.stations.count
                                )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.vertical, 24)
                .padding(.horizontal, 20)
            }
            .navigationTitle("Tokyo Train Lines")
        }
    }
}

// MARK: - LineCardView
struct LineCardView: View {
    let line: TrainLine
    
    var progress: Double {
        guard line.totalStations > 0 else { return 0 }
        return Double(line.visitedStations) / Double(line.totalStations)
    }
    
    var body: some View {
        HStack(spacing: 20) {
            Circle()
                .fill(line.color)
                .frame(width: 36, height: 36)
                .shadow(radius: 2)
            VStack(alignment: .leading, spacing: 8) {
                Text(line.name)
                    .font(.headline)
                Text("\(line.visitedStations) of \(line.totalStations) stations visited")
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
