//
//  Project Chromatic
//  Chromatic
//
//  Created by Lakr Aream on 2020/4/18.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import AptPackageVersion
import Dog
import Foundation

/// invoke all metadata downloaded and build packages
/// - Parameters:
///   - original: parser, string
///   - fromRepo: repo reference
/// - Returns: container
internal func invokePackages(withContext original: String, fromRepo: URL? = nil) -> [String: Package] {
    var resultBuilder = [String: Package]()
    original
        .replacingOccurrences(of: "\r\n", with: "\n")
        .replacingOccurrences(of: "\r", with: "\n")
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .components(separatedBy: "\n\n")
        .filter { $0.count > 0 }
        .map { invokeSingleAptMeta(withContext: $0) }
        .compactMap { $0 }
        .forEach { metadata in
            guard let id = metadata["package"]?.lowercased(), // just lowercase
                  let ver = metadata["version"],
                  Package.validateVersion(ver)
            else {
                debugPrint("A package failed to be verified, giving up!")
                debugPrint(metadata)
                return
            }
            if let package = resultBuilder[id] {
                var newpayload = package.payload
                newpayload[ver] = metadata
                let newPackage = Package(identity: package.identity,
                                         payload: newpayload,
                                         repoRef: package.repoRef)
                resultBuilder[id] = newPackage
            } else {
                resultBuilder[id] = Package(identity: id,
                                            payload: [ver: metadata],
                                            repoRef: fromRepo)
            }
        }
    return resultBuilder
}

/// invoke all apt metadata, usually packages
/// - Parameter original: parser, string
/// - Returns: invoked metadata if success, otherwise it would be empty but sure it exists
internal func invokeAptMeta(withContext original: String) -> [[String: String]] {
    original
        .replacingOccurrences(of: "\r\n", with: "\n")
        .replacingOccurrences(of: "\r", with: "\n")
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .components(separatedBy: "\n\n")
        .filter { $0.count > 0 }
        .map { invokeSingleAptMeta(withContext: $0) }
        .compactMap { $0 }
}

/// invoke single apt metadata
/// - Parameter original: parser, string
/// - Returns: invoked metadata if success, requires at least one component
internal func invokeSingleAptMeta(withContext original: String) -> [String: String]? {
    var resultBuilder = [String: String]()
    var lastBuildingKey: String?
    original
        // clean \r\n, usually generate by bash script with mistake
        .replacingOccurrences(of: "\r\n", with: "\n")
        // again
        .replacingOccurrences(of: "\r", with: "\n")
        // clean, do it now, before splitting them
        .trimmingCharacters(in: .whitespacesAndNewlines)
        // cut with line
        .components(separatedBy: "\n")
        // empty line, should not appear here since we filtering it when invokeAptMeta
        .filter { $0.count > 0 }
        // comments
        .filter { !$0.hasPrefix("#") }
        // loop over
        .forEach { line in
            // great, let's build it
            var clearedLine = line
            if clearedLine.contains("#") {
                // ignore comments
                clearedLine = clearedLine
                    .components(separatedBy: "#")
                    .first ?? clearedLine
            }
            clearedLine = clearedLine.trimmingCharacters(in: .whitespaces)
            if line.hasPrefix(" "), // belongs to previous line
               let lastBuildingKey, lastBuildingKey.count > 0, // for robuster
               var lastBuildingValue = resultBuilder[lastBuildingKey]
            { // or invalid line
                // appending this line to lastBuildingValue
                lastBuildingValue += " " + clearedLine
                resultBuilder[lastBuildingKey] = lastBuildingValue
            } else {
                var separator = clearedLine.components(separatedBy: ":")
                guard separator.count >= 2 else {
                    // this line is invalid
                    lastBuildingKey = nil
                    return
                }
                let key = separator
                    .removeFirst()
                    .trimmingCharacters(in: .whitespaces)
                    .lowercased()
                let value = separator
                    .joined(separator: ":")
                    .trimmingCharacters(in: .whitespaces)
                resultBuilder[key] = value
                lastBuildingKey = key
            }
        }
    for (key, value) in resultBuilder {
        // assuming key is all alpha numeric, and value could be something like äé¢¸»é¢»äé»é¢¢
        if let dx = value.data(using: .isoLatin1, allowLossyConversion: false),
           let sx = String(data: dx, encoding: .utf8)
        {
            resultBuilder[key] = sx
        }
    }
    return resultBuilder.keys.count > 0 ? resultBuilder : nil
}

/*

 test metadata

 Origin: Lakr Internal
  with me memem # memememe
 Label: Lakr Internal # some test
 Suite: stable
  # hey
 #
 Version: 1.0
 Codename: ios
 Architectures: iphoneos-arm
 Components: main
 Description: Lakr Internal:lalalala: lalala : lalal # lalallalalaal
  itemmmemememememememe
     ememaifdasifiodsanfoi   #
 Host-Software: Lakr Internal

 aa
 3
 #

 */
