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

    @NSManaged public var id: Int32
    @NSManaged public var userId: Int16
    @NSManaged public var title: String?
    @NSManaged public var taskDescription: String?
    @NSManaged public var date: Date?
    @NSManaged public var isCompleted: Bool

}

extension Task : Identifiable {

}
