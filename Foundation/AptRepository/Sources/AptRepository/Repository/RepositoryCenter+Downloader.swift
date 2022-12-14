//
//  RepositoryCenter+Api.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/6.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import Dog
import Foundation
import SWCompression

internal extension RepositoryCenter {
    // MARK: - Downloader

    /// download data and wait, header is injected from networkingHeaders, timeout is used with networkingTimeout
    /// - Parameter fromUrl: data url
    /// - Returns: data if success
    func downloadData(fromUrl: URL) -> Data? {
        var request = URLRequest(
            url: fromUrl,
            cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
            timeoutInterval: TimeInterval(networkingTimeout)
        )
        networkingHeaders.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        var returningData: Data?
        let sem = DispatchSemaphore(value: 0)
        debugPrint("requesting to \(request.url?.absoluteString ?? "")")
        URLSession
            .shared
            .dataTask(with: request) { data, resp, error in
                if let resp = resp as? HTTPURLResponse,
                   resp.statusCode == 200,
                   error == nil,
                   let data = data
                {
                    returningData = data
                }
                if let error = error {
                    print(error.localizedDescription)
                }
                sem.signal()
            }
            .resume()
        _ = sem.wait(timeout: .now() + Double(networkingTimeout))
        return returningData
    }

    /// download avatar data
    /// - Parameter withUrl: url
    /// - Returns: data if success
    func downloadUpdateAvatar(withUrl: URL) -> Data? {
        downloadData(fromUrl: withUrl)
    }

    /// download release metadata from repo, re-encode if isoLatin1 found
    /// - Parameter withUrl: target url
    /// - Returns: release metadata if success
    func downloadUpdateRelease(withUrl: URL) -> String? {
        guard let data = downloadData(fromUrl: withUrl) else { return nil }
        guard let original = String(data: data, encoding: .utf8) else { return nil }
        if let decode = original.data(using: .isoLatin1, allowLossyConversion: false),
           let reEncoded = String(data: decode, encoding: .utf8)
        {
            return reEncoded
        }
        return original
    }

    /// detect if this repo supports commercial package
    /// - Parameter withUrl: target url, we will append payment_endpoint inside the function
    /// - Returns: endpoint if success
    func detectPaymentEndpoint(withUrl: URL) -> String? {
        guard let data = downloadData(fromUrl: withUrl.appendingPathComponent("payment_endpoint"))
        else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    /// detect if this repo supports featured package and returns json data
    /// - Parameter withUrl: target url, we will append featured.json inside the function
    /// - Returns: json string if success
    func detectFeaturedMetadata(withUrl: URL) -> String? {
        guard let data = downloadData(fromUrl: withUrl.appendingPathComponent("sileo-featured.json")),
              let str = String(data: data, encoding: .utf8),
              str.contains("FeaturedBannersView")
        else {
//            not working good
//            JSONSerialization.isValidJSONObject(data)
            return nil
        }
        return str
    }

    /// download the package, decompress if needed
    /// - Parameters:
    ///   - withBaseUrl: base url
    ///   - suffix: url path extension
    /// - Returns: package metadata if success
    func downloadUpdatePackage(withBaseUrl: URL, suffix: String) -> String? {
        let targetUrl = withBaseUrl.appendingPathExtension(suffix)
        guard let data = downloadData(fromUrl: targetUrl) else { return nil }
        var resultBuilder: String?
        switch suffix {
        case "":
            resultBuilder = String(data: data, encoding: .utf8)
        case "bz", "bz2":
            if data.count > 0,
               let decompress = try? BZip2.decompress(data: data)
            {
                if let str = String(data: decompress, encoding: .utf8) {
                    resultBuilder = str
                } else if let str = String(data: decompress, encoding: .ascii) {
                    resultBuilder = str
                }
            }
        case "gz", "gz2":
            if data.count > 0,
               let decompress = try? GzipArchive.unarchive(archive: data)
            {
                if let str = String(data: decompress, encoding: .utf8) {
                    resultBuilder = str
                } else if let str = String(data: decompress, encoding: .ascii) {
                    resultBuilder = str
                }
            }
        case "lzma":
            if data.count > 0,
               let decompress = try? LZMA.decompress(data: data)
            {
                if let str = String(data: decompress, encoding: .utf8) {
                    resultBuilder = str
                } else if let str = String(data: decompress, encoding: .ascii) {
                    resultBuilder = str
                }
            }
        case "lzma2":
            if data.count > 0,
               let decompress = try? LZMA2.decompress(data: data)
            {
                if let str = String(data: decompress, encoding: .utf8) {
                    resultBuilder = str
                } else if let str = String(data: decompress, encoding: .ascii) {
                    resultBuilder = str
                }
            }
        case "xz", "xz2":
            if data.count > 0,
               let decompress = try? XZArchive.unarchive(archive: data)
            {
                if let str = String(data: decompress, encoding: .utf8) {
                    resultBuilder = str
                } else if let str = String(data: decompress, encoding: .ascii) {
                    resultBuilder = str
                }
            }
        default:
            Dog.shared.join(self, "unknown archive path extension \(suffix)", level: .error)
        }
        if let decode = resultBuilder?.data(using: .isoLatin1, allowLossyConversion: false),
           let reEncoded = String(data: decode, encoding: .utf8)
        {
            return reEncoded
        }
        return resultBuilder
    }
}
