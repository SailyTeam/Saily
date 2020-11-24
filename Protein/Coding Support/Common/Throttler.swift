//
//  Throttler.swift
//  Protein
//
//  Created by soulghost on 10/5/2020.
//  from https://www.craftappco.com/blog/2018/5/30/simple-throttling-in-swift
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

class CommonThrottler {

    @Atomic private var workItem: DispatchWorkItem = DispatchWorkItem(block: {})
//    private var lock: NSLock = NSLock()
    private var previousRun: Date = Date.distantPast
    private let queue: DispatchQueue
    private let minimumDelay: TimeInterval

    init(minimumDelay: TimeInterval, queue: DispatchQueue = DispatchQueue.main) {
        self.minimumDelay = minimumDelay
        self.queue = queue
    }

    deinit {
        
    }
    
    func throttle(_ block: @escaping () -> Void) {
        
        let priv = workItem
        // Re-assign workItem with the new block task, resetting the previousRun time when it executes
        let item = DispatchWorkItem() {
            [weak self] in
            self?.previousRun = Date()
            block()
        }
        
        // Cancel any existing work item if it has not yet executed
//        lock.lock()
//        workItem.cancel()
        workItem = item
        priv.cancel()
//        lock.unlock()
        
        // If the time since the previous run is more than the required minimum delay
        // => execute the workItem immediately
        // else
        // => delay the workItem execution by the minimum delay time
        let delay = previousRun.timeIntervalSinceNow > minimumDelay ? 0 : minimumDelay
        queue.asyncAfter(deadline: .now() + Double(delay), execute: item)
        
    }
}
