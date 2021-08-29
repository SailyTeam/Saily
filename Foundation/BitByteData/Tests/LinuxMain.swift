import XCTest

import BitByteDataBenchmarks
import BitByteDataTests

var tests = [XCTestCaseEntry]()
tests += BitByteDataBenchmarks.__allTests()
tests += BitByteDataTests.__allTests()

XCTMain(tests)
