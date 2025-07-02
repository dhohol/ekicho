//
//  User.swift
//  Ekicho
//
//  Created by Daniele Hohol on 7/1/25.
//
import Foundation
import FirebaseFirestore

struct User: Codable, Identifiable {
    @DocumentID var id: String?  // Firestore doc ID (e.g., "daniele_001")

    var display_name: String
    var email: String
    var auth_provider: String
    var current_city_id: String

    var home_stations: [String: String]  // e.g., ["tokyo": "tokyo_monzen-nakacho"]
    var auxiliary_stations: [String: [String: String]]  // e.g., ["tokyo": ["work": "tokyo_roppongi"]]

    var created_at: Date?
    var last_active_at: Date?
}
