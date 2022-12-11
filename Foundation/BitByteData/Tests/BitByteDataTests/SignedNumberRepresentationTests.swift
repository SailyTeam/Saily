// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import BitByteData
import XCTest

class SignedNumberRepresentationTests: XCTestCase {
    // MARK: minRepresentableNumber

    func testMinRepresentableNumber_SM() {
        let repr = SignedNumberRepresentation.signMagnitude
        XCTAssertEqual(repr.minRepresentableNumber(bitsCount: 1), 0)
        XCTAssertEqual(repr.minRepresentableNumber(bitsCount: 2), -1)
        XCTAssertEqual(repr.minRepresentableNumber(bitsCount: 11), -1023)
        XCTAssertEqual(repr.minRepresentableNumber(bitsCount: 15), -16383)
        XCTAssertEqual(repr.minRepresentableNumber(bitsCount: 23), -4_194_303)
        XCTAssertEqual(repr.minRepresentableNumber(bitsCount: Int.bitWidth), Int.min)
        XCTAssertEqual(repr.minRepresentableNumber(bitsCount: 335), Int.min)
    }

    func testMinRepresentableNumber_1C() {
        let repr = SignedNumberRepresentation.oneComplementNegatives
        XCTAssertEqual(repr.minRepresentableNumber(bitsCount: 1), 0)
        XCTAssertEqual(repr.minRepresentableNumber(bitsCount: 2), -1)
        XCTAssertEqual(repr.minRepresentableNumber(bitsCount: 11), -1023)
        XCTAssertEqual(repr.minRepresentableNumber(bitsCount: 15), -16383)
        XCTAssertEqual(repr.minRepresentableNumber(bitsCount: 23), -4_194_303)
        XCTAssertEqual(repr.minRepresentableNumber(bitsCount: Int.bitWidth), Int.min)
        XCTAssertEqual(repr.minRepresentableNumber(bitsCount: 335), Int.min)
    }

    func testMinRepresentableNumber_2C() {
        let repr = SignedNumberRepresentation.twoComplementNegatives
        XCTAssertEqual(repr.minRepresentableNumber(bitsCount: 1), -1)
        XCTAssertEqual(repr.minRepresentableNumber(bitsCount: 2), -2)
        XCTAssertEqual(repr.minRepresentableNumber(bitsCount: 11), -1024)
        XCTAssertEqual(repr.minRepresentableNumber(bitsCount: 15), -16384)
        XCTAssertEqual(repr.minRepresentableNumber(bitsCount: 23), -4_194_304)
        XCTAssertEqual(repr.minRepresentableNumber(bitsCount: Int.bitWidth), Int.min)
        XCTAssertEqual(repr.minRepresentableNumber(bitsCount: 335), Int.min)
    }

    func testMinRepresentableNumber_Biased_E3() {
        let repr = SignedNumberRepresentation.biased(bias: 3)
        XCTAssertEqual(repr.minRepresentableNumber(bitsCount: 1), -3)
        XCTAssertEqual(repr.minRepresentableNumber(bitsCount: 2), -3)
        XCTAssertEqual(repr.minRepresentableNumber(bitsCount: 11), -3)
        XCTAssertEqual(repr.minRepresentableNumber(bitsCount: 15), -3)
        XCTAssertEqual(repr.minRepresentableNumber(bitsCount: 23), -3)
        XCTAssertEqual(repr.minRepresentableNumber(bitsCount: Int.bitWidth), -3)
        XCTAssertEqual(repr.minRepresentableNumber(bitsCount: 335), -3)
    }

    func testMinRepresentableNumber_Biased_E127() {
        let repr = SignedNumberRepresentation.biased(bias: 127)
        XCTAssertEqual(repr.minRepresentableNumber(bitsCount: 1), -127)
        XCTAssertEqual(repr.minRepresentableNumber(bitsCount: 2), -127)
        XCTAssertEqual(repr.minRepresentableNumber(bitsCount: 11), -127)
        XCTAssertEqual(repr.minRepresentableNumber(bitsCount: 15), -127)
        XCTAssertEqual(repr.minRepresentableNumber(bitsCount: 23), -127)
        XCTAssertEqual(repr.minRepresentableNumber(bitsCount: Int.bitWidth), -127)
        XCTAssertEqual(repr.minRepresentableNumber(bitsCount: 335), -127)
    }

    func testMinRepresentableNumber_Biased_E1023() {
        let repr = SignedNumberRepresentation.biased(bias: 1023)
        XCTAssertEqual(repr.minRepresentableNumber(bitsCount: 1), -1023)
        XCTAssertEqual(repr.minRepresentableNumber(bitsCount: 2), -1023)
        XCTAssertEqual(repr.minRepresentableNumber(bitsCount: 11), -1023)
        XCTAssertEqual(repr.minRepresentableNumber(bitsCount: 15), -1023)
        XCTAssertEqual(repr.minRepresentableNumber(bitsCount: 23), -1023)
        XCTAssertEqual(repr.minRepresentableNumber(bitsCount: Int.bitWidth), -1023)
        XCTAssertEqual(repr.minRepresentableNumber(bitsCount: 335), -1023)
    }

    func testMinRepresentableNumber_RN2() {
        let repr = SignedNumberRepresentation.radixNegativeTwo
        XCTAssertEqual(repr.minRepresentableNumber(bitsCount: 1), 0)
        XCTAssertEqual(repr.minRepresentableNumber(bitsCount: 2), -2)
        XCTAssertEqual(repr.minRepresentableNumber(bitsCount: 11), -682)
        XCTAssertEqual(repr.minRepresentableNumber(bitsCount: 15), -10922)
        XCTAssertEqual(repr.minRepresentableNumber(bitsCount: 23), -2_796_202)
        XCTAssertEqual(repr.minRepresentableNumber(bitsCount: Int.bitWidth), Int.min)
        XCTAssertEqual(repr.minRepresentableNumber(bitsCount: 335), Int.min)
    }

    // MARK: maxRepresentableNumber

    func testMaxRepresentableNumber_SM() {
        let repr = SignedNumberRepresentation.signMagnitude
        XCTAssertEqual(repr.maxRepresentableNumber(bitsCount: 1), 0)
        XCTAssertEqual(repr.maxRepresentableNumber(bitsCount: 2), 1)
        XCTAssertEqual(repr.maxRepresentableNumber(bitsCount: 11), 1023)
        XCTAssertEqual(repr.maxRepresentableNumber(bitsCount: 15), 16383)
        XCTAssertEqual(repr.maxRepresentableNumber(bitsCount: 23), 4_194_303)
        XCTAssertEqual(repr.maxRepresentableNumber(bitsCount: Int.bitWidth), Int.max)
        XCTAssertEqual(repr.maxRepresentableNumber(bitsCount: 335), Int.max)
    }

    func testMaxRepresentableNumber_1C() {
        let repr = SignedNumberRepresentation.oneComplementNegatives
        XCTAssertEqual(repr.maxRepresentableNumber(bitsCount: 1), 0)
        XCTAssertEqual(repr.maxRepresentableNumber(bitsCount: 2), 1)
        XCTAssertEqual(repr.maxRepresentableNumber(bitsCount: 11), 1023)
        XCTAssertEqual(repr.maxRepresentableNumber(bitsCount: 15), 16383)
        XCTAssertEqual(repr.maxRepresentableNumber(bitsCount: 23), 4_194_303)
        XCTAssertEqual(repr.maxRepresentableNumber(bitsCount: Int.bitWidth), Int.max)
        XCTAssertEqual(repr.maxRepresentableNumber(bitsCount: 335), Int.max)
    }

    func testMaxRepresentableNumber_2C() {
        let repr = SignedNumberRepresentation.twoComplementNegatives
        XCTAssertEqual(repr.maxRepresentableNumber(bitsCount: 1), 0)
        XCTAssertEqual(repr.maxRepresentableNumber(bitsCount: 2), 1)
        XCTAssertEqual(repr.maxRepresentableNumber(bitsCount: 11), 1023)
        XCTAssertEqual(repr.maxRepresentableNumber(bitsCount: 15), 16383)
        XCTAssertEqual(repr.maxRepresentableNumber(bitsCount: 23), 4_194_303)
        XCTAssertEqual(repr.maxRepresentableNumber(bitsCount: Int.bitWidth), Int.max)
        XCTAssertEqual(repr.maxRepresentableNumber(bitsCount: 335), Int.max)
    }

    func testMaxRepresentableNumber_Biased_E3() {
        let repr = SignedNumberRepresentation.biased(bias: 3)
        XCTAssertEqual(repr.maxRepresentableNumber(bitsCount: 1), -2)
        XCTAssertEqual(repr.maxRepresentableNumber(bitsCount: 2), 0)
        XCTAssertEqual(repr.maxRepresentableNumber(bitsCount: 11), 2044)
        XCTAssertEqual(repr.maxRepresentableNumber(bitsCount: 15), 32764)
        XCTAssertEqual(repr.maxRepresentableNumber(bitsCount: 23), 8_388_604)
        XCTAssertEqual(repr.maxRepresentableNumber(bitsCount: Int.bitWidth), Int.max - 3)
        XCTAssertEqual(repr.maxRepresentableNumber(bitsCount: 335), Int.max - 3)
    }

    func testMaxRepresentableNumber_Biased_E127() {
        let repr = SignedNumberRepresentation.biased(bias: 127)
        XCTAssertEqual(repr.maxRepresentableNumber(bitsCount: 1), -126)
        XCTAssertEqual(repr.maxRepresentableNumber(bitsCount: 2), -124)
        XCTAssertEqual(repr.maxRepresentableNumber(bitsCount: 11), 1920)
        XCTAssertEqual(repr.maxRepresentableNumber(bitsCount: 15), 32640)
        XCTAssertEqual(repr.maxRepresentableNumber(bitsCount: 23), 8_388_480)
        XCTAssertEqual(repr.maxRepresentableNumber(bitsCount: Int.bitWidth), Int.max - 127)
        XCTAssertEqual(repr.maxRepresentableNumber(bitsCount: 335), Int.max - 127)
    }

    func testMaxRepresentableNumber_Biased_E1023() {
        let repr = SignedNumberRepresentation.biased(bias: 1023)
        XCTAssertEqual(repr.maxRepresentableNumber(bitsCount: 1), -1022)
        XCTAssertEqual(repr.maxRepresentableNumber(bitsCount: 2), -1020)
        XCTAssertEqual(repr.maxRepresentableNumber(bitsCount: 11), 1024)
        XCTAssertEqual(repr.maxRepresentableNumber(bitsCount: 15), 31744)
        XCTAssertEqual(repr.maxRepresentableNumber(bitsCount: 23), 8_387_584)
        XCTAssertEqual(repr.maxRepresentableNumber(bitsCount: Int.bitWidth), Int.max - 1023)
        XCTAssertEqual(repr.maxRepresentableNumber(bitsCount: 335), Int.max - 1023)
    }

    func testMaxRepresentableNumber_RN2() {
        let repr = SignedNumberRepresentation.radixNegativeTwo
        XCTAssertEqual(repr.maxRepresentableNumber(bitsCount: 1), 1)
        XCTAssertEqual(repr.maxRepresentableNumber(bitsCount: 2), 1)
        XCTAssertEqual(repr.maxRepresentableNumber(bitsCount: 11), 1365)
        XCTAssertEqual(repr.maxRepresentableNumber(bitsCount: 15), 21845)
        XCTAssertEqual(repr.maxRepresentableNumber(bitsCount: 23), 5_592_405)
        XCTAssertEqual(repr.maxRepresentableNumber(bitsCount: Int.bitWidth), 6_148_914_691_236_517_205)
        XCTAssertEqual(repr.maxRepresentableNumber(bitsCount: 335), 6_148_914_691_236_517_205)
    }
}
