@testable import SwiftThrottle
import XCTest

/// Indicates how long the test will run
let multithreadThreshold = 15

final class SwiftThrottleTests: XCTestCase {
    /// Test the throttle
    func test() {
        print("[XCT] Starting test \(#file) \(#function)")

        var testShouldTerminate = false

        let sem = DispatchSemaphore(value: 0)
        let totalTestTime = Double(multithreadThreshold)
        let emitter: Double = 0.5

        // controller
        DispatchQueue.global(qos: .background).async {
            var sec: Double = 1
            while sec < totalTestTime {
                print("Throttle is testing in background... \(sec)/\(totalTestTime)s")
                sec += 1
                sleep(1)
            }
            print("Terminating throttle test...")
            testShouldTerminate = true
            print("Waiting for ending expectation assertions to arrive...")
            sleep(3)
            sem.signal()
        }

        var results = [Int]()
        let results_lock = NSLock()
        DispatchQueue.global(qos: .background).async {
            let cpuCount = ProcessInfo().processorCount
            XCTAssert(cpuCount > 0, "this test must be performed on a machine that has at least 1 cpu core")

            var dispatch = 0
            while dispatch < cpuCount {
                // worker
                let currentDispatchIndex = dispatch + 1
                let name = "ThrottleTest.\(currentDispatchIndex)"
                let queue = DispatchQueue(label: name, attributes: .concurrent) // just in case
                let throttle = Throttle(minimumDelay: Double.random(in: 0 ... 0.1), queue: DispatchQueue(label: name + ".worker"))
                print("Throttle test is starting test thread \(name)")
                throttle.updateMinimumDelay(interval: emitter)
                throttle.throttle(job: nil)
                queue.async {
                    var hit = 0
                    while !testShouldTerminate {
                        throttle.throttle { hit += 1 }
                        // with this sleep follow we get:
                        // Throttle executed for [220, 220, 222, 216, 219, 221, 220, 221] times
                        usleep(useconds_t.random(in: 0 ... 1000))
                    }
                    var endingExpectation = ""
                    let expectValue = "ending.call.successed"
                    throttle.throttle {
                        print("Throttle on thread \(currentDispatchIndex) setting endingExpectation...")
                        endingExpectation = expectValue
                    }
                    sleep(1)
                    XCTAssert(endingExpectation == expectValue, "Throttle failed to program last execution on thread: \(currentDispatchIndex)")
                    results_lock.lock()
                    results.append(hit)
                    results_lock.unlock()
                }
                dispatch += 1
            }
        }

        sem.wait()

        print("Throttle thread safe test completed")
        XCTAssert(results.count > 0)
        print("Throttle executed for \(results) times")

        print("Throttle test completed")

        /*

         ** ABOUT GCD **

         if we dont sleep there we get:
         -> usleep(useconds_t.random(in: 0 ... 1000))

         ---
         Throttle thread safe test completed
         Throttle executed for [303, 303, 303, 0, 0, 0, 0, 303] times
         Throttle test completed
         ---

         -> Throttle executed for [303, 303, 303, 0, 0, 0, 0, 303] times

         this shows that you will still need to handle GCD concurrency in your app in a right way
         this is not a bug and do not use my throttle in a loop without giving up cpu time

         */
    }
}
