//
//  UserDefault.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/6.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import Foundation

public enum Properties {
    private static var storeLocation: URL?
    private static var onError: (String) -> Void = { _ in }

    public static func setup(storeAt location: URL, onError errorCall: @escaping (String) -> Void) {
        storeLocation = location
        onError = errorCall

        do {
            try? FileManager.default.createDirectory(at: location, withIntermediateDirectories: true)
            var isDir = ObjCBool(false)
            let exists = FileManager.default.fileExists(atPath: location.path, isDirectory: &isDir)
            guard exists, isDir.boolValue else {
                fatalError("Broken Setting Permission")
            }
        }
    }

    private static func locationFor(key: String) -> URL? {
        storeLocation?.appendingPathComponent(key)
    }

    static func read(key: String) -> Data? {
        guard let url = locationFor(key: key) else {
            return nil
        }
        return try? Data(contentsOf: url)
    }

    static func write(key: String, value: Data?) {
        guard let url = locationFor(key: key) else {
            return
        }
        do {
            try? FileManager.default.removeItem(at: url)
            if let value { try value.write(to: url) }
        } catch {
            onError(error.localizedDescription)
        }
    }
}

let encoder = JSONEncoder()
let decoder = JSONDecoder()

@propertyWrapper
public struct PropertiesWrapper<Value: Codable> {
    let key: String
    let defaultValue: Value

    let accessLock = NSLock()
    var cachedValue: Value?

    public init(key: String, defaultValue: Value) {
        self.key = key
        self.defaultValue = defaultValue
        cachedValue = retainDiskValue()
    }

    public var wrappedValue: Value {
        get {
            accessLock.lock()
            let value = cachedValue
                ?? retainDiskValue()
                ?? defaultValue
            accessLock.unlock()
            return value
        }
        set {
            accessLock.lock()
            cachedValue = newValue
            writeDiskValue(newValue: newValue)
            accessLock.unlock()
        }
    }

    private func retainDiskValue() -> Value? {
        guard let data = Properties.read(key: key),
              let object = try? decoder.decode(Value.self, from: data)
        else {
            return nil
        }
        return object
    }

    private func writeDiskValue(newValue: Value?) {
        if let newValue,
           let data = try? encoder.encode(newValue)
        {
            Properties.write(key: key, value: data)
        } else {
            Properties.write(key: key, value: nil)
        }
    }
}
