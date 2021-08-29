// Copyright (c) 2021 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import Foundation

/// Also known as PAX header.
struct TarExtendedHeader {
    var unknownRecords = [String: String]()

    var atime: Double?
    var ctime: Double?
    var mtime: Double?

    var size: Int?

    var uid: Int?
    var gid: Int?

    var uname: String?
    var gname: String?

    var path: String?
    var linkpath: String?

    var charset: String?
    var comment: String?

    init(_ data: Data) throws {
        // Split header data into entries with "\n" (0x0A) character as a separator.
        let entriesData = data.split(separator: 0x0A)

        var unknownRecords = [String: String]()

        for entryData in entriesData where !entryData.isEmpty {
            let entryDataSplit = entryData.split(separator: 0x20, maxSplits: 1, omittingEmptySubsequences: false)

            guard entryDataSplit.count == 2,
                  let lengthString = String(data: entryDataSplit[0], encoding: .utf8),
                  Int(lengthString) == entryData.count + 1
            else { throw TarError.wrongPaxHeaderEntry }

            // Split header entry into key-value pair with "=" (0x3D) character as a separator.
            let keyValueDataPair = entryDataSplit[1].split(separator: 0x3D, maxSplits: 1,
                                                           omittingEmptySubsequences: false)

            guard keyValueDataPair.count == 2,
                  let key = String(data: keyValueDataPair[0], encoding: .utf8),
                  let value = String(data: keyValueDataPair[1], encoding: .utf8)
            else { throw TarError.wrongPaxHeaderEntry }

            switch key {
            case "uid":
                self.uid = Int(value)
            case "gid":
                self.gid = Int(value)
            case "uname":
                self.uname = value
            case "gname":
                self.gname = value
            case "size":
                self.size = Int(value)
            case "atime":
                self.atime = Double(value)
            case "ctime":
                self.ctime = Double(value)
            case "mtime":
                self.mtime = Double(value)
            case "path":
                self.path = value
            case "linkpath":
                self.linkpath = value
            case "charset":
                self.charset = value
            case "comment":
                self.comment = value
            default:
                unknownRecords[key] = value
            }
        }

        self.unknownRecords = unknownRecords
    }

    init(_ info: TarEntryInfo) {
        let maxOctalLengthEight = (1 << 24) - 1
        let maxOctalLengthTwelve = (1 << 36) - 1

        if let uid = info.ownerID, uid > maxOctalLengthEight {
            self.uid = uid
        }
        if let gid = info.groupID, gid > maxOctalLengthEight {
            self.gid = gid
        }
        if let uname = info.ownerUserName {
            let asciiUnameData = uname.data(using: .ascii)
            if asciiUnameData == nil || asciiUnameData!.count > 32 {
                self.uname = uname
            }
        }
        if let gname = info.ownerGroupName {
            let asciiGnameData = gname.data(using: .ascii)
            if asciiGnameData == nil || asciiGnameData!.count > 32 {
                self.gname = gname
            }
        }
        if let size = info.size, size > maxOctalLengthTwelve {
            self.size = size
        }
        if let mtime = info.modificationTime?.timeIntervalSince1970,
           mtime < 0 || mtime > Double(maxOctalLengthTwelve)
        {
            self.mtime = mtime
        }
        // The non-asciiness of the (link)name is still a reason to use PAX headers, even though we encode using UTF-8
        // in basic TAR headers anyway, because one can imagine a third-party implementation, that can read PAX headers
        // properly, but still expects all string fields in the basic header to be ASCII-only. By using PAX headers we
        // can "support" those implementations, though this will work only if they skip (non-ASCII/invalid) string
        // fields after encountering a PAX header.
        let asciiNameData = info.name.data(using: .ascii)
        if asciiNameData == nil || asciiNameData!.count > 100 {
            path = info.name
        }
        let asciiLinkNameData = info.name.data(using: .ascii)
        if asciiLinkNameData == nil || asciiLinkNameData!.count > 100 {
            linkpath = info.linkName
        }

        atime = info.accessTime?.timeIntervalSince1970
        ctime = info.creationTime?.timeIntervalSince1970
        charset = info.charset
        comment = info.comment
        unknownRecords = info.unknownExtendedHeaderRecords ?? [:]
    }

    func generateContainerData() -> Data {
        var headerString = ""
        if let atime = self.atime {
            headerString += TarExtendedHeader.generateHeaderString("atime", String(atime))
        }

        if let ctime = self.ctime {
            headerString += TarExtendedHeader.generateHeaderString("ctime", String(ctime))
        }

        if let mtime = self.mtime {
            headerString += TarExtendedHeader.generateHeaderString("mtime", String(mtime))
        }

        if let size = self.size {
            headerString += TarExtendedHeader.generateHeaderString("size", String(size))
        }

        if let uid = self.uid {
            headerString += TarExtendedHeader.generateHeaderString("uid", String(uid))
        }

        if let gid = self.gid {
            headerString += TarExtendedHeader.generateHeaderString("gid", String(gid))
        }

        if let uname = self.uname {
            headerString += TarExtendedHeader.generateHeaderString("uname", uname)
        }

        if let gname = self.gname {
            headerString += TarExtendedHeader.generateHeaderString("gname", gname)
        }

        if let path = self.path {
            headerString += TarExtendedHeader.generateHeaderString("path", path)
        }

        if let linkpath = self.linkpath {
            headerString += TarExtendedHeader.generateHeaderString("linkpath", linkpath)
        }

        if let charset = self.charset {
            headerString += TarExtendedHeader.generateHeaderString("charset", charset)
        }

        if let comment = self.comment {
            headerString += TarExtendedHeader.generateHeaderString("comment", comment)
        }

        for (key, value) in unknownRecords {
            headerString += TarExtendedHeader.generateHeaderString(key, value)
        }

        return Data(headerString.utf8)
    }

    private static func generateHeaderString(_ fieldName: String, _ valueString: String) -> String {
        let valueCount = Data(valueString.utf8).count
        return TarExtendedHeader.calculateCountString(fieldName, valueCount) + " \(fieldName)=\(valueString)\n"
    }

    private static func calculateCountString(_ fieldName: String, _ valueCount: Int) -> String {
        let fixedCount = 3 + fieldName.count + valueCount // 3 = Space + "=" + "\n"
        var countStr = String(fixedCount)
        // Workaround for cases when number of figures in count increases when the count itself is included.
        while true {
            let totalCount = fixedCount + countStr.count
            if String(totalCount).count > countStr.count {
                countStr = String(totalCount)
                continue
            } else {
                countStr = String(totalCount)
                break
            }
        }
        return countStr
    }
}
