import SwiftUI
import Combine

// MARK: - Models

struct Station: Identifiable, Hashable, Codable {
    let id: String // global unique ID
    let name: String
}

struct TrainLine: Identifiable, Codable {
    let id: UUID
    let name: String
    let colorName: String
    let symbol: String?
    let iconAssetName: String?
    let shape: String?
    let stationIDs: [String] // references to global stations
    
    var color: Color {
        switch colorName.lowercased() {
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        case "blue": return .blue
        case "purple": return .purple
        case "yellow": return .yellow
        case "pink": return .pink
        case "brown": return .brown
        case "lightblue": return Color("LightBlue")
        default: return .gray
        }
    }
}

// MARK: - JSON Models

struct LinesJSON: Codable {
    let stations: [Station]
    let lines: [LineData]
}

struct LineData: Codable {
    let lineName: String
    let colorName: String
    let symbol: String?
    let shape: String?
    let iconAssetName: String?
    let stationIDs: [String]
}

// MARK: - Data Store (Single Source of Truth)

class EkichoDataStore: ObservableObject {
    @Published var visitedStationIDs: Set<String> = [] // global station IDs
    let lines: [TrainLine]
    let stations: [String: Station] // global station dictionary
    
    private let userDefaultsKey = "visitedStationIDs"
    
    init() {
        let (lines, stations) = Self.loadLinesAndStationsFromJSON()
        self.lines = lines
        self.stations = stations
        loadVisitedStations()
    }
    
    // MARK: - JSON Loading
    private static func loadLinesAndStationsFromJSON() -> ([TrainLine], [String: Station]) {
        guard let url = Bundle.main.url(forResource: "lines", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(LinesJSON.self, from: data) else {
            print("Failed to load lines.json, using fallback data")
            return Self.getFallbackLinesAndStations()
        }
        let stationDict = Dictionary(uniqueKeysWithValues: decoded.stations.map { ($0.id, $0) })
        let lines = decoded.lines.map { lineData in
            TrainLine(
                id: UUID(),
                name: lineData.lineName,
                colorName: lineData.colorName,
                symbol: lineData.symbol,
                iconAssetName: lineData.iconAssetName,
                shape: lineData.shape,
                stationIDs: lineData.stationIDs
            )
        }
        return (lines, stationDict)
    }
    
    private static func getFallbackLinesAndStations() -> ([TrainLine], [String: Station]) {
        let stations = [
            Station(id: "shinjuku", name: "Shinjuku"),
            Station(id: "shibuya", name: "Shibuya"),
            Station(id: "ebisu", name: "Ebisu")
        ]
        let lines = [
            TrainLine(id: UUID(), name: "JR Yamanote Line", colorName: "green", symbol: "JY", iconAssetName: nil, shape: nil, stationIDs: ["shinjuku", "shibuya", "ebisu"]),
            TrainLine(id: UUID(), name: "JR Chuo Line", colorName: "red", symbol: "JC", iconAssetName: nil, shape: nil, stationIDs: ["shinjuku", "ebisu"])
        ]
        let stationDict = Dictionary(uniqueKeysWithValues: stations.map { ($0.id, $0) })
        return (lines, stationDict)
    }
    
    // MARK: - Persistence
    func loadVisitedStations() {
        if let savedIDs = UserDefaults.standard.array(forKey: userDefaultsKey) as? [String] {
            self.visitedStationIDs = Set(savedIDs)
        }
    }
    func saveVisitedStations() {
        UserDefaults.standard.set(Array(visitedStationIDs), forKey: userDefaultsKey)
    }
    // MARK: - User Actions
    func toggleVisited(station: Station) {
        if visitedStationIDs.contains(station.id) {
            visitedStationIDs.remove(station.id)
        } else {
            visitedStationIDs.insert(station.id)
        }
        saveVisitedStations()
    }
    // MARK: - View-facing Logic
    func visitedStationCount(for line: TrainLine) -> Int {
        let lineStationIDs = Set(line.stationIDs)
        return visitedStationIDs.intersection(lineStationIDs).count
    }
}
