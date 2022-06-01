//
//  DiggerDelegate.swift
//  Digger
//
//  Created by ant on 2017/10/25.
//  Copyright © 2017年 github.cornerant. All rights reserved.
//

import Foundation

public class DiggerDelegate: NSObject {
    var manager: DiggerManager?
}

// MARK: -  SessionDelegate

extension DiggerDelegate: URLSessionDataDelegate, URLSessionDelegate {
    public func urlSession(_: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        guard let manager = manager else { return }
        guard let url = dataTask.originalRequest?.url, let diggerSeed = manager.findDiggerSeed(with: url) else {
            return
        }

        // the file has been downloaded
        if DiggerCache.isFileExist(atPath: DiggerCache.cachePath(url: url)) {
            let cachesURL = URL(fileURLWithPath: DiggerCache.cachePath(url: url))
//            let errorInfo = ["theFileHasbeenDownloaded": cachesURL]
//            let error = NSError(domain: DiggerErrorDomain, code: DiggerError.fileIsExist.rawValue, userInfo: errorInfo)
//            notifyCompletionCallback(Result.failure(error), diggerSeed)
            dataTask.cancel()
            notifyCompletionCallback(.success(cachesURL), diggerSeed)
            return
        }
        /// status code
        if let statusCode = (response as? HTTPURLResponse)?.statusCode,
           !(200 ..< 400).contains(statusCode)
        {
            let error = NSError(domain: DiggerErrorDomain,
                                code: DiggerError.invalidStatusCode.rawValue,
                                userInfo: ["statusCode": statusCode, NSLocalizedDescriptionKey: HTTPURLResponse.localizedString(forStatusCode: statusCode)])

            notifyCompletionCallback(Result.failure(error), diggerSeed)

            return
        }

        guard let responseHeaders = (response as? HTTPURLResponse)?.allHeaderFields as? [String: String] else {
            return
        }

        // rangeString    String    "bytes 9660646-72300329/72300330"
        if let totalBytesString = responseHeaders["Content-Length"], let totalBytes = Int64(totalBytesString) {
            diggerSeed.progress.totalUnitCount = totalBytes
        }

        if let completedBytesString = responseHeaders["Content-Range"]?.components(separatedBy: "-").first?.components(separatedBy: " ").last,
           let completedBytes = Int64(completedBytesString)
        {
            diggerSeed.progress.completedUnitCount = completedBytes
        }

        if diggerSeed.progress.totalUnitCount >= DiggerCache.systemFreeSize() {
            let errorInfo = ["diskOutOfSpace,check systemFreeSize ": url]
            let error = NSError(domain: DiggerErrorDomain, code: DiggerError.diskOutOfSpace.rawValue, userInfo: errorInfo)

            notifyCompletionCallback(Result.failure(error), diggerSeed)

            return
        }

        if diggerSeed.progress.fractionCompleted > 1.0 { // file error
            DiggerCache.removeItem(atPath: diggerSeed.tempPath)
            let error = NSError(domain: DiggerErrorDomain, code: DiggerError.fileInfoError.rawValue, userInfo: nil)
            notifyCompletionCallback(Result.failure(error), diggerSeed)
            DiggerCache.moveItem(atPath: diggerSeed.tempPath, toPath: diggerSeed.cachePath)

            return

        } else if diggerSeed.progress.fractionCompleted == 1.0 { // file Is Exist in temp
            DiggerCache.moveItem(atPath: diggerSeed.tempPath, toPath: diggerSeed.cachePath)
            notifyCompletionCallback(Result.success(diggerSeed.cacheFileURL), diggerSeed)

            return

        } else {
            diggerSeed.outputStream = OutputStream(toFileAtPath: diggerSeed.tempPath, append: true)
            diggerSeed.outputStream?.open()

            diggerLog("start to download  \n" + url.absoluteString)
            completionHandler(.allow)
        }
    }

    public func urlSession(_: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let manager = manager else { return }

        guard let url = dataTask.originalRequest?.url, let diggerSeed = manager.findDiggerSeed(with: url) else {
            return
        }

        diggerSeed.progress.completedUnitCount += Int64((data as NSData).length)
        let buffer = [UInt8](data)

        diggerSeed.outputStream?.write(buffer, maxLength: (data as NSData).length)
        notifyProgressCallback(diggerSeed)
    }

    public func urlSession(_: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let manager = manager else { return }

        guard let url = task.originalRequest?.url, let diggerSeed = manager.findDiggerSeed(with: url) else {
            return
        }

        if let errorInfo = error {
            notifyCompletionCallback(Result.failure(errorInfo), diggerSeed)

        } else {
            notifyCompletionCallback(Result.success(diggerSeed.cacheFileURL), diggerSeed)
        }

        diggerSeed.outputStream?.close()
    }
}

// MARK: -  notifyCallback

extension DiggerDelegate {
    func notifyProgressCallback(_ diggerSeed: DiggerSeed) {
        notifySpeedCallback(diggerSeed)

        DispatchQueue.main.safeAsync {
            _ = diggerSeed.callbacks.map { $0.progress?(diggerSeed.progress) }
        }
    }

    func notifyCompletionCallback(_ result: Result<URL>, _ diggerSeed: DiggerSeed) {
        guard let manager = manager else { return }

        switch result {
        case let .failure(error as NSError):
            if error.code == DiggerError.downloadCanceled.rawValue {
                // If a task is cancelled, the temporary file will be deleted
                DiggerCache.removeItem(atPath: diggerSeed.tempPath)
            }

            diggerLog(error)

        case let .success(url):

            DiggerCache.moveItem(atPath: diggerSeed.tempPath, toPath: diggerSeed.cachePath)

            diggerLog("download success \n" + url.absoluteString)
        }

        manager.removeDigeerSeed(for: diggerSeed.url)

        DispatchQueue.main.safeAsync {
            _ = diggerSeed.callbacks.map { $0.completion?(result) }
        }
        notifySpeedZeroCallback(diggerSeed)
    }

    func notifySpeedCallback(_ diggerSeed: DiggerSeed) {
        let progress = diggerSeed.progress
        var dataCount = progress.completedUnitCount
        let time = Double(NSDate().timeIntervalSince1970)
        var lastData: Int64 = 0
        var lastTime: Double = 0

        if progress.userInfo[.throughputKey] != nil {
            lastData = progress.userInfo[.fileCompletedCountKey] as! Int64
        } else {
            dataCount = 0
        }

        if progress.userInfo[.estimatedTimeRemainingKey] != nil {
            lastTime = progress.userInfo[.estimatedTimeRemainingKey] as! Double
        }

        if (time - lastTime) <= 1.0 {
            return
        }
        let speed = Int64(Double(dataCount - lastData) / (time - lastTime))
        progress.setUserInfoObject(dataCount, forKey: .fileCompletedCountKey)
        progress.setUserInfoObject(time, forKey: .estimatedTimeRemainingKey)
        progress.setUserInfoObject(speed, forKey: .throughputKey)

        if let speed = progress.userInfo[.throughputKey] as? Int64 {
            DispatchQueue.main.safeAsync {
                _ = diggerSeed.callbacks.map { $0.speed?(speed) }
            }
        }
    }

    /// speed should be zero, when cancel or suspend

    public func notifySpeedZeroCallback(_ diggerSeed: DiggerSeed) {
        DispatchQueue.main.safeAsync {
            _ = diggerSeed.callbacks.map { $0.speed?(0) }
        }
    }
}
