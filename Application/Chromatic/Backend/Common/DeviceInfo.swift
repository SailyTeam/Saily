//
//  DeviceInfo.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/25.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import AptRepository
import Digger
import Dog
import Foundation
import PropertyWrapper
import UIKit

class DeviceInfo {
    static let current = DeviceInfo()

    @PropertiesWrapper(key: "useRealDeviceInfo", defaultValue: true)
    public var useRealDeviceInfo: Bool {
        didSet {
            setupUserAgents()
        }
    }

    private init() {
        do {
            let foo = dlopen("/usr/lib/libMobileGestalt.dylib", RTLD_GLOBAL | RTLD_LAZY)
            typealias MGCopyAnswerAddr = @convention(c) (CFString) -> CFString
            let lookup = dlsym(foo, "MGCopyAnswer")
            var udid = ""
            if lookup != nil {
                let MGCopyAnswer = unsafeBitCast(lookup, to: MGCopyAnswerAddr.self)
                let read = MGCopyAnswer("UniqueDeviceID" as CFString) as String
                udid = read
                Dog.shared.join("MGCopyAnswer", "UniqueDeviceID returned udid \(read.count) long", level: .info)
            }
            if udid.count < 1 {
                let seed = "0123456789abcdef"
                var build = ""
                while build.count < 40 {
                    build.append("\(seed.randomElement()!)")
                }
                Dog.shared.join("MGCopyAnswer", "UniqueDeviceID lookup failed, using \(build) for requests", level: .warning)
                udid = build
            }
            realDeviceIdentity = udid
        }
    }

    let realDeviceIdentity: String

    var udid: String {
        if useRealDeviceInfo { return realDeviceIdentity }
        let seed = "0123456789abcdef"
        var build = ""
        while build.count < 40 {
            build.append("\(seed.randomElement()!)")
        }
        return build
    }

    var machine: String {
        if useRealDeviceInfo {
            var systemInfo = utsname()
            uname(&systemInfo)
            let machineMirror = Mirror(reflecting: systemInfo.machine)
            let identifier = machineMirror.children.reduce("") { identifier, element in
                guard let value = element.value as? Int8, value != 0 else { return identifier }
                return identifier + String(UnicodeScalar(UInt8(value)))
            }
            return identifier
        }
        return [
            "iPhone6,1", "iPhone6,2", "iPhone7,2", "iPhone7,1", "iPhone8,1", "iPhone8,2", "iPhone9,1", "iPhone9,3", "iPhone9,2", "iPhone9,4", "iPhone8,4", "iPhone10,1", "iPhone10,4", "iPhone10,2", "iPhone10,5", "iPhone10,3", "iPhone10,6", "iPhone11,2", "iPhone11,4", "iPhone11,6", "iPhone11,8", "iPhone12,1", "iPhone12,3", "iPhone12,5", "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4", "iPad3,1", "iPad3,2", "iPad3,3", "iPad3,4", "iPad3,5", "iPad3,6", "iPad6,11", "iPad6,12", "iPad7,5", "iPad7,6", "iPad7,11", "iPad7,12", "iPad4,1", "iPad4,2", "iPad4,3", "iPad5,3", "iPad5,4", "iPad11,4", "iPad11,5", "iPad2,5", "iPad2,6", "iPad2,7", "iPad4,4", "iPad4,5", "iPad4,6", "iPad4,7", "iPad4,8", "iPad4,9", "iPad5,1", "iPad5,2", "iPad11,1", "iPad11,2", "iPad6,3", "iPad6,4", "iPad7,3", "iPad7,4", "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4", "iPad8,9", "iPad8,10", "iPad6,7", "iPad6,8", "iPad7,1", "iPad7,2", "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8", "iPad8,11", "iPad8,12",
        ].randomElement()!
    }

    var firmware: String {
        if useRealDeviceInfo { return UIDevice.current.systemVersion }
        return [
            "13.0", "13.1", "13.2", "13.3", "13.4",
            "12.0", "12.1", "12.2", "12.3", "12.4",
            "11.0", "11.1", "11.2", "11.3", "11.4",
        ].randomElement()!
    }

    func setupUserAgents() {
        RepositoryCenter.default.networkingHeaders = [
            "X-Machine": machine,
            "X-Unique-ID": udid,
            "X-Firmware": firmware,
        ]
        RepositoryCenter.default.networkingHeaders.forEach { key, value in
            DiggerManager.shared.additionalHTTPHeaders[key] = value
        }
    }
}
