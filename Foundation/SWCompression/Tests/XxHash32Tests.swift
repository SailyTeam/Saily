// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import Foundation
@testable import SWCompression
import XCTest

class XxHash32Tests: XCTestCase {
    func test1() {
        let message = ""
        let answer = 0x02CC_5D05 as UInt32
        let hash = XxHash32.hash(data: Data(message.utf8))
        XCTAssertEqual(hash, answer)
    }

    func test2() {
        let message = "a"
        let answer = 0x550D_7456 as UInt32
        let hash = XxHash32.hash(data: Data(message.utf8))
        XCTAssertEqual(hash, answer)
    }

    func test3() {
        let message = "abc"
        let answer = 0x32D1_53FF as UInt32
        let hash = XxHash32.hash(data: Data(message.utf8))
        XCTAssertEqual(hash, answer)
    }

    func test4() {
        let message = "message digest"
        let answer = 0x7C94_8494 as UInt32
        let hash = XxHash32.hash(data: Data(message.utf8))
        XCTAssertEqual(hash, answer)
    }

    func test5() {
        let message = "abcdefghijklmnopqrstuvwxyz"
        let answer = 0x63A1_4D5F as UInt32
        let hash = XxHash32.hash(data: Data(message.utf8))
        XCTAssertEqual(hash, answer)
    }

    func test6() {
        let message = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
        let answer = 0x9C28_5E64 as UInt32
        let hash = XxHash32.hash(data: Data(message.utf8))
        XCTAssertEqual(hash, answer)
    }

    func test7() {
        let message = "12345678901234567890123456789012345678901234567890123456789012345678901234567890"
        let answer = 0x9C05_F475 as UInt32
        let hash = XxHash32.hash(data: Data(message.utf8))
        XCTAssertEqual(hash, answer)
    }
}
