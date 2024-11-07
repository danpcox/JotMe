//
//  Todo.swift
//  JotMe
//
//  Created by Dan Cox on 11/7/24.
//


// Todo.swift
// JotMe

import Foundation

struct Todo: Codable, Identifiable {
    let id: Int
    let todoText: String
    let dueDate: String?
    let isCompletedInt: Int

    // Computed property to return isCompleted as a Boolean
    var isCompleted: Bool {
        return isCompletedInt != 0
    }

    enum CodingKeys: String, CodingKey {
        case id
        case todoText = "todo_text"
        case dueDate = "due_date"
        case isCompletedInt = "is_completed"
    }
}
