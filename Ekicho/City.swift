//
//  City.swift
//  Ekicho
//
//  Created by Daniele Hohol on 7/1/25.
//
import Foundation
import FirebaseFirestore

struct City: Codable, Identifiable {
    @DocumentID var id: String?  // e.g., "tokyo"

    var name: String
    var region: String
    var slug: String
    var display_order: Int
}
