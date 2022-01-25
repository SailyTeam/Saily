// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import Foundation
import SWCompression
import SwiftCLI

// This extension allows to use TarContainer.Format as a Key option.
extension TarContainer.Format: ConvertibleFromString {
    public init?(input: String) {
        switch input {
        case "prePosix":
            self = .prePosix
        case "ustar":
            self = .ustar
        case "gnu":
            self = .gnu
        case "pax":
            self = .pax
        default:
            return nil
        }
    }
}
