//
//  Station.swift
//  Ekicho
//
//  Created by Daniele Hohol on 7/1/25.
//
import Foundation
import FirebaseFirestore

struct Station: Codable, Identifiable, Hashable {
    @DocumentID var id: String?  // e.g., "tokyo_shibuya"

    var station_id: String
    var name: String
    var city_id: String
    var line_ids: [String]
    var lat: Double?
    var lng: Double?
    var is_active: Bool
    
    // MARK: - Computed Properties for UI Compatibility
    var hasLocation: Bool {
        return lat != nil && lng != nil
    }
    
    // For compatibility with existing UI code
    var displayName: String {
        return name
    }
}
