//
//  Console.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/12/14.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import Dog
import Foundation

protocol ConsoleCommand {
    func resolveCommand(_: String) -> Bool
    func printHelp()
}

class Console {
    static let current = Console()
    private init() {}

    private let commandList: [ConsoleCommand] = [
        CCRecovery(),
    ]

    func enterConsoleMode() -> Never {
        Dog.shared.join(self, "entering command line mode", level: .info)
        InterfaceBridge.removeRecoveryFlag(with: #function, userRequested: true)
        while true {
            let command = readLine(strippingNewline: true)
            guard let command = command else {
                fatalError("EOF returned from readLine()")
            }
            if command == "help" {
                commandList.forEach { $0.printHelp() }
                continue
            }
            if command == "exit" {
                exit(0)
            }
            var resolved = false
            for consoleCommand in commandList {
                if consoleCommand.resolveCommand(command) {
                    resolved = true
                    break
                }
            }
            if !resolved {
                Dog.shared.join(self, "command not found", level: .error)
            } else {
                Dog.shared.join(self, "command completed", level: .info)
            }
        }
    }
}
