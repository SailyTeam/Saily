//
//  SetupViewController.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/8.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import AptRepository
import Digger
import Dog
import DropDown
import Renet
import SnapKit
import SwifterSwift
import UIKit

private var kSetupCompleted = false
private var accessLock = NSLock()

class SetupViewController: UIViewController {
    let descriptionLabel = UILabel()

    static var setupCompleted: Bool { kSetupCompleted }

    override func viewDidLoad() {
        super.viewDidLoad()

        descriptionLabel.textColor = .gray
        descriptionLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .semibold)
        view.addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { x in
            x.centerX.equalTo(self.view)
            x.centerY.equalTo(self.view).offset(25)
        }

        DispatchQueue.global().async {
            self.dispatchSetup()
        }
    }

    func dispatchSetup() {
        accessLock.lock()
        if kSetupCompleted {
            DispatchQueue.main.async {
                self.dispatchAllocInterface()
            }
        } else {
            bootstrapApplication()
            kSetupCompleted = true
            DispatchQueue.main.async {
                self.dispatchAllocInterface()
            }
        }
        accessLock.unlock()
    }

    func bootstrapApplication() {
        #if !DEBUG
            UserDefaults.standard.set(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
        #endif

        // MARK: - CENTER

        do {
            DispatchQueue.main.async { [self] in
                descriptionLabel.text = NSLocalizedString("INITIALIZING_REPOSITORY_ENGINE", comment: "Initializing Repository Engine")
            }
            _ = PackageCenter.default
            DispatchQueue.main.async { [self] in
                descriptionLabel.text = NSLocalizedString("INITIALIZING_PACKAGES_ENGINE", comment: "Initializing Packages Engine")
            }
            _ = RepositoryCenter.default
            RepositoryCenter.default.networkingRedirect = cRepositoryRedirection
        }

        DispatchQueue.main.async { [self] in
            descriptionLabel.text = NSLocalizedString("CONFIGURAING_APPLICATION", comment: "Configuring Application")
        }

        // MARK: - DROPDOWN

        do {
            DropDown.startListeningToKeyboard()

            let appearance = DropDown.appearance()
            appearance.textColor = UIColor(named: "TEXT_TITLE")!
            appearance.selectedTextColor = UIColor.white
            appearance.textFont = .roundedFont(ofSize: 18, weight: .semibold)
            appearance.backgroundColor = UIColor(light: .white,
                                                 dark: .init(hex: 0x2C2C2E)!)
            appearance.shadowColor = .black
            appearance.setupShadowOpacity(0.1)
            appearance.selectionBackgroundColor = UIColor(hex: 0x93D5DC)!
            appearance.layer.shadowOpacity = 0.1
            appearance.cellHeight = 60
        }

        // MARK: - DOWNLOAD ENGINE

        if let bundleId = Bundle.main.bundleIdentifier {
            let result = SGRenet.resolveNetworkProblemForApp(withBundleId: bundleId)
            Dog.shared.join("SGRenet", "resolveNetworkProblemForApp withBundleId \(bundleId) returns \(result)")
        }

        DiggerManager.shared.allowsCellularAccess = true
        DiggerManager.shared.logLevel = .high
        DiggerManager.shared.maxConcurrentTasksCount = 8
        DiggerManager.shared.startDownloadImmediately = false

        _ = CariolNetwork.shared

        // MARK: - iCloud Avatar

        AppleAvatar.prepareIconIfAvailable()

        // MARK: - PROCESSOR

        AuxiliaryExecute.setupExecutables()
        _ = TaskProcessor.shared
    }

    func dispatchAllocInterface() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let target = storyboard.instantiateViewController(withIdentifier: "NavigatorEnterViewController")
        target.modalPresentationStyle = .fullScreen
        view.window?.rootViewController = target
    }
}
