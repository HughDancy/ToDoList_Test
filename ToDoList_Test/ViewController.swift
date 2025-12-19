//
//  ViewController.swift
//  ToDoList_Test
//
//  Created by Борис Киселев on 17.12.2025.
//

import UIKit

class ViewController: UIViewController {
    let taskManager = TaskManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemYellow
        let numberOfTasks = taskManager.fetchNumberOfTasks()
        print(numberOfTasks)
//        taskManager.addTask(title: "Drink some beer", description: "Drink IPA and Shteininger") { bool in
//            print("Adding new task is succeful - \(bool)")
//        }
    
        
    }


}

