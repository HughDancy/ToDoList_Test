//
//  Task+CoreDataProperties.swift
//  ToDoList_Test
//
//  Created by Борис Киселев on 17.12.2025.
//
//

public import Foundation
public import CoreData


public typealias TaskCoreDataPropertiesSet = NSSet

extension Task {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Task> {
        return NSFetchRequest<Task>(entityName: "Task")
    }

    @NSManaged public var id: UUID
    @NSManaged public var userId: UUID
    @NSManaged public var title: String?
    @NSManaged public var taskDescription: String?
    @NSManaged public var date: Date?
    @NSManaged public var isCompleted: Bool

}

extension Task : Identifiable {
    static func sortedByDateDescending() -> [NSSortDescriptor] {
        return [
            NSSortDescriptor(key: "date", ascending: false)
        ]
    }
}
