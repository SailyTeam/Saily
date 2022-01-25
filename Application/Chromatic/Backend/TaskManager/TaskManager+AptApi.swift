//
//  TaskManager+Load.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/21.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import AptRepository
import Dog
import Foundation

extension TaskManager {
    // MARK: - STRUCTURE

    enum PackageResolutionResult {
        case success(resolvedActions: [PackageAction])
        case removeErrorTooManyDependency
        case brokenResource
        case missingRequired
        case breaksOther
        case unknownError
    }

    // MARK: STRUCTURE -

    func startPackageResolution(action: PackageAction) -> PackageResolutionResult {
        let date = Date()
        defer {
            let time = Date().timeIntervalSince(date)
            let text = String(format: "package resolution completed in %.2f seconds", time)
            Dog.shared.join(self, text, level: .info)
        }
        switch action.action {
        case .install: return resolveInstall(action: action)
        case .remove: return resolveRemove(action: action)
        }
    }

    private func resolveInstall(action: PackageAction) -> PackageResolutionResult {
        var context = copyCurrentUserActions()
        context.append(action)
        return resolvePackageActions(context: context, dryRun: false)
    }

    private func resolveRemove(action: PackageAction) -> PackageResolutionResult {
        var context = copyCurrentUserActions()
        context.append(action)
        return resolvePackageActions(context: context, dryRun: false)
    }

    // MARK: - OPERATER

    /// resolve any dependencies that required by the action
    /// - Parameters:
    ///   - context: the copy of user actions, will be modified when processing to avoid dependency loop
    ///   - dryRun: do not commit to task manager if set true
    /// - Returns: resolution result
    @discardableResult private
    func resolvePackageActions(context: [PackageAction], dryRun: Bool) -> PackageResolutionResult {
        var resolvedActions = [PackageAction]()
        PackageActionReport.shared.openSession()
        defer {
            PackageActionReport.shared.commit()
        }
        Dog.shared.join(self, "resolving package requests")

        // MARK: - step 1, separate action pool

        let content = context.filter(\.isUserRequired)
        var removeIdentitySet = Set<String>()
        let originalRemoveRequest = content
            .filter { $0.action == .remove }
            .filter {
                if removeIdentitySet.contains($0.represent.identity) {
                    return false
                }
                removeIdentitySet.insert($0.represent.identity)
                return true
            }
        var installIdentitySet = Set<String>()
        let originalInstallRequest = content
            .filter { $0.action == .install }
            .filter {
                if installIdentitySet.contains($0.represent.identity) {
                    return false
                }
                if removeIdentitySet.contains($0.represent.identity) {
                    return false
                }
                installIdentitySet.insert($0.represent.identity)
                return true
            }
        var blockedFromRemoveQueue: [String] = []

        // MARK: - step 2, build removal extra remove

        do {
            var removedContext = [Package]()
            let installation = PackageCenter.default.obtainInstalledPackageList()
            for removeRequest in originalRemoveRequest {
                var success = true
                removedContext = searchRemovalBarrier(success: &success,
                                                      removeRequest: removeRequest,
                                                      removedContext: removedContext,
                                                      installation: installation)
                if !success {
                    return .removeErrorTooManyDependency
                }
            }
            var removalQueue = [PackageAction]()
            let map = originalRemoveRequest.map(\.represent.identity)
            for item in removedContext {
                guard let action = PackageAction(action: .remove,
                                                 represent: item,
                                                 isUserRequired: map.contains(item.identity))
                else {
                    return .brokenResource
                }
                removalQueue.append(action)
            }
            Dog.shared.join(self, "resolved removal queue with \(removalQueue.count)")
            resolvedActions.append(contentsOf: removalQueue)
            blockedFromRemoveQueue = removalQueue.map(\.represent.identity)
        }

        // MARK: - step 3, extend install request with their dependencies

        do {
            var missingPackage: [String] = []
            var breakPackages: [String] = []
            var installContext = [Package]()
            for request in originalInstallRequest {
                installContext = searchInstallExtra(installRequest: request,
                                                    installContext: installContext,
                                                    removing: blockedFromRemoveQueue,
                                                    missingPackage: &missingPackage,
                                                    breakPackage: &breakPackages)
            }
            if missingPackage.count > 0 {
                return .missingRequired
            }
            if breakPackages.count > 0 {
                return .breaksOther
            }
            var installQueue = [PackageAction]()
            let map = originalInstallRequest.map(\.represent.identity)
            for item in installContext {
                guard let action = PackageAction(action: .install,
                                                 represent: item,
                                                 isUserRequired: map.contains(item.identity))
                else {
                    return .brokenResource
                }
                installQueue.append(action)
            }
            resolvedActions.append(contentsOf: installQueue)
        }

        // MARK: - step 4, commit if needed

        if !dryRun {
            resolvedActions.forEach { action in
                Dog.shared.join(self,
                                "\(action.action.rawValue) \(action.represent.identity) \(action.represent.latestVersion ?? "0.0.0.???") \(action.represent.repoRef?.absoluteString ?? "no repo") user required? \(action.isUserRequired)",
                                level: .verbose)
            }
            commitResolved(resolvedActions: resolvedActions)
        }

        PackageActionReport.shared.clear()
        return .success(resolvedActions: resolvedActions)
    }

    func cancelActionWithPackage(identity: String) -> PackageResolutionResult {
        let copy = copyCurrentUserActions()
            .filter { $0.represent.identity != identity }
        return resolvePackageActions(context: copy, dryRun: false)
    }

    @discardableResult
    func updateEverything() -> Bool {
        PackageActionReport.shared.clear()
        PackageActionReport.shared.openSession()
        let installed = PackageCenter
            .default
            .obtainInstalledPackageList()
        var actions = [PackageAction]()
        for item in installed {
            guard let version = item.latestVersion else { continue }
            let candidate = PackageCenter
                .default
                .obtainUpdateForPackage(with: item.identity,
                                        version: version)
                .compactMap { $0 }
            guard let decision = PackageCenter
                .default
                .newestPackage(of: candidate),
                let action = PackageAction(action: .install,
                                           represent: decision,
                                           isUserRequired: true)
            else {
                continue
            }
            Dog.shared.join(self,
                            "update candidate \(item.identity) [\(item.latestVersion ?? "0.0.0.???")] -> [\(decision.latestVersion ?? "0.0.0.???")] (\(decision.repoRef?.absoluteString ?? "unknown repo")",
                            level: .info)
            actions.append(action)
        }
        var result: PackageResolutionResult?
        actions.forEach { result = resolveInstall(action: $0) }
        PackageActionReport.shared.commit()
        guard let commitResult = result else {
            return false
        }
        switch commitResult {
        case .success(resolvedActions: _): return true
        default: return false
        }
    }
}
