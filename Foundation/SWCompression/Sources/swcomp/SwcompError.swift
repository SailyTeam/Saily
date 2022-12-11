// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import Foundation

enum SwcompError {
    case noOutputPath
    case lz4BigDictId
    case lz4NoDict
    case lz4BigBlockSize
    case benchmarkSmallIterCount
    case benchmarkUnknownCompResult
    case benchmarkCannotSetup(Benchmark.Type, String, Error)
    case benchmarkCannotMeasure(Benchmark.Type, Error)
    case benchmarkCannotMeasureBadOutSize(Benchmark.Type)
    case benchmarkReaderTarNoInputSize(String)
    case benchmarkCannotGetSubcommandPathWindows
    case benchmarkCannotAppendToDirectory
    case containerSymLinkDestPath(String)
    case containerHardLinkDestPath(String)
    case containerNoEntryData(String)
    case containerOutPathExistsNotDir
    case fileHandleCannotOpen
    case tarCreateXzNotSupported
    case tarCreateOutPathExists
    case tarCreateInPathDoesNotExist

    var errorCode: Int32 {
        switch self {
        case .noOutputPath:
            return 1
        case .lz4BigDictId:
            return 101
        case .lz4NoDict:
            return 102
        case .lz4BigBlockSize:
            return 103
        case .benchmarkSmallIterCount:
            return 201
        case .benchmarkUnknownCompResult:
            return 202
        case .benchmarkCannotSetup:
            return 203
        case .benchmarkCannotMeasure:
            return 204
        case .benchmarkCannotMeasureBadOutSize:
            return 214
        case .benchmarkReaderTarNoInputSize:
            return 205
        case .benchmarkCannotGetSubcommandPathWindows:
            return 206
        case .benchmarkCannotAppendToDirectory:
            return 207
        case .containerSymLinkDestPath:
            return 301
        case .containerHardLinkDestPath:
            return 311
        case .containerNoEntryData:
            return 302
        case .containerOutPathExistsNotDir:
            return 303
        case .fileHandleCannotOpen:
            return 401
        case .tarCreateXzNotSupported:
            return 501
        case .tarCreateOutPathExists:
            return 502
        case .tarCreateInPathDoesNotExist:
            return 503
        }
    }

    var message: String {
        switch self {
        case .noOutputPath:
            return "Unable to get output path and no output parameter was specified."
        case .lz4BigDictId:
            return "Too large dictionary ID."
        case .lz4NoDict:
            return "Dictionary ID is specified without specifying the dictionary itself."
        case .lz4BigBlockSize:
            return "Too big block size."
        case .benchmarkSmallIterCount:
            return "Iteration count, if set, must be not less than 1."
        case .benchmarkUnknownCompResult:
            return "Unknown comparison."
        case let .benchmarkCannotSetup(benchmark, input, error):
            return "Unable to set up benchmark \(benchmark): input=\(input), error=\(error)."
        case let .benchmarkCannotMeasure(benchmark, error):
            return "Unable to measure benchmark \(benchmark), error=\(error)."
        case let .benchmarkCannotMeasureBadOutSize(benchmark):
            return "Unable to measure benchmark \(benchmark): outputData.count is not greater than zero."
        case let .benchmarkReaderTarNoInputSize(input):
            return "ReaderTAR.benchmarkSetUp(): file size is not available for input=\(input)."
        case .benchmarkCannotGetSubcommandPathWindows:
            return "Cannot get subcommand path on Windows. (This error should never be shown!)"
        case .benchmarkCannotAppendToDirectory:
            return "Cannot append results to the save path since it is a directory."
        case let .containerSymLinkDestPath(entryName):
            return "Unable to get destination path for symbolic link \(entryName)."
        case let .containerHardLinkDestPath(entryName):
            return "Unable to get destination path for hard link \(entryName)."
        case let .containerNoEntryData(entryName):
            return "Unable to get data for the entry \(entryName)."
        case .containerOutPathExistsNotDir:
            return "Specified output path already exists and is not a directory."
        case .fileHandleCannotOpen:
            return "Unable to open input file."
        case .tarCreateXzNotSupported:
            return "XZ compression is not supported when creating a container."
        case .tarCreateOutPathExists:
            return "Output path already exists."
        case .tarCreateInPathDoesNotExist:
            return "Specified input path doesn't exist."
        }
    }
}

func swcompExit(_ error: SwcompError) -> Never {
    print("\nERROR: \(error.message)")
    exit(error.errorCode)
}
