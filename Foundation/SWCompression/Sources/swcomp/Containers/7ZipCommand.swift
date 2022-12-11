// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import Foundation
import SWCompression
import SwiftCLI

final class SevenZipCommand: ContainerCommand {
    typealias ContainerType = SevenZipContainer

    let name = "7z"
    let shortDescription = "Extracts a 7-Zip container"

    @Flag("-i", "--info", description: "Print the information about of the entries in the container including their attributes")
    var info: Bool

    @Flag("-l", "--list", description: "Print the list of names of the entries in the container")
    var list: Bool

    @Key("-e", "--extract", description: "Extract a container into the specified directory")
    var extract: String?

    @Flag("-v", "--verbose", description: "Print the list of extracted files and directories.")
    var verbose: Bool

    @Param var input: String

    var optionGroups: [OptionGroup] {
        [.exactlyOne($info, $list, $extract)]
    }
}
