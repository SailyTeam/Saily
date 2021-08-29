// Copyright (c) 2021 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import Foundation
import SWCompression
import SwiftCLI

/// This extension allows to use `BlockSize` as a `Key` option.
extension BZip2.BlockSize: ConvertibleFromString {
    public static func convert(from: String) -> BZip2.BlockSize? {
        guard let num = Int(from)
        else { return nil }
        return BZip2.BlockSize(rawValue: num)
    }
}
