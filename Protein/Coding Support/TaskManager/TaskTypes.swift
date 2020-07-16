//
//  TaskTypes.swift
//  Protein
//
//  Created by Lakr Aream on 2020/4/19.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import Foundation

extension TaskManager {
    
    enum TaskType: String {
        case packageTask
        case downloadTask
        case unownedTask
    }
    
    enum PackageTaskType: String {
        case selectInstall
        case pullupInstall
        case selectDelete
        case pullupDelete
    }
    
    enum TaskStauts: String {
        case pending            // used if the task run automatically after checkpoint
        case activated
        case queued             // used if the task run only after interface event fired
        case done               // should only be used in download
        case prepare            // should only be used in install when downloading packages
    }
    
    struct Task: Equatable {
        
        static func == (lhs: TaskManager.Task, rhs: TaskManager.Task) -> Bool {
            return lhs.id != nil && rhs.id != nil && lhs.id == rhs.id
        }
        
        var id: String?
        var type: TaskType
        var name: String
        var description: String
        var status: TaskStauts
        var relatedObjects: [String : Any]?
    }
    
    struct PackageTaskModificationReturn {
        let didSuccess: Bool
        let resolveObject: PackageResolveReturn
    }
    
}
