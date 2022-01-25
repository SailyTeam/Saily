// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import Foundation

/// Represents file attributes in DOS format.
public struct DosAttributes: OptionSet {
    /// Raw bit flags value.
    public let rawValue: UInt32

    /// Initializes attributes with bit flags.
    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    /// File is archive or archived.
    public static let archive = DosAttributes(rawValue: 0b0010_0000)

    /// File is a directory.
    public static let directory = DosAttributes(rawValue: 0b0001_0000)

    /// File is a volume.
    public static let volume = DosAttributes(rawValue: 0b0000_1000)

    /// File is a system file.
    public static let system = DosAttributes(rawValue: 0b0000_0100)

    /// File is hidden.
    public static let hidden = DosAttributes(rawValue: 0b0000_0010)

    /// File is read-only.
    public static let readOnly = DosAttributes(rawValue: 0b0000_0001)
}
