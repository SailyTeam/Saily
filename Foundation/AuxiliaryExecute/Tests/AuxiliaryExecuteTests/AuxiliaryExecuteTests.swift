@testable import AuxiliaryExecute
import XCTest

final class AuxiliaryExecuteTests: XCTestCase {
    func testExample() throws {
        do {
            let result = AuxiliaryExecute.local.bash(command: "printf \"\nnya\n\"")
            print(result)
            XCTAssert(result.exitCode == 0)
            XCTAssertNil(result.error)
            XCTAssert(result.stdout == "\nnya\n")
            XCTAssert(result.stderr == "")
        }

        do {
            let result = AuxiliaryExecute.local.shell(
                command: "bash",
                args: ["-c", "echo $mua"],
                environment: ["mua": "nya"],
                timeout: 0
            ) { stdout in
                print(stdout)
            } stderrBlock: { stderr in
                print(stderr)
            }

            XCTAssert(result.exitCode == 0)
            XCTAssertNil(result.error)
            XCTAssert(result.stdout.trimmingCharacters(in: .whitespacesAndNewlines) == "nya")
            XCTAssert(result.stderr == "")
        }

        do {
            let result = AuxiliaryExecute.local.shell(
                command: "bash",
                args: ["-c", "echo $mua"],
                environment: ["mua": "nya=nya="],
                timeout: 0
            ) { stdout in
                print(stdout)
            } stderrBlock: { stderr in
                print(stderr)
            }

            XCTAssert(result.exitCode == 0)
            XCTAssertNil(result.error)
            XCTAssert(result.stdout.trimmingCharacters(in: .whitespacesAndNewlines) == "nya=nya=")
            XCTAssert(result.stderr == "")
        }

        do {
            let result = AuxiliaryExecute.local.shell(
                command: "tail",
                args: ["-f", "/dev/null"],
                timeout: 1
            ) { stdout in
                print(stdout)
            } stderrBlock: { stderr in
                print(stderr)
            }

            XCTAssert(result.exitCode == SIGKILL)
            XCTAssert(result.error == .timeout)
        }
    }
}
