//
//  DirectInstall.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/27.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import AptRepository
import Dog
import UIKit

class DirectInstallController: UIViewController {
    var patternLocation: URL?

    let indicator = UIActivityIndicatorView()
    let text = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        preferredContentSize = preferredPopOverSize
        view.addSubview(indicator)
        indicator.snp.makeConstraints { x in
            x.centerX.equalToSuperview()
            x.centerY.equalToSuperview().offset(-10)
        }
        indicator.startAnimating()
        text.textColor = .gray
        text.font = .monospacedDigitSystemFont(ofSize: 12, weight: .semibold)
        view.addSubview(text)
        text.snp.makeConstraints { x in
            x.centerX.equalToSuperview()
            x.centerY.equalToSuperview().offset(10)
        }
        text.text = NSLocalizedString("UNPACKING_PACKAGE", comment: "Unpacking Package")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        defer {
            text.text = ""
            indicator.stopAnimating()
        }

        guard let url = patternLocation else {
            failedAndExit()
            return
        }

        let targetDir = documentsDirectory
            .appendingPathComponent("DirectInstallCache")
            .appendingPathComponent(UUID().uuidString)
        var copiedLocation = URL(fileURLWithPath: "")
        let meta = unpackPackage(from: url, toDir: targetDir, withCopiedPayload: &copiedLocation)
        guard let meta = meta,
              let build = Package(from: meta, injecting: [
                  DirectInstallInjectedPackageLocationKey:
                      copiedLocation.path,
              ])
        else {
            failedAndExit(with: NSLocalizedString("FAILED_VERIFY_PACKAGE",
                                                  comment: "Failed to verify package"))
            return
        }
        let target = PackageController(package: build)
        if let navigator = navigationController {
            navigator.popViewController(animated: true) {
                navigator.pushViewController(target)
            }
        } else {
            let presenter = presentingViewController
            target.modalTransitionStyle = .coverVertical
            target.modalPresentationStyle = .formSheet
            dismiss(animated: true) {
                presenter?.present(target, animated: true, completion: nil)
            }
        }
    }

    func failedAndExit(with reason: String? = nil) {
        func callDismiss() {
            if let navigator = navigationController {
                navigator.popViewController()
            } else {
                dismiss(animated: true, completion: nil)
            }
        }
        Dog.shared.join(self, "failed with reason: \(reason ?? "unknown")", level: .error)
        if let reason = reason {
            let alert = UIAlertController(title: NSLocalizedString("ERROR", comment: "Error"),
                                          message: reason,
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("DISMISS", comment: "Dismiss"),
                                          style: .default,
                                          handler: { _ in
                                              callDismiss()
                                          }))
            present(alert, animated: true, completion: nil)
        } else {
            callDismiss()
        }
    }

    typealias Success = Bool
    func unpackPackage(from: URL, toDir: URL, withCopiedPayload: inout URL) -> String? {
        Dog.shared.join(self, "unpacking package metadata at \(from.path) to \(toDir.path)", level: .info)
        do {
            if FileManager.default.fileExists(atPath: toDir.path) {
                try FileManager.default.removeItem(at: toDir)
            }
            try FileManager.default.createDirectory(at: toDir,
                                                    withIntermediateDirectories: true,
                                                    attributes: nil)
            withCopiedPayload = toDir.appendingPathComponent("DirectInstall-\(UUID().uuidString).deb")
            try FileManager.default.moveItem(at: from,
                                             to: withCopiedPayload)
        } catch {
            Dog.shared.join(self, "permission denied \(error.localizedDescription)")
            return nil
        }
        let result = AuxiliaryExecuteWrapper.mobilespawn(command: AuxiliaryExecuteWrapper.dpkg,
                                                         args: ["-e", withCopiedPayload.path, toDir.path],
                                                         timeout: 10) { str in
            debugPrint(str)
        }
        Dog.shared.join(self, "unpacking package metadata returned \(result.0)", level: .info)
        let control = toDir
            .appendingPathComponent("control")
        do {
            return try String(contentsOf: control)
        } catch {
            Dog.shared.join(self, "can not read control file \(error.localizedDescription)")
            return nil
        }
    }
}
