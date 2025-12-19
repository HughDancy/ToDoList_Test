//
//  CoreDataManager.swift
//  ToDoList_Test
//
//  Created by Борис Киселев on 18.12.2025.
//

import Foundation
import CoreData

final class CoreDataManager {
    
    // MARK: - Singleton
    static let shared = CoreDataManager()
    
    // MARK: - Properties
    private let modelName: String
    
    // MARK: - Init
    private init(modelName: String = "ToDoList_Test") {
        self.modelName = modelName
    }
    
    // MARK: - Persistent Container propertie
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: modelName)
        
        // MARK: - For lightwave migration?
        let storeDescription = container.persistentStoreDescriptions.first
        storeDescription?.shouldMigrateStoreAutomatically = true
        storeDescription?.shouldInferMappingModelAutomatically = true
        
        container.loadPersistentStores { [weak self] storeDescription, error in
            if let error {
                print("[\(String(describing: self))] Went some error - \(error)")
            } else {
                print("CoreData Store loaded is succefully")
            }
        }
        
        // MARK: - Setup context
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return container
    }()
    
    // MARK: - CoreData Contexts
    
    // For Main Thread
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
//    // For background context
    var newBackgroundContext: NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.automaticallyMergesChangesFromParent = true
        return context
    }
    
    // MARK: - Performing operation in background context
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        persistentContainer.performBackgroundTask(block)
    }
    
    // MARK: - Saving operations
    func saveViewContext() {
        let context = viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("[\(String(describing: self))] Went some error on saving main context - \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    // Async saving background context
//    func saveBackgroundContext(_ context: NSManagedObjectContext, comelition: ((Result<Void, Error>) -> Void)? = nil) {
//        context.perform {
//            guard context.hasChanges else {
//                comelition?(.success(()))
//                return
//            }
//            
//            do {
//                try context.save()
//                comelition?(.success(()))
//            } catch {
//                print("[\(String(describing: self))] Went some error on saving background context - \(error.localizedDescription)")
//                comelition?(.failure(error))
//            }
//        }
//    }
    
    
    
    // MARK: - Support Methods
    func getStoredItemsCount<T: NSManagedObject>(for entity: T.Type, predicate: NSPredicate? = nil, in context: NSManagedObjectContext) -> Int {
        let fetchRequest = NSFetchRequest<T>(entityName: String(describing: entity))
        fetchRequest.predicate = predicate
        
        do {
            return try context.count(for: fetchRequest)
        } catch {
            print("[\(String(describing: self))] Went some error on get items coutn - \(error.localizedDescription)")
            return 0
        }
    }
}


