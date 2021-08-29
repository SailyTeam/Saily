// Copyright (c) 2021 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import Foundation
import SWCompression
import SwiftCLI

class ZipCommand: ContainerCommand {
    let name = "zip"
    let shortDescription = "Extracts a ZIP container"

    let info = Flag("-i", "--info", description: "Print the list of entries in a container and their attributes")
    let extract = Key<String>("-e", "--extract", description: "Extract a container into the specified directory")
    let verbose = Flag("-v", "--verbose", description: "Print the list of extracted files and directories.")

    let archive = Parameter()

    let openFunction: (Data) throws -> [ZipEntry] = ZipContainer.open
    let infoFunction: (Data) throws -> [ZipEntryInfo] = ZipContainer.info
}
