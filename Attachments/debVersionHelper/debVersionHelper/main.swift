//
//  main.swift
//  debVersionHelper
//
//  Created by Lakr Aream on 8/28/20.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import Foundation

print("DEB Development Package Version Helper v1.0")

if CommandLine.arguments.count != 3 && CommandLine.arguments.count != 4 {
    print("./exec control_file output_file [write version to file]")
    exit(-1)
}


extension String {
    mutating func removeSpaces() {
        while self.hasPrefix(" ") {
            self.removeFirst()
        }
        while self.hasSuffix(" ") {
            self.removeLast()
        }
    }
}

// taken from Saily
// https://github.com/SailyTeam/main
func invokeDebianMeta(context: String) -> [String : String] {
    
    if context.count < 2 { return [:] }
    
    var metas = [(String, String)]()
    for compose in context.components(separatedBy: "\n") where compose != "" {
        var line = compose
        line.removeSpaces()
        if line.contains(":") && !compose.hasPrefix("  ") {
            let split = line.components(separatedBy: ":")
            if split.count >= 2 {
                var key = split[0]
                var val = ""
                for (index, item) in split.enumerated() where index > 0 {
                    var get = item
                    get.removeSpaces()
                    val += get
                    val += ":"
                }
                val.removeLast()
                key.removeSpaces()
                val.removeSpaces()
                metas.append((key, val))
            } else {
            }
        } else {
            if var get = metas.last {
                metas.removeLast()
                get.1 = get.1 + "\n" + line
                metas.append(get)
            }
        }
    }
    
    var ret = [String : String]()
    metas.forEach { (object) in
        let key = object.0 //.lowercased()
        var val = object.1
//        if DEFINE.DPKG_CONTROL_LOWERKEYS.contains(key) {
//            val = val.lowercased()
//        }
        ret[key] = val
    }
    return ret
    
}

let read = try! String(contentsOfFile: CommandLine.arguments[1])
print("\n------ READ ------\n")
var invoke = invokeDebianMeta(context: read)
print(invoke)
print("\n------------------\n")

let orig = invoke["Version"]!
let new = orig + "-" + String(Int(Date().timeIntervalSince1970 / 10000))
print("Setting new version: \(new)")
invoke["Version"] = new
var out = ""
for (key, value) in invoke {
    out += key + ": " + value + "\n"
}
out += "\n"

print("\n------ OUT ------\n")
print(out)
print("\n-----------------\n")

print("Writting file...")
try! out.write(toFile: CommandLine.arguments[2], atomically: true, encoding: .utf8)

if CommandLine.arguments.count == 4 {
    print("Writing version to file...")
    try! new.write(toFile: CommandLine.arguments[3], atomically: true, encoding: .utf8)
}

print("DONE!")
