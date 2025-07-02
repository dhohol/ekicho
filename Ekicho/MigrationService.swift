import Foundation
import FirebaseAuth
import FirebaseFirestore

class MigrationService {
    private let db = Firestore.firestore()
    private let userDefaultsKey = "visitedStationIDs"
    
    func migrateLocalVisitsToFirebase(completion: @escaping (Bool) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        
        // Check if migration has already been done
        let migrationKey = "migrationCompleted_\(userId)"
        if UserDefaults.standard.bool(forKey: migrationKey) {
            completion(true)
            return
        }
        
        // Get local visited stations
        guard let savedIDs = UserDefaults.standard.array(forKey: userDefaultsKey) as? [String],
              !savedIDs.isEmpty else {
            // No local data to migrate
            UserDefaults.standard.set(true, forKey: migrationKey)
            completion(true)
            return
        }
        
        // Migrate each visit to Firebase
        let group = DispatchGroup()
        var successCount = 0
        var totalCount = savedIDs.count
        
        for stationId in savedIDs {
            group.enter()
            
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
            
            let visitRef = db.collection("users").document(userId).collection("visits").document(stationId)
            
            do {
                try visitRef.setData(from: visit) { error in
                    if error == nil {
                        successCount += 1
                    }
                    group.leave()
                }
            } catch {
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            // Mark migration as completed
            UserDefaults.standard.set(true, forKey: migrationKey)
            
            // Clean up local data
            UserDefaults.standard.removeObject(forKey: self.userDefaultsKey)
            
            print("✅ Migration completed: \(successCount)/\(totalCount) visits migrated")
            completion(successCount > 0)
        }
    }
} 