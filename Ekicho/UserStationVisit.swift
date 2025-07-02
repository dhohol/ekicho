//
//  UserStationVisit.swift
//  Ekicho
//
//  Created by Daniele Hohol on 7/1/25.
//
import Foundation
import FirebaseFirestore

struct UserStationVisit: Codable, Identifiable {
    @DocumentID var id: String?  // e.g., "daniele_001_tokyo_shibuya"

    var user_id: String
    var station_id: String
    var visited_at: Date

    var photo_urls: [String]
    var recommendation_text: String?
    var recommendation_url: String?

    var is_public: Bool
    var flagged: Bool
    var is_deleted: Bool
}
