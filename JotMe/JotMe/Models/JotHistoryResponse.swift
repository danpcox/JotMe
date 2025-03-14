//
//  JotHistoryResponse.swift
//  JotMe
//
//  Created by Dan Cox on 11/7/24.
//


import Foundation

struct JotHistoryResponse: Codable {
    let success: Bool
    let message: String
    let jots: [Jot]
    let todos: [Todo]
}
