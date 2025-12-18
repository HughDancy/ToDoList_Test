//
//  TaskEntity.swift
//  ToDoList_Test
//
//  Created by Борис Киселев on 18.12.2025.
//

import Foundation


struct TaskEntity: Hashable {
    let id: Int
    let title: String
    let description: String?
    let isCompleted: Bool
    let creationDate: Date
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd//MM//yy"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: creationDate)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(title)
        hasher.combine(isCompleted)
    }
    
    static func ==(lhs: TaskEntity, rhs: TaskEntity) -> Bool {
        lhs.id == rhs.id &&
        lhs.isCompleted == rhs.isCompleted &&
        lhs.title == rhs.title
    }
}
