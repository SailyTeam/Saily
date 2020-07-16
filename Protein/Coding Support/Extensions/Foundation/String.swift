//
//  String.swift
//  Protein
//
//  Created by Lakr Aream on 2020/4/18.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import UIKit
import CommonCrypto

extension String {
    
    func base64Encoded() -> String? {
        return data(using: .utf8)?.base64EncodedString()
    }
    
    func base64Decoded() -> String? {
        guard let data = Data(base64Encoded: self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    static var clipBoardContext: String {
        get {
            if let pasteboardString = UIPasteboard.general.string {
                return pasteboardString
            }
            return ""
        }
    }
    
    func pushClipBoard() {
        UIPasteboard.general.string = self
    }
    
    func localized(_ lang: String? = nil, comment: String = "") -> String {
        if let lang = lang {
            if let path = Bundle.main.path(forResource: lang, ofType: "lproj"), let bundle = Bundle(path: path) {
                return NSLocalizedString(self, tableName: nil, bundle: bundle, value: "", comment: comment)
            } else {
                return NSLocalizedString(self, comment: comment)
            }
        } else {
            let userLanguage = ConfigManager.shared.Application.usedLanguage
            if userLanguage != "" {
                if let path = Bundle.main.path(forResource: userLanguage, ofType: "lproj"), let bundle = Bundle(path: path) {
                    return NSLocalizedString(self, tableName: nil, bundle: bundle, value: "", comment: comment)
                } else {
                    return NSLocalizedString(self, comment: comment)
                }
            } else if NSLocalizedString("LANGUAGE_FALG_233", comment: comment) == "LANGUAGE_FALG_233" {
                if let path = Bundle.main.path(forResource: "en", ofType: "lproj"), let bundle = Bundle(path: path) {
                    return NSLocalizedString(self, tableName: nil, bundle: bundle, value: "", comment: comment)
                } else {
                    return NSLocalizedString(self, comment: comment)
                }
            } else {
                return NSLocalizedString(self, comment: comment)
            }
        }
    }
    
    mutating func removeSpaces() {
        while self.hasPrefix(" ") {
            self.removeFirst()
        }
        while self.hasSuffix(" ") {
            self.removeLast()
        }
    }
    
    mutating func removeNewLine() {
        while self.hasPrefix("\n") {
            self.removeFirst()
        }
        while self.hasSuffix("\n") {
            self.removeLast()
        }
    }
    
    mutating func cleanAndReplaceLineBreaker() {
        self = self.replacingOccurrences(of: "\r\n", with: "\n", options: .literal, range: nil)
        self = self.replacingOccurrences(of: "\r", with: "\n", options: .literal, range: nil)
    }
    
    mutating func cleanAndReplaceLineBreakerInIfLet() -> Bool {
        self = self.replacingOccurrences(of: "\r\n", with: "\n", options: .literal, range: nil)
        self = self.replacingOccurrences(of: "\r", with: "\n", options: .literal, range: nil)
        return true
    }
    
    func getSuggestedHeight(font: UIFont, widthOfView: CGFloat) -> CGFloat {
        let frame = NSString(string: self).boundingRect(
            with: CGSize(width: widthOfView, height: .infinity),
            options: [.usesFontLeading, .usesLineFragmentOrigin],
            attributes: [.font : font],
            context: nil)
        return frame.size.height
    }
    
    func share(fromView anchor: UIView? = nil) {
        let poper = UIActivityViewController(activityItems: [self], applicationActivities: nil)
        var top = UIViewController()
        if var topController = UIApplication.mainWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            top = topController
        }
        if let popoverController = poper.popoverPresentationController {
            popoverController.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
            popoverController.sourceView = anchor
            popoverController.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
        }
        top.present(poper, animated: true, completion: nil)
    }
    
    func getQRCodeImage() -> UIImage? {
        let data = self.data(using: String.Encoding.ascii)
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 3, y: 3)
            if let output = filter.outputImage?.transformed(by: transform) {
                return UIImage(ciImage: output)
            }
        }
        return nil
    }
    
    static func md5From(data: Data) -> String {
        let length = Int(CC_MD5_DIGEST_LENGTH)
        let messageData = data
        var digestData = Data(count: length)
        _ = digestData.withUnsafeMutableBytes { digestBytes -> UInt8 in
            messageData.withUnsafeBytes { messageBytes -> UInt8 in
                if let messageBytesBaseAddress = messageBytes.baseAddress, let digestBytesBlindMemory = digestBytes.bindMemory(to: UInt8.self).baseAddress {
                    let messageLength = CC_LONG(messageData.count)
                    CC_MD5(messageBytesBaseAddress, messageLength, digestBytesBlindMemory)
                }
                return 0
            }
        }
        let md5Hex =  digestData.map { String(format: "%02hhx", $0) }.joined()
        return md5Hex
    }
    
    static func sha1From(data: Data) -> String {
        var digest = [UInt8](repeating: 0, count:Int(CC_SHA1_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA1($0.baseAddress, CC_LONG(data.count), &digest)
        }
        let hexBytes = digest.map { String(format: "%02hhx", $0) }
        let sha1Hex = hexBytes.joined()
        return sha1Hex
    }
    
    static func sha256From(data: Data) -> String {
        var digest = [UInt8](repeating: 0, count:Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &digest)
        }
        let hexBytes = digest.map { String(format: "%02hhx", $0) }
        let sha256Hex = hexBytes.joined()
        return sha256Hex
    }
    
    func indices(of occurrence: String) -> [Int] {
        var indices = [Int]()
        var position = startIndex
        while let range = range(of: occurrence, range: position..<endIndex) {
            let i = distance(from: startIndex,
                             to: range.lowerBound)
            indices.append(i)
            let offset = occurrence.distance(from: occurrence.startIndex,
                                             to: occurrence.endIndex) - 1
            guard let after = index(range.lowerBound,
                                    offsetBy: offset,
                                    limitedBy: endIndex) else {
                                        break
            }
            position = index(after: after)
        }
        return indices
    }
    
    func ranges(of searchString: String) -> [Range<String.Index>] {
        let _indices = indices(of: searchString)
        let count = searchString.count
        return _indices.map({ index(startIndex, offsetBy: $0)..<index(startIndex, offsetBy: $0+count) })
    }
    
    func widthOfString(usingFont font: UIFont) -> CGFloat {
         let fontAttributes = [NSAttributedString.Key.font: font]
         let size = self.size(withAttributes: fontAttributes)
         return size.width
     }

     func heightOfString(usingFont font: UIFont) -> CGFloat {
         let fontAttributes = [NSAttributedString.Key.font: font]
         let size = self.size(withAttributes: fontAttributes)
         return size.height
     }

     func sizeOfString(usingFont font: UIFont) -> CGSize {
         let fontAttributes = [NSAttributedString.Key.font: font]
         return self.size(withAttributes: fontAttributes)
     }
}

extension NSAttributedString {
    convenience init(data: Data, documentType: DocumentType, encoding: String.Encoding = .utf8) throws {
        try self.init(data: data,
                      options: [.documentType: documentType,
                                .characterEncoding: encoding.rawValue],
                      documentAttributes: nil)
    }
    convenience init(html data: Data) throws {
        try self.init(data: data, documentType: .html)
    }
    convenience init(txt data: Data) throws {
        try self.init(data: data, documentType: .plain)
    }
    convenience init(rtf data: Data) throws {
        try self.init(data: data, documentType: .rtf)
    }
    convenience init(rtfd data: Data) throws {
        try self.init(data: data, documentType: .rtfd)
    }
    
}

extension NSMutableAttributedString {
    
    func setFontFace(font: UIFont, color: UIColor? = nil) {
        beginEditing()
        self.enumerateAttribute(
            .font,
            in: NSRange(location: 0, length: self.length)
        ) { (value, range, _) in
            
            if let f = value as? UIFont,
                let newFontDescriptor = f.fontDescriptor
                    .withFamily(font.familyName)
                    .withSymbolicTraits(f.fontDescriptor.symbolicTraits) {
                
                let newFont = UIFont(
                    descriptor: newFontDescriptor,
                    size: font.pointSize
                )
                removeAttribute(.font, range: range)
                addAttribute(.font, value: newFont, range: range)
                if let color = color {
                    removeAttribute(
                        .foregroundColor,
                        range: range
                    )
                    addAttribute(
                        .foregroundColor,
                        value: color,
                        range: range
                    )
                }
            }
        }
        endEditing()
    }
    
}

extension StringProtocol {
    var data: Data { return Data(utf8) }
    var htmlToAttributedString: NSAttributedString? {
        do {
            return try .init(html: data)
        } catch {
            print("[E] Extension StringProtocol: html err:", error)
            return nil
        }
    }
    var htmlDataToString: String? {
        return htmlToAttributedString?.string
    }
}
