//
//  QandAResponse.swift
//  JotMe
//
//  Created by Dan Cox on 3/11/25.
//


import Foundation

struct QandAResponse: Codable {
    let success: Bool
    let message: String
    let qanda: QandA
}
