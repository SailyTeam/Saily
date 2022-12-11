// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import Foundation
import SWCompression
import SwiftCLI

let _SWC_VERSION = "4.8.3"

let cli = CLI(name: "swcomp", version: _SWC_VERSION,
              description: """
              swcomp - a small command-line client for SWCompression framework.
              Serves as an example of SWCompression usage.
              """)
cli.parser.parseOptionsAfterCollectedParameter = true
cli.commands = [XZCommand(),
                LZ4Command(),
                LZMACommand(),
                BZip2Command(),
                GZipCommand(),
                ZipCommand(),
                TarCommand(),
                SevenZipCommand(),
                BenchmarkGroup()]
cli.goAndExit()
