//
//  TaskManager.swift
//  ToDoList_Test
//
//  Created by Борис Киселев on 17.12.2025.
//

import Foundation
import CoreData

protocol TaskManagerProtocol: AnyObject {
    var onTaskUpdated: (([TaskEntity]) -> Void)? { get set }
    var isLoading: Bool { get }
    
    func fetchTasks()
    func refreshTasks()
    func toggleTaskState(at index: Int)
    func fetchNumberOfTasks() -> Int
    func serachTask(with query: String)
    func deleteTask(at index: Int)
    func addTask(title: String, description: String?, compelition: @escaping (Bool) -> Void)
    func updateTaskInfo(at index: Int, title: String, description: String?, compelition: @escaping (Bool) -> Void)
}

final class TaskManager: TaskManagerProtocol {
    
    // MARK: - Private properties
    private let coreDataManager: CoreDataManager
    private let highPriorityQueue: DispatchQueue
    private let backgroundQueue: DispatchQueue
    
    // MARK: - Optimization store
    private var displayTasks = [TaskEntity]()
    private var allTaskId = [UUID]()
    
    // MARK: - Strte properties
    private(set) var isLoading = false
    private var isBackgroundLoading = false
    private var hasMoreTasksStored = true
    
    // MARK: - Callback
    var onTaskUpdated: (([TaskEntity]) -> Void)?
    
    // MARK: - Optimization constants
    private let initialBatchSize = 50
    private let backgroundBatchSize = 100

    
    // MARK: - Init
    init(coreDataManager: CoreDataManager = CoreDataManager.shared) {
        self.coreDataManager = coreDataManager
        self.highPriorityQueue = DispatchQueue(
            label: "com.todoList_Test.taskmanager.queue",
            qos: .userInitiated,
            attributes: .concurrent
        )
        self.backgroundQueue = DispatchQueue(
            label: "com.todoList_Test.background.queue",
            qos: .background,
            attributes: .concurrent
        )
    }
    
    // MARK: - Protocol methods
    func fetchTasks() {
        guard !isLoading else { return }
        isLoading = true
        
        loadAllSortedByDateTasks { [weak self] sortedIds in
            guard let self = self else { return }
            
            self.allTaskId = sortedIds
            
            self.loadFirstBatch { firstTasks in
                self.isLoading = false
                self.displayTasks = firstTasks
                
                DispatchQueue.main.async {
                    self.onTaskUpdated?(self.displayTasks)
                }
                self.startBackgroundLoadingTask()
            }
        }
    }
    
    func refreshTasks() {
        displayTasks.removeAll()
        allTaskId.removeAll()
        hasMoreTasksStored = true
        fetchTasks()
    }
    
    func toggleTaskState(at index: Int) {
        guard index < displayTasks.count else { return }
        
        let task = displayTasks[index]
        
        coreDataManager.performBackgroundTask { [weak self] context in
            guard let self = self else { return }
            
            let fetchRequest = Task.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", task.id as CVarArg)
            fetchRequest.fetchLimit = 1
            
            do {
                if let taskEntity = try context.fetch(fetchRequest).first {
                    taskEntity.isCompleted.toggle()
                    
                    try context.save()
                    
                    let updateModel = TaskEntity(
                        id: taskEntity.id,
                        title: taskEntity.title ?? "Title has been lost",
                        description: taskEntity.description,
                        isCompleted: taskEntity.isCompleted,
                        creationDate: taskEntity.date)
                    
                    DispatchQueue.main.async {
                        if let index = self.displayTasks.firstIndex(where: { $0.id == task.id}) {
                            self.displayTasks[index] = updateModel
                            self.onTaskUpdated?(self.displayTasks)
                        }
                    }
                }
            } catch {
                print("Toggle error: \(error)")
            }
        }
    }
    
    func fetchNumberOfTasks() -> Int {
        return coreDataManager.viewContext.countOfEntity("Task")
    }
    
    func serachTask(with query: String) {
        guard  !query.isEmpty else {
            if !displayTasks.isEmpty {
                onTaskUpdated?(displayTasks)
            } else {
                fetchTasks()
            }
            return
        }
        
        highPriorityQueue.async { [weak self] in
            guard let self = self else { return }
            let fetchRequest = Task.fetchRequest()
            fetchRequest.predicate = NSPredicate(
                format: "title CONTAINS[cd] %@ OR taskDescription CONTAINS[cd] %@",
                query, query
            )
            fetchRequest.propertiesToFetch = ["id", "title", "taskDescription", "isCompleted", "date"]
            fetchRequest.returnsObjectsAsFaults = false
            fetchRequest.fetchLimit = 200
            fetchRequest.sortDescriptors = Task.sortedByDateDescending()
            
            do {
                let tasks = try self.coreDataManager.viewContext.fetch(fetchRequest)
                let displayModels = tasks.map { self.createDisplayTasks(from: $0) }
                
                DispatchQueue.main.async {
                    self.displayTasks = displayModels
                    self.onTaskUpdated?(displayModels)
                }
            } catch {
                print("Search error - \(error)")
            }
        }
    }
    
    func deleteTask(at index: Int) {
        guard index < displayTasks.count else { return }
        
        let task = displayTasks[index]
        
        coreDataManager.performBackgroundTask { [weak self] context in
            guard let self = self else { return }
            
            let fetchRequest = Task.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", task.id as CVarArg)
            fetchRequest.fetchLimit = 1
            
            do {
                if let taskEntity = try context.fetch(fetchRequest).first {
                    context.delete(taskEntity)
                    try context.save()
                    
                    DispatchQueue.main.async {
                        self.displayTasks.remove(at: index)
                        self.allTaskId.removeAll(where: { $0 == task.id })
                        self.onTaskUpdated?(self.displayTasks)
                    }
                }
            } catch {
                print("Delete error - \(error)")
            }
        }
    }
    
    
    func addTask(title: String, description: String?, compelition: @escaping (Bool) -> Void) {
        coreDataManager.performBackgroundTask { [weak self] context in
            guard let self = self else {
                print("Self in add Task is false")
                compelition(false)
                return
            }
            
            let newTask = Task(context: context)
            newTask.id = UUID()
            newTask.userId = UUID()
            newTask.title = title
            newTask.taskDescription = description
            newTask.isCompleted = false
            newTask.date = Date()
            
            do {
                try context.save()
                
                let displayModel = TaskEntity(
                    id: newTask.id,
                    title: newTask.title ?? "Title has been lost",
                    description: newTask.description,
                    isCompleted: newTask.isCompleted,
                    creationDate: newTask.date)
                
                    self.displayTasks.insert(displayModel, at: 0)
                    self.allTaskId.insert(newTask.id, at: 0)
                    self.onTaskUpdated?(self.displayTasks)
            } catch {
                print("Adding New Task error - \(error)")
            }
        }
    }
    
    func updateTaskInfo(at index: Int, title: String, description: String?, compelition: @escaping (Bool) -> Void) {
        guard index < displayTasks.count else {
            compelition(false)
            return
        }
        
        let task = displayTasks[index]
        
        coreDataManager.performBackgroundTask { [weak self] context in
            guard let self = self else {
                compelition(false)
                return
            }
            
            let fetchRequest = Task.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", task.id as CVarArg)
            fetchRequest.fetchLimit = 1
            
            do {
                if let taskEntity = try context.fetch(fetchRequest).first {
                    taskEntity.title = title
                    taskEntity.taskDescription = description
                    
                    try context.save()
                    
                    let updateModel = TaskEntity(
                        id: taskEntity.id,
                        title: taskEntity.title ?? "",
                        description: taskEntity.taskDescription,
                        isCompleted: taskEntity.isCompleted,
                        creationDate: taskEntity.date)
                    
                    DispatchQueue.main.async {
                        self.displayTasks[index] = updateModel
//                        self.taskCache[task.id] = taskEntity
                        self.displayTasks.sort { $0.creationDate ?? Date() > $1.creationDate ?? Date() }
                        self.onTaskUpdated?(self.displayTasks)
                    }
                } else {
                    DispatchQueue.main.async {
                        compelition(false)
                    }
                }
            } catch {
                print("Update error - \(error)")
                DispatchQueue.main.async {
                    compelition(false)
                }
            }
        }
    }
    
    
    
    // MARK: - Supported private methods
    private func loadAllSortedByDateTasks(compelition: @escaping ([UUID]) -> Void) {
        highPriorityQueue.async { [weak self] in
            guard let self = self else {
                compelition([])
                return
            }
            let fetchRequest = NSFetchRequest<NSDictionary>(entityName: "Task")
            fetchRequest.resultType = .dictionaryResultType
            fetchRequest.propertiesToFetch = ["id", "date"]
            fetchRequest.sortDescriptors = Task.sortedByDateDescending()
            
            do {
                let results = try self.coreDataManager.viewContext.fetch(fetchRequest)
                let ids = results.compactMap { dict -> UUID? in
                    return dict["id"] as? UUID
                }
                compelition(ids)
                
            } catch {
                print("ID fetch error")
                compelition([])
            }
        }
    }
    
    // MARK: - Load first batch
    private func loadFirstBatch(compelition: @escaping ([TaskEntity]) -> Void) {
        highPriorityQueue.async { [weak self] in
            guard let self = self else {
                compelition([])
                return
            }
            
            let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
            
            fetchRequest.propertiesToFetch = ["id", "title", "taskDescription", "isCompleted", "date"]
            fetchRequest.fetchBatchSize = self.initialBatchSize
            fetchRequest.fetchLimit = self.initialBatchSize
            fetchRequest.sortDescriptors = Task.sortedByDateDescending()
            
            do {
                let tasks = try self.coreDataManager.viewContext.fetch(fetchRequest)
                
//                tasks.forEach { task in
//                    self.taskCache[task.id] = task
//                }
                
                let displayTasksModel = tasks.map { self.createDisplayTasks(from: $0) }
                compelition(displayTasksModel)
            } catch {
                print("Invalid batch error: - \(error)")
                compelition([])
            }
        }
    }
    
    private func startBackgroundLoadingTask() {
        guard !isBackgroundLoading, hasMoreTasksStored else { return }
        
        isBackgroundLoading = true
        
        backgroundQueue.async { [weak self] in
            guard let loadedCount = self?.displayTasks.count,
                  let totalCount = self?.allTaskId.count,
                  let self = self else { return }
                    
            
            guard loadedCount < totalCount else {
                self.isBackgroundLoading = false
                self.hasMoreTasksStored = false
                return
            }
            
            let startIndex = loadedCount
            let endIndex = min(startIndex + self.backgroundBatchSize , totalCount)
            let batchIds = Array(self.allTaskId[startIndex..<endIndex])
            
            let batchTasks = self.fetchTasksByIDs(batchIds)
            let dispalyModels = batchTasks.map { self.createDisplayTasks(from: $0) }
            
//            batchTasks.forEach { task in
//                self.taskCache[task.id] = task
//            }
            
            DispatchQueue.main.async {
                self.displayTasks.append(contentsOf: dispalyModels)
                self.onTaskUpdated?(self.displayTasks)
                
                self.hasMoreTasksStored = self.displayTasks.count < totalCount
                self.isBackgroundLoading = false
                
                if self.hasMoreTasksStored {
                    self.backgroundQueue.asyncAfter(deadline: .now() + 0) {
                        self.startBackgroundLoadingTask()
                    }
                }
            }
        }
    }
    
    
    
    
    
    // MARK: - Convert Task to Task Entity
    private func createDisplayTasks(from task: Task) -> TaskEntity {
        return TaskEntity(id: task.id,
                          title: task.title ?? "Title has been lost",
                          description: task.taskDescription,
                          isCompleted: task.isCompleted,
                          creationDate: task.date)
    }
    
    // TODO: - Change id to UUID
    private func fetchTasksByIDs(_ ids: [UUID]) -> [Task] {
        guard !ids.isEmpty else { return [] }
        
        let fetchRequest = Task.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id IN %@", ids)
        
        fetchRequest.propertiesToFetch = ["id", "title", "taskDescription", "isCompleted", "date"]
        fetchRequest.returnsObjectsAsFaults = false
        fetchRequest.fetchBatchSize = ids.count
        fetchRequest.sortDescriptors = Task.sortedByDateDescending()
        
        do {
            let tasks = try coreDataManager.viewContext.fetch(fetchRequest)
            
            let taskDict = Dictionary(uniqueKeysWithValues: tasks.map { ($0.id, $0)})
            return ids.compactMap { taskDict[$0] }
        } catch {
            print("Eror with fetch tasks by ids - \(error)")
            return []
        }
        
    }
    

 
    
    
   
    
    
    
    
    
   
    
  
    
//    // MARK: - Propetie
//    private let batchSize = 25
//    
//    
//    // MARK: - Singleton
//    static let shared = TaskManager()
//    
//
//    
//    
}
