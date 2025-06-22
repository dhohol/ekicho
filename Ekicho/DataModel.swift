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
    let company: String? // optional company property
    
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
        case "emerald": return .mint
        case "rose": return .pink
        case "gold": return .yellow
        default: return .gray
        }
    }
    
    var companyName: String {
        return company ?? "Other"
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
    let company: String? // optional company property
}

// MARK: - Data Store (Single Source of Truth)

class EkichoDataStore: ObservableObject {
    @Published var visitedStationIDs: Set<String> = [] // global station IDs
    @Published var selectedCompanies: Set<String> = []
    let lines: [TrainLine]
    let stations: [String: Station] // global station dictionary
    let allCompanies: [String]
    
    private let userDefaultsKey = "visitedStationIDs"
    private let selectedCompaniesKey = "selectedCompanies"
    
    init() {
        let (lines, stations) = Self.loadLinesAndStationsFromJSON()
        self.lines = lines
        self.stations = stations
        
        let uniqueCompanies = Set(lines.map { $0.companyName })
        self.allCompanies = Array(uniqueCompanies).sorted()

        loadVisitedStations()
        loadSelectedCompanies()

        if let savedCompanies = UserDefaults.standard.array(forKey: selectedCompaniesKey) as? [String] {
            self.selectedCompanies = Set(savedCompanies)
        } else {
            self.selectedCompanies = Set(allCompanies)
        }
    }
    
    // MARK: - JSON Loading
    private static func loadLinesAndStationsFromJSON() -> ([TrainLine], [String: Station]) {
        guard let url = Bundle.main.url(forResource: "lines", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(LinesJSON.self, from: data) else {
            print("Failed to load lines.json, using fallback data")
            return Self.getFallbackLinesAndStations()
        }
        let stationDict = Dictionary(decoded.stations.map { ($0.id, $0) }, uniquingKeysWith: { _, last in last })
        let lines = decoded.lines.map { lineData in
            TrainLine(
                id: UUID(),
                name: lineData.lineName,
                colorName: lineData.colorName,
                symbol: lineData.symbol,
                iconAssetName: lineData.iconAssetName,
                shape: lineData.shape,
                stationIDs: lineData.stationIDs,
                company: lineData.company
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
            TrainLine(id: UUID(), name: "JR Yamanote Line", colorName: "green", symbol: "JY", iconAssetName: nil, shape: nil, stationIDs: ["shinjuku", "shibuya", "ebisu"], company: "JR"),
            TrainLine(id: UUID(), name: "JR Chuo Line", colorName: "red", symbol: "JC", iconAssetName: nil, shape: nil, stationIDs: ["shinjuku", "ebisu"], company: "JR")
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
    
    func loadSelectedCompanies() {
        if let savedCompanies = UserDefaults.standard.array(forKey: selectedCompaniesKey) as? [String] {
            // Ensure saved companies are still valid
            let validCompanies = Set(savedCompanies).intersection(allCompanies)
            self.selectedCompanies = validCompanies.isEmpty ? Set(allCompanies) : validCompanies
        } else {
            self.selectedCompanies = Set(allCompanies)
        }
    }
    
    func saveSelectedCompanies() {
        UserDefaults.standard.set(Array(selectedCompanies), forKey: selectedCompaniesKey)
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
    
    func toggleCompany(_ company: String) {
        if selectedCompanies.contains(company) {
            selectedCompanies.remove(company)
        } else {
            selectedCompanies.insert(company)
        }
        saveSelectedCompanies()
    }
    
    func toggleAllCompanies() {
        if selectedCompanies.count == allCompanies.count {
            selectedCompanies.removeAll()
        } else {
            selectedCompanies = Set(allCompanies)
        }
        saveSelectedCompanies()
    }
    
    // MARK: - View-facing Logic
    func visitedStationCount(for line: TrainLine) -> Int {
        let lineStationIDs = Set(line.stationIDs)
        return visitedStationIDs.intersection(lineStationIDs).count
    }
    
    // MARK: - Progress Calculation
    var totalProgress: ProgressInfo {
        let allStationIDs = Set(lines.flatMap { $0.stationIDs })
        let visitedCount = visitedStationIDs.intersection(allStationIDs).count
        let totalCount = allStationIDs.count
        let percentage = totalCount > 0 ? Double(visitedCount) / Double(totalCount) : 0
        
        return ProgressInfo(
            visitedCount: visitedCount,
            totalCount: totalCount,
            percentage: percentage
        )
    }
    
    var filteredLines: [TrainLine] {
        lines.filter { selectedCompanies.contains($0.companyName) }
    }
}

// MARK: - Supporting Types

struct ProgressInfo {
    let visitedCount: Int
    let totalCount: Int
    let percentage: Double
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
