//
//  QandA.swift
//  JotMe
//
//  Created by Dan Cox on 3/11/25.
//


import Foundation

struct QandA: Codable, Identifiable {
    let apiId: Int?            // Optional API-provided identifier
    let question: String
    let answer: String
    let createdAt: String      // Date/time the question was asked
    
    // Conform to Identifiable
    var id: String {
        if let apiId = apiId {
            return "\(apiId)"
        }
        return question  // Fallback unique value
    }
}
