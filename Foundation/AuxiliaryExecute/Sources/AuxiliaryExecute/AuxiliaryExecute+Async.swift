//
//  AuxiliaryExecute+Spawn.swift
//  AuxiliaryExecute
//
//  Created by Cyandev on 2022/1/10.
//

#if swift(>=5.5)

    import Foundation

    @available(iOS 15.0, macOS 12.0.0, *)
    public extension AuxiliaryExecute {
        /// async/await function for spawn using withCheckedContinuation
        /// - Parameters:
        ///   - command: full path of the binary file. eg: "/bin/cat"
        ///   - args: arg to pass to the binary, exclude argv[0] which is the path itself. eg: ["nya"]
        ///   - environment: any environment to be appended/overwrite when calling posix spawn. eg: ["mua" : "nya"]
        ///   - timeout: any wall timeout if lager than 0, in seconds. eg: 6
        ///   - stdout: a block call from pipeControlQueue in background when buffer from stdout available for read
        ///   - stderr: a block call from pipeControlQueue in background when buffer from stderr available for read
        /// - Returns: execution recipe, see it's definition for details
        @discardableResult
        static func spawnAsync(
            command: String,
            args: [String] = [],
            environment: [String: String] = [:],
            timeout: Double = 0,
            stdoutBlock: ((String) -> Void)? = nil,
            stderrBlock: ((String) -> Void)? = nil
        ) async -> ExecuteRecipe {
            await withCheckedContinuation { cont in
                self.spawn(
                    command: command,
                    args: args,
                    environment: environment,
                    timeout: timeout,
                    stdoutBlock: stdoutBlock,
                    stderrBlock: stderrBlock
                ) { recipe in
                    cont.resume(returning: recipe)
                }
            }
        }

        /// async/await function for spawn using withCheckedContinuation
        /// - Parameters:
        ///   - command: full path of the binary file. eg: "/bin/cat"
        ///   - args: arg to pass to the binary, exclude argv[0] which is the path itself. eg: ["nya"]
        ///   - environment: any environment to be appended/overwrite when calling posix spawn. eg: ["mua" : "nya"]
        ///   - timeout: any wall timeout if lager than 0, in seconds. eg: 6
        ///   - output: a block call from pipeControlQueue in background when buffer from stdout or stderr available for read
        /// - Returns: execution recipe, see it's definition for details
        @discardableResult
        static func spawnAsync(
            command: String,
            args: [String] = [],
            environment: [String: String] = [:],
            timeout: Double = 0,
            output: ((String) -> Void)? = nil
        ) async -> ExecuteRecipe {
            await spawnAsync(
                command: command,
                args: args,
                environment: environment,
                timeout: timeout,
                stdoutBlock: { str in
                    output?(str)
                }, stderrBlock: { str in
                    output?(str)
                }
            )
        }
    }

#endif
