//
//  Console+Recovery.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/12/15.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import Foundation

class CCRecovery: ConsoleCommand {
    func printHelp() {
        print(
            """
            [recovery]
                - enter: mark application broken
                         enter recovery next time open in springboard
                - leave: mark application fixed
            """
        )
    }

    func resolveCommand(_ command: String) -> Bool {
        var commandElements = command.components(separatedBy: " ")
        guard commandElements.count >= 1,
              commandElements.first == "recovery"
        else {
            return false
        }
        commandElements.removeFirst()
        execute(args: commandElements)
        return true
    }

    func execute(args: [String]) {
        func brokenCommand() {
            print("invalid arguments")
            printHelp()
        }
        guard args.count >= 1 else {
            brokenCommand()
            return
        }
        switch args[0] {
        case "enter":
            try? "911".write(toFile: applicationRecoveryFlag.path,
                             atomically: true,
                             encoding: .utf8)
        case "leave":
            InterfaceBridge.removeRecoveryFlag(with: #function, userRequested: true)
        default:
            brokenCommand()
            return
        }
    }
}
