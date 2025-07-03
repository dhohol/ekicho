import SwiftUI
import Combine

class FirebaseDataStore: ObservableObject {
    @Published var selectedCompanies: Set<String> = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var visitedStationIDs: Set<String> = []
    
    let firebaseService: FirebaseService
    private let selectedCompaniesKey = "selectedCompanies"
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var lines: [Line] {
        firebaseService.filteredLines(selectedCompanies: selectedCompanies)
    }
    
    var stations: [String: Station] {
        firebaseService.stations
    }
    
    var allCompanies: [String] {
        firebaseService.allCompanies
    }
    
    var totalProgress: ProgressInfo {
        // Use ALL lines for global progress, not just filtered lines
        let allReferencedStationIDs = Set(firebaseService.lines.flatMap { $0.station_ids })
        let validStationIDs = allReferencedStationIDs.intersection(Set(stations.keys))
        let visitedCount = visitedStationIDs.intersection(validStationIDs).count
        let totalCount = validStationIDs.count
        let percentage = totalCount > 0 ? Double(visitedCount) / Double(totalCount) : 0

        return ProgressInfo(
            visitedCount: visitedCount,
            totalCount: totalCount,
            percentage: percentage
        )
    }
    
    // MARK: - Initialization
    init(firebaseService: FirebaseService) {
        self.firebaseService = firebaseService
        
        // Observe Firebase service changes
        firebaseService.$isLoading
            .assign(to: &$isLoading)
        
        firebaseService.$error
            .assign(to: &$error)
        
        // Relay userVisits changes to visitedStationIDs
        firebaseService.$userVisits
            .map { Set($0.keys) }
            .receive(on: DispatchQueue.main)
            .assign(to: &self.$visitedStationIDs)
        
        // Load selected companies after Firebase data is loaded
        firebaseService.$lines
            .dropFirst() // Skip the initial empty array
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.loadSelectedCompanies()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Persistence
    func loadSelectedCompanies() {
        // Don't load if allCompanies is still empty (data not loaded yet)
        guard !allCompanies.isEmpty else { 
            return 
        }
        
        if let savedCompanies = UserDefaults.standard.array(forKey: selectedCompaniesKey) as? [String] {
            // Ensure saved companies are still valid
            let validCompanies = Set(savedCompanies).intersection(allCompanies)
            // If no valid companies found, default to all companies (not empty)
            self.selectedCompanies = validCompanies.isEmpty ? Set(allCompanies) : validCompanies
        } else {
            // No saved preferences - default to all companies selected
            self.selectedCompanies = Set(allCompanies)
        }
        
        // Save the current selection to ensure consistency
        saveSelectedCompanies()
    }
    
    func saveSelectedCompanies() {
        UserDefaults.standard.set(Array(selectedCompanies), forKey: selectedCompaniesKey)
    }
    
    // MARK: - Debug/Testing
    func clearSavedPreferences() {
        UserDefaults.standard.removeObject(forKey: selectedCompaniesKey)
    }
    
    // MARK: - User Actions
    func toggleVisited(station: Station) {
        firebaseService.toggleStationVisit(stationId: station.station_id)
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
    func visitedStationCount(for line: Line) -> Int {
        visitedStationIDs.intersection(Set(line.station_ids)).count
    }
    
    // MARK: - Data Refresh
    func refreshData() {
        firebaseService.loadData()
    }
} 