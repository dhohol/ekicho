//
//  Line.swift
//  Ekicho
//
//  Created by Daniele Hohol on 7/1/25.
//
import Foundation
import FirebaseFirestore
import SwiftUI

struct Line: Codable, Identifiable {
    @DocumentID var id: String?  // e.g., "tokyo_yamanote"

    var line_id: String
    var name: String
    var company: String
    var city_id: String

    var line_symbol: String
    var color_name: String
    var color_hex: String
    var shape: String
    var icon_asset_name: String

    var station_ids: [String]
    var is_active: Bool
    
    // MARK: - Computed Properties for UI Compatibility
    var symbol: String? {
        return line_symbol.isEmpty ? nil : line_symbol
    }
    
    var iconAssetName: String? {
        return icon_asset_name.isEmpty ? nil : icon_asset_name
    }
    
    var color: Color {
        if !color_hex.isEmpty {
            return Color(hex: color_hex)
        }
        
        // Fallback to color_name if hex is not available
        switch color_name.lowercased() {
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
        return company.isEmpty ? "Other" : company
    }
}
