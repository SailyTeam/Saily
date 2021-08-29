//  SwiftThrottle.swift
//  Twitter @Lakr233
//
//  Created by Lakr Aream on 12/12/20.
//

import Foundation

/*

 This throttle is intended to prevent the program from crashing with
 too many requests or is used for saving computer resources.

 ** Swift Throttle is not designed for operations that require high time accuracy **

 */

// MARK: - THROTTLE

public class Throttle {
    // MARK: - PROPERTY

    /// Setup with these values to control the throttle behave
    /// - minimumDelay >= 0.5 second is suggested
    public private(set) var minimumDelay: TimeInterval
    public private(set) var workingQueue: DispatchQueue

    /// lock when dispatch job to execution
    private var executeLock = NSLock()

    /// These value controls throttle behavior
    public private(set) var lastExecute: Date?
    public private(set) var lastRequestWasCanceled: Bool = false
    public private(set) var scheduled: Bool = false

    /// Lock when setting jobs, required by thread safe design
    private var _assignmentLock = NSLock()
    private var _assignment: (() -> Void)?
    public private(set) var assignment: (() -> Void)? {
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

    // MARK: - INIT

    /// Create a throttle
    /// - Parameters:
    ///   - minimumDelay: in second
    ///   - queue: the queue that job will executed on, default to main
    public init(minimumDelay delay: TimeInterval,
                queue: DispatchQueue = DispatchQueue.main)
    {
        minimumDelay = delay
        workingQueue = queue

        #if DEBUG
            if minimumDelay < 0.5 {
                // we suggest minimumDelay to be at least 0.5 second
                debugPrint("[SwiftThrottle] "
                    + "minimumDelay(\(minimumDelay) less then 0.5s will be inaccurate"
                    + ", last callback not guaranteed")
            }
        #endif
    }

    // MARK: - API

    /// Update property minimumDelay
    /// - Parameter interval: in second
    public func updateMinimumDelay(interval: Double) {
        executeLock.lock()
        minimumDelay = interval
        executeLock.unlock()
    }

    /// Assign job to throttle
    /// - Parameter job: call block
    public func throttle(job: (() -> Void)?) {
        realThrottle(job: job, useAssignment: false)
    }

    // MARK: - BACKEND

    /// Check nothing but execute
    /// - Parameter capturedJob: block to execute
    private func releaseExec(capturedJob: @escaping (() -> Void)) {
        lastExecute = Date()
        workingQueue.async {
            capturedJob()
        }
    }

    /// Throttle is working here
    /// - Parameters:
    ///   - job: block that was required to execute
    ///   - useAssignment: shall we overwrite assigned job?
    private func realThrottle(job: (() -> Void)?, useAssignment: Bool) {
        // lock down every thing when resigning job
        executeLock.lock()
        defer { self.executeLock.unlock() }

        // if called from rescheduled job, cancel job overwrite
        var capturedJobDecision: (() -> Void)?
        if !useAssignment {
            // resign job every time calling from user
            assignment = job
            capturedJobDecision = job
        } else {
            capturedJobDecision = assignment
        }
        guard let capturedJob = capturedJobDecision else { return }

        // MARK: LOCK BEGIN

        if let lastExec = lastExecute {
            // executed before, value negative
            let timeBetween = -lastExec.timeIntervalSinceNow

            if timeBetween < minimumDelay {
                // The throttle will be reprogrammed once for future execution
                lastRequestWasCanceled = true
                if !scheduled {
                    scheduled = true
                    let dispatchTime = Double(minimumDelay - timeBetween + 0.01)
                    // Preventing trigger failures
                    // This is where the inaccuracy comes from
                    workingQueue.asyncAfter(deadline: .now() + dispatchTime) {
                        self.realThrottle(job: nil, useAssignment: true)
                        self.scheduled = false
                    }
                }
            } else {
                // Throttle release to execution
                releaseExec(capturedJob: capturedJob)
            }
        }
        else // never called before, release to execution
        {
            releaseExec(capturedJob: capturedJob)
        }

        // MARK: LOCK END
    }
}
