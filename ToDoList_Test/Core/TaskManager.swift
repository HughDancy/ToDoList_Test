//
//  TaskManager.swift
//  ToDoList_Test
//
//  Created by Борис Киселев on 17.12.2025.
//

import Foundation
import CoreData

final class TaskManager {
    
//    // MARK: - Propetie
//    private let batchSize = 25
//    
//    
//    // MARK: - Singleton
//    static let shared = TaskManager()
//    
//    // MARK: - Setup CoreData Stack
//    private lazy var persistentContainer: NSPersistentContainer = {
//        let container = NSPersistentContainer(name: "task")
//        
//        let description = container.persistentStoreDescriptions.first
//        description?.shouldInferMappingModelAutomatically = true
//        description?.shouldMigrateStoreAutomatically = true
//        description?.setOption(true as NSNumber,
//                               forKey: NSPersistentHistoryTrackingKey)
//        description?.setOption(true as NSNumber,
//                               forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
//        
//        container.loadPersistentStores { _, error in
//            if let error {
//                print("[\(String(describing: self))] Went some error - \(error)")
//            }
//            
//            container.viewContext.automaticallyMergesChangesFromParent = true
//            container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
//            
//            container.viewContext.shouldDeleteInaccessibleFaults = true
//        }
//        
//        return container
//    }()
//    
//    // MARK: - Fetch Tasks method
//    func fetchTask(
//    
}
