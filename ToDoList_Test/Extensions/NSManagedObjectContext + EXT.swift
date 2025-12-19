//
//  NSManagedContext + EXT.swift
//  ToDoList_Test
//
//  Created by Борис Киселев on 19.12.2025.
//

import CoreData

extension NSManagedObjectContext {
    func countOfEntity(_ entityName: String, predicate: NSPredicate? = nil) -> Int {
         let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
         request.predicate = predicate
         request.resultType = .countResultType
         
         do {
             return try self.count(for: request)
         } catch {
             print("Count error: \(error)")
             return 0
         }
     }
}
