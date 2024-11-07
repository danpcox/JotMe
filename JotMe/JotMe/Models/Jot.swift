//
//  Jot.swift
//  JotMe
//
//  Created by Dan Cox on 11/7/24.
//

// Jot.swift
// JotMe

import Foundation

struct Jot: Codable, Identifiable {
    let id: Int
    let jotText: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case jotText = "jot_text"
        case createdAt = "created_at"
    }
}
