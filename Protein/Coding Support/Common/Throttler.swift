//
//  Throttler.swift
//  Protein
//
//  Created by soulghost on 10/5/2020.
//  from https://www.craftappco.com/blog/2018/5/30/simple-throttling-in-swift
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

class CommonThrottler {

    private var _assignment: (() -> ())? = nil
    private var _assignmentLock = NSLock()
    private var assignment:(() -> ())? {
        set {
            _assignmentLock.lock()
            defer { _assignmentLock.unlock() }
            _assignment = newValue
        }
        get {
            _assignmentLock.lock()
            defer { _assignmentLock.unlock() }
            return _assignment
        }
    }
    private var minimumDelay: TimeInterval
    private var workingQueue: DispatchQueue
    private var executeLock: NSLock = NSLock()
    private var lastExecute: Date?
    private var lastLoadBlocked: Bool = false
    private var scheduled: Bool = false
    
    init(minimumDelay: TimeInterval, queue: DispatchQueue = DispatchQueue.main) {
        self.minimumDelay = minimumDelay
        self.workingQueue = queue
    }
    
    func throttle(job: (() -> ())?) {
        assignment = job
        executeLock.lock()
        defer { executeLock.unlock() }
        guard let capture = job else {
            return
        }
        if let lastExec = lastExecute {
            let val = abs(lastExec.timeIntervalSinceNow)
            if val < minimumDelay {
                lastLoadBlocked = true
                if !scheduled {
                    scheduled = true
                    workingQueue.asyncAfter(deadline: .now() + (minimumDelay - val)) {
                        self.throttle(job: capture)
                        self.scheduled = false
                    }
                }
                return
            }
            lastExecute = Date()
            workingQueue.async {
                capture()
            }
        } else {
            lastExecute = Date()
            workingQueue.async {
                capture()
            }
        }
    }
    
}
