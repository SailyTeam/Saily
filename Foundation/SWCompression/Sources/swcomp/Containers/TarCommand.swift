// Copyright (c) 2022 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import Foundation
import SWCompression
import SwiftCLI

final class TarCommand: Command {
    let name = "tar"
    let shortDescription = "Extracts a TAR container"

    @Flag("-z", "--gz", description: "With -e: decompress with GZip first; with -c: compress container with GZip")
    var gz: Bool

    @Flag("-j", "--bz2", description: "With -e: decompress with BZip2 first; with -c: compress container with BZip2")
    var bz2: Bool

    @Flag("-x", "--xz", description: "With -e: decompress with XZ first; with -c: not supported")
    var xz: Bool

    @Flag("-i", "--info", description: "Print the information about of the entries in the container including their attributes")
    var info: Bool

    @Flag("-l", "--list", description: "Print the list of names of the entries in the container")
    var list: Bool

    @Key("-e", "--extract", description: "Extract a container into specified directory")
    var extract: String?

    @Flag("-f", "--format", description: "Print the \"format\" of a container")
    var format: Bool

    @Key("-c", "--create", description: "Create a new container containing the specified file/directory (recursively)")
    var create: String?

    @Key("--use-format", description: "Use specified TAR format when creating a container; available options: prePosix, ustar, gnu, pax")
    var useFormat: TarContainer.Format?

    @Flag("-v", "--verbose", description: "Print the list of extracted files and directories.")
    var verbose: Bool

    var optionGroups: [OptionGroup] {
        [.atMostOne($gz, $bz2, $xz), .exactlyOne($info, $list, $extract, $format, $create)]
    }

    @Param var input: String

    func execute() throws {
        if useFormat != nil && create == nil {
            print("WARNING: --use-format option is ignored without -c/--create option")
        }

        var fileData: Data
        if create == nil {
            fileData = try Data(contentsOf: URL(fileURLWithPath: input),
                                options: .mappedIfSafe)

            if gz {
                fileData = try GzipArchive.unarchive(archive: fileData)
            } else if bz2 {
                fileData = try BZip2.decompress(data: fileData)
            } else if xz {
                fileData = try XZArchive.unarchive(archive: fileData)
            }
        } else {
            fileData = Data()
        }

        if info || list {
            if gz {
                fileData = try Data(contentsOf: URL(fileURLWithPath: input),
                                    options: .mappedIfSafe)
                fileData = try GzipArchive.unarchive(archive: fileData)
                let entries = try TarContainer.info(container: fileData)
                if info {
                    swcomp.printInfo(entries)
                } else {
                    swcomp.printList(entries)
                }
            } else if bz2 {
                fileData = try Data(contentsOf: URL(fileURLWithPath: input),
                                    options: .mappedIfSafe)
                fileData = try BZip2.decompress(data: fileData)
                let entries = try TarContainer.info(container: fileData)
                if info {
                    swcomp.printInfo(entries)
                } else {
                    swcomp.printList(entries)
                }
            } else if xz {
                fileData = try Data(contentsOf: URL(fileURLWithPath: input),
                                    options: .mappedIfSafe)
                fileData = try XZArchive.unarchive(archive: fileData)
                let entries = try TarContainer.info(container: fileData)
                if info {
                    swcomp.printInfo(entries)
                } else {
                    swcomp.printList(entries)
                }
            } else {
                guard let handle = FileHandle(forReadingAtPath: input)
                else { swcompExit(.fileHandleCannotOpen) }

                var reader = TarReader(fileHandle: handle)
                var isFinished = false
                while !isFinished {
                    isFinished = try reader.process { (entry: TarEntry?) -> Bool in
                        guard entry != nil
                        else { return true }
                        if info {
                            print(entry!.info)
                            print("------------------\n")
                        } else {
                            print(entry!.info.name)
                        }
                        return false
                    }
                }
                try handle.closeCompat()
            }
        } else if let outputPath = extract {
            guard try isValidOutputDirectory(outputPath, create: true)
            else { swcompExit(.containerOutPathExistsNotDir) }

            if gz {
                fileData = try Data(contentsOf: URL(fileURLWithPath: input),
                                    options: .mappedIfSafe)
                fileData = try GzipArchive.unarchive(archive: fileData)
                let entries = try TarContainer.open(container: fileData)
                try swcomp.write(entries, outputPath, verbose)
            } else if bz2 {
                fileData = try Data(contentsOf: URL(fileURLWithPath: input),
                                    options: .mappedIfSafe)
                fileData = try BZip2.decompress(data: fileData)
                let entries = try TarContainer.open(container: fileData)
                try swcomp.write(entries, outputPath, verbose)
            } else if xz {
                fileData = try Data(contentsOf: URL(fileURLWithPath: input),
                                    options: .mappedIfSafe)
                fileData = try XZArchive.unarchive(archive: fileData)
                let entries = try TarContainer.open(container: fileData)
                try swcomp.write(entries, outputPath, verbose)
            } else {
                if verbose {
                    print("d = directory, f = file, l = symbolic link")
                }

                guard let handle = FileHandle(forReadingAtPath: input)
                else { swcompExit(.fileHandleCannotOpen) }
                var reader = TarReader(fileHandle: handle)
                let fileManager = FileManager.default
                let outputURL = URL(fileURLWithPath: outputPath)
                var directoryAttributes = [(attributes: [FileAttributeKey: Any], path: String)]()
                var isFinished = false
                while !isFinished {
                    isFinished = try reader.process { (entry: TarEntry?) -> Bool in
                        guard entry != nil
                        else { return true }
                        if entry!.info.type == .directory {
                            directoryAttributes.append(try writeDirectory(entry!, outputURL, verbose))
                        } else {
                            try writeFile(entry!, outputURL, verbose)
                        }
                        return false
                    }
                }
                try handle.closeCompat()

                for tuple in directoryAttributes {
                    try fileManager.setAttributes(tuple.attributes, ofItemAtPath: tuple.path)
                }
            }
        } else if format {
            let format = try TarContainer.formatOf(container: fileData)
            switch format {
            case .prePosix:
                print("TAR format: pre-POSIX")
            case .ustar:
                print("TAR format: POSIX aka \"ustar\"")
            case .gnu:
                print("TAR format: POSIX with GNU extensions")
            case .pax:
                print("TAR format: PAX")
            }
        } else if let inputPath = create {
            guard !xz
            else { swcompExit(.tarCreateXzNotSupported) }

            let fileManager = FileManager.default

            guard !fileManager.fileExists(atPath: input)
            else { swcompExit(.tarCreateOutPathExists) }

            guard fileManager.fileExists(atPath: inputPath)
            else { swcompExit(.tarCreateInPathDoesNotExist) }

            if verbose {
                print("Creating new container at \"\(input)\" from \"\(inputPath)\"")
                print("d = directory, f = file, l = symbolic link")
            }
            if gz {
                let entries = try TarEntry.createEntries(inputPath, verbose)
                var outData = TarContainer.create(from: entries, force: useFormat ?? .pax)
                let outputURL = URL(fileURLWithPath: input)
                let fileName = outputURL.lastPathComponent
                outData = try GzipArchive.archive(data: outData, fileName: fileName.isEmpty ? nil : fileName,
                                                  writeHeaderCRC: true)
                try outData.write(to: outputURL)
            } else if bz2 {
                let entries = try TarEntry.createEntries(inputPath, verbose)
                var outData = TarContainer.create(from: entries, force: useFormat ?? .pax)
                let outputURL = URL(fileURLWithPath: input)
                outData = BZip2.compress(data: outData)
                try outData.write(to: outputURL)
            } else {
                let outputURL = URL(fileURLWithPath: input)
                try "".write(to: outputURL, atomically: true, encoding: .utf8)
                let handle = try FileHandle(forWritingTo: outputURL)
                var writer = TarWriter(fileHandle: handle, force: useFormat ?? .pax)
                try TarEntry.generateEntries(&writer, inputPath, verbose)
                try writer.finalize()
                try handle.closeCompat()
            }
        }
    }
}
