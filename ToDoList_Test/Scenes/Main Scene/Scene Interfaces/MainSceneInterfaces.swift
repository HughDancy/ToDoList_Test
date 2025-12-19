//
//  MainSceneInterfaces.swift
//  ToDoList_Test
//
//  Created by Борис Киселев on 19.12.2025.
//

import Foundation
import UIKit

protocol MainSceneViewProtocol: AnyObject {
    var presenter: MainScenePresenterInputProtocol? { get set }
    var router: MainSceneRouterProtocol? { get set }
    
    func getTasks(_ tasks: [TaskEntity])
    func addNewTask(title: String, description: String?)
    func doneTask()
    func deleteTask(with index: Int)
    func goToTaskDetail(with index: Int)
}


protocol MainScenePresenterInputProtocol: AnyObject {
    var view: MainSceneViewProtocol? { get set }
    var interactor: MainSceneInteractorProtocol? { get set }
    
    func appendNewTask(title: String, description: String?)
    func deleteTask(with index: Int)
    func getAllTask()
}

protocol MainScenePresenterOutputProtocol: AnyObject {
    func deliverAllTasks(_ tasks: [TaskEntity])
    func makeTaskDone(_ bool: Bool)
    func addingNewTask(_ bool: Bool)
    func deletingTask(_ bool: Bool)
    
}

protocol MainSceneInteractorProtocol: AnyObject {
    var presenter: MainScenePresenterOutputProtocol? { get set }
    
    func fetchTasks()
    func addNewTask(title: String, description: String?)
    func removeTask(with index: Int)
    func markTaskAsDone(with index: Int)
    
}

protocol MainSceneRouterProtocol: AnyObject {
    var sourceView: UIViewController { get set }
    
    func goToTaskDetail(with task: TaskEntity)
    
}

