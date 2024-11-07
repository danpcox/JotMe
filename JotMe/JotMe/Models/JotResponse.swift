//
//  JotResponse.swift
//  JotMe
//
//  Created by Dan Cox on 11/7/24.
//


// JotResponse.swift
// JotMe

import Foundation

struct JotResponse: Codable {
    let success: Bool
    let message: String
    let jot: Jot
}
