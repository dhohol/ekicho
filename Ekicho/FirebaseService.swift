import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

class FirebaseService: ObservableObject {
    let db = Firestore.firestore()
    
    // MARK: - Published Properties
    @Published var lines: [Line] = []
    @Published var stations: [String: Station] = [:]
    @Published var userVisits: [String: UserStationVisit] = [:]
    @Published var isLoading = false
    @Published var error: String?
    
    // MARK: - Computed Properties
    var allCompanies: [String] {
        let uniqueCompanies = Set(lines.map { $0.company })
        return Array(uniqueCompanies).sorted()
    }
    
    var visitedStationIDs: Set<String> {
        Set(userVisits.keys)
    }
    
    var totalProgress: ProgressInfo {
        let allStationIDs = Set(lines.flatMap { $0.station_ids })
        let visitedCount = visitedStationIDs.intersection(allStationIDs).count
        let totalCount = allStationIDs.count
        let percentage = totalCount > 0 ? Double(visitedCount) / Double(totalCount) : 0
        
        return ProgressInfo(
            visitedCount: visitedCount,
            totalCount: totalCount,
            percentage: percentage
        )
    }
    
    // MARK: - Initialization
    init() {
        loadData()
    }
    
    // MARK: - Data Loading
    func loadData() {
        isLoading = true
        error = nil
        
        // Load lines and stations in parallel
        let group = DispatchGroup()
        
        group.enter()
        loadLines { [weak self] in
            group.leave()
        }
        
        group.enter()
        loadStations { [weak self] in
            group.leave()
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.isLoading = false
            // Load user visits after lines and stations are loaded
            self?.loadUserVisits()
        }
    }
    
    private func loadLines(completion: @escaping () -> Void) {
        db.collection("lines")
            .whereField("is_active", isEqualTo: true)
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.error = "Failed to load lines: \(error.localizedDescription)"
                        // print("❌ Error loading lines: \(error)")
                        completion()
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        self?.error = "No lines found"
                        // print("❌ No lines found in Firestore")
                        completion()
                        return
                    }
                    
                    let loadedLines = documents.compactMap { document in
                        do {
                            return try document.data(as: Line.self)
                        } catch {
                            // print("❌ Error decoding line \(document.documentID): \(error)")
                            return nil
                        }
                    }
                    
                    self?.lines = loadedLines
                    // print("✅ Loaded \(loadedLines.count) lines from Firestore")
                    completion()
                }
            }
    }
    
    private func loadStations(completion: @escaping () -> Void) {
        db.collection("stations")
            .whereField("is_active", isEqualTo: true)
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.error = "Failed to load stations: \(error.localizedDescription)"
                        // print("❌ Error loading stations: \(error)")
                        completion()
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        self?.error = "No stations found"
                        // print("❌ No stations found in Firestore")
                        completion()
                        return
                    }
                    
                    let loadedStations = documents.compactMap { document in
                        do {
                            return try document.data(as: Station.self)
                        } catch {
                            // print("❌ Error decoding station \(document.documentID): \(error)")
                            return nil
                        }
                    }
                    
                    self?.stations = Dictionary(uniqueKeysWithValues: loadedStations.map { ($0.station_id, $0) })
                    // print("✅ Loaded \(loadedStations.count) stations from Firestore")
                    completion()
                }
            }
    }
    
    private func loadUserVisits() {
        guard let userId = Auth.auth().currentUser?.uid else {
            // print("⚠️ No authenticated user, skipping user visits load")
            return
        }
        
        // print("🔄 Loading user visits for user: \(userId)")
        
        db.collection("users")
            .document(userId)
            .collection("visits")
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.error = "Failed to load user visits: \(error.localizedDescription)"
                        // print("❌ Error loading user visits: \(error)")
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        // print("✅ No user visits found (new user)")
                        return
                    }
                    
                    let loadedVisits = documents.compactMap { document in
                        do {
                            return try document.data(as: UserStationVisit.self)
                        } catch {
                            // print("❌ Error decoding visit \(document.documentID): \(error)")
                            return nil
                        }
                    }
                    
                    self?.userVisits = Dictionary(uniqueKeysWithValues: loadedVisits.map { ($0.station_id, $0) })
                    // print("✅ Loaded \(loadedVisits.count) user visits from Firestore")
                }
            }
    }
    
    // MARK: - User Actions
    func toggleStationVisit(stationId: String) {
        guard let userId = Auth.auth().currentUser?.uid else {
            error = "User not authenticated"
            // print("❌ Cannot toggle visit: user not authenticated")
            return
        }
        
        let visitRef = db.collection("users").document(userId).collection("visits").document(stationId)
        
        if userVisits[stationId] != nil {
            // Remove visit
            // print("🔄 Removing visit for station: \(stationId)")
            visitRef.delete { [weak self] error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.error = "Failed to remove visit: \(error.localizedDescription)"
                        // print("❌ Error removing visit: \(error)")
                    } else {
                        self?.userVisits.removeValue(forKey: stationId)
                        // print("✅ Visit removed for station: \(stationId)")
                    }
                }
            }
        } else {
            // Add visit
            // print("🔄 Adding visit for station: \(stationId)")
            let visit = UserStationVisit(
                user_id: userId,
                station_id: stationId,
                visited_at: Date(),
                photo_urls: [],
                recommendation_text: nil,
                recommendation_url: nil,
                is_public: false,
                flagged: false,
                is_deleted: false
            )
            
            do {
                try visitRef.setData(from: visit) { [weak self] error in
                    DispatchQueue.main.async {
                        if let error = error {
                            self?.error = "Failed to add visit: \(error.localizedDescription)"
                            // print("❌ Error adding visit: \(error)")
                        } else {
                            self?.userVisits[stationId] = visit
                            // print("✅ Visit added for station: \(stationId)")
                        }
                    }
                }
            } catch {
                self.error = "Failed to create visit: \(error.localizedDescription)"
                // print("❌ Error creating visit object: \(error)")
            }
        }
    }
    
    // MARK: - Helper Methods
    func visitedStationCount(for line: Line) -> Int {
        let lineStationIDs = Set(line.station_ids)
        return visitedStationIDs.intersection(lineStationIDs).count
    }
    
    func filteredLines(selectedCompanies: Set<String>) -> [Line] {
        if selectedCompanies.isEmpty {
            return []  // Return no lines when no companies are selected
        }
        if selectedCompanies.count == allCompanies.count {
            return lines  // Return all lines when all companies are selected
        }
        return lines.filter { selectedCompanies.contains($0.company) }
    }
    
    // MARK: - User Management
    func createUserIfNeeded(completion: @escaping (Bool) -> Void) {
        guard let user = Auth.auth().currentUser else {
            // print("❌ No authenticated user for user creation")
            completion(false)
            return
        }
        
        let userRef = db.collection("users").document(user.uid)
        
        userRef.getDocument { [weak self] snapshot, error in
            if let error = error {
                // print("❌ Error checking user document: \(error)")
                completion(false)
                return
            }
            
            if snapshot?.exists == true {
                // User already exists
                // print("✅ User document already exists: \(user.uid)")
                completion(true)
            } else {
                // Create new user document
                // print("🔄 Creating new user document: \(user.uid)")
                let newUser = User(
                    display_name: user.displayName ?? "User",
                    email: user.email ?? "",
                    auth_provider: "apple",
                    current_city_id: "tokyo", // Default to Tokyo
                    home_stations: [:],
                    auxiliary_stations: [:],
                    created_at: Date(),
                    last_active_at: Date()
                )
                
                do {
                    try userRef.setData(from: newUser) { error in
                        if let error = error {
                            // print("❌ Error creating user document: \(error)")
                            completion(false)
                        } else {
                            // print("✅ User document created successfully: \(user.uid)")
                            completion(true)
                        }
                    }
                } catch {
                    // print("❌ Error encoding user data: \(error)")
                    completion(false)
                }
            }
        }
    }
    
    // MARK: - User Visit Existence Check
    func hasAnyUserVisits(completion: @escaping (Bool) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        db.collection("users")
            .document(userId)
            .collection("visits")
            .limit(to: 1)
            .getDocuments { snapshot, error in
                if let error = error {
                    // print("❌ Error checking for user visits: \(error)")
                    completion(false)
                    return
                }
                let hasVisits = (snapshot?.documents.count ?? 0) > 0
                completion(hasVisits)
            }
    }
}

// MARK: - Supporting Types
struct ProgressInfo {
    let visitedCount: Int
    let totalCount: Int
    let percentage: Double
} 