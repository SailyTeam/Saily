// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import Foundation
import SWCompression
import SwiftCLI

let cli = CLI(name: "swcomp", version: "4.8.0",
              description: """
              swcomp - a small command-line client for SWCompression framework.
              Serves as an example of SWCompression usage.
              """)
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
