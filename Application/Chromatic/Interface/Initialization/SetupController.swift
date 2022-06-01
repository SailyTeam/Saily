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
import SPIndicator
import SwifterSwift
import UIKit

private var kSetupCompleted = false
private var accessLock = NSLock()

class SetupViewController: UIViewController {
    let descriptionLabel = UILabel()

    static var setupCompleted: Bool { kSetupCompleted }

    override func viewDidLoad() {
        super.viewDidLoad()

        if applicationShouldEnterRecovery {
            debugPrint("\(self) applicationShouldEnterRecovery")
            setupRecoveryViews()
            return
        }

        descriptionLabel.text = ""
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
        if AuxiliaryExecuteWrapper.session == nil {
            DispatchQueue.main.async {
                SPIndicator.present(title: "chromaticspawn: EPERM",
                                    message: "",
                                    preset: .error,
                                    haptic: .error,
                                    from: .top,
                                    completion: nil)
            }
        }
    }

    func bootstrapApplication() {
        #if !DEBUG
            UserDefaults.standard.set(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
        #endif

        if #available(iOS 15.0, *) {
            UITableView.appearance().sectionHeaderTopPadding = 0.0
        }

        DeviceInfo.current.setupUserAgents()

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
            appearance.textFont = .roundedFont(ofSize: 16, weight: .semibold)
            appearance.backgroundColor = UIColor(light: .white,
                                                 dark: .init(hex: 0x2C2C2E)!)
            appearance.shadowColor = .black
            appearance.setupShadowOpacity(0.1)
            appearance.selectionBackgroundColor = UIColor(hex: 0x93D5DC)!
            appearance.layer.shadowOpacity = 0.1
            appearance.cellHeight = 45
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

        _ = TaskProcessor.shared
    }

    func dispatchAllocInterface() {
        let controller = NavigatorEnterViewController()
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: false)
        #if DEBUG
            DispatchQueue.global().asyncAfter(deadline: .now() + 6) {
                InterfaceBridge.removeRecoveryFlag(with: #function, userRequested: false)
            }
        #endif
    }

    func setupRecoveryViews() {
        view.subviews.forEach { $0.removeFromSuperview() }

        let powerButton = UIImageView()
        powerButton.image = .fluent(.power24Filled)
        powerButton.tintColor = .gray.withAlphaComponent(0.1)
        powerButton.contentMode = .scaleAspectFit
        view.addSubview(powerButton)
        powerButton.snp.makeConstraints { x in
            x.height.equalTo(300)
            x.width.equalTo(300)
            x.center.equalToSuperview()
        }

        let recoverText =
            """
            There seems to be a problem with our application. You can choose to reset the application or restart it.

            Il semble y avoir un problème avec notre application. Vous pouvez choisir de réinitialiser l'application ou de la redémarrer.

            Es scheint ein Problem mit unserer Anwendung zu geben. Sie können die Anwendung entweder zurücksetzen oder neu starten.

            Parece que hay un problema con nuestra aplicación. Puedes optar por restablecer la aplicación o reiniciarla.

            当社のアプリケーションに問題があるようです。アプリケーションをリセットするか、再起動するかを選択できます。

            应用程序似乎出现了问题。你可以选择重置应用程序或者重新启动。
            """

        let textView = UITextView()
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.isSelectable = true
        textView.backgroundColor = .clear
        textView.font = .roundedFont(ofSize: 10, weight: .semibold)
        textView.text = recoverText
        view.addSubview(textView)
        textView.snp.makeConstraints { x in
            x.height.equalTo(300)
            x.width.equalTo(300)
            x.center.equalToSuperview()
        }

        let resetButton = UIButton()
        resetButton.setImage(.fluent(.deleteForever24Filled), for: .normal)
        resetButton.tintColor = .systemRed
        resetButton.addTarget(self, action: #selector(resetApplication), for: .touchUpInside)
        view.addSubview(resetButton)
        resetButton.snp.makeConstraints { x in
            x.left.equalTo(textView.snp.left)
            x.bottom.equalTo(textView.snp.bottom)
            x.width.equalTo(50)
            x.height.equalTo(50)
        }

        let rebootButton = UIButton()
        rebootButton.setImage(.fluent(.arrowCounterclockwise24Filled), for: .normal)
        rebootButton.tintColor = .systemBlue
        rebootButton.addTarget(self, action: #selector(rebootApplication), for: .touchUpInside)
        view.addSubview(rebootButton)
        rebootButton.snp.makeConstraints { x in
            x.right.equalTo(textView.snp.right)
            x.bottom.equalTo(textView.snp.bottom)
            x.width.equalTo(50)
            x.height.equalTo(50)
        }
    }

    @objc
    func resetApplication() {
        debugPrint("\(#file) \(#function) \(self)")

        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.resetStandardUserDefaults()
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
        debugPrint(Array(UserDefaults.standard.dictionaryRepresentation().keys).count)

        let bundleIdentifier = Bundle
            .main
            .bundleIdentifier ?? "wiki.qaq.chromatic"

        let library = FileManager
            .default
            .urls(for: .libraryDirectory, in: .userDomainMask)[0]
        let applicationSupport = library
            .appendingPathComponent("Application Support")

        var removingDirs = [URL]()
        removingDirs.append(documentsDirectory)

        let bugsnag = applicationSupport
            .appendingPathComponent("com.bugsnag.Bugsnag")
            .appendingPathComponent(bundleIdentifier)
        removingDirs.append(bugsnag)
        let savedApplicationState = library
            .appendingPathComponent("Saved Application State")
            .appendingPathComponent("\(bundleIdentifier).savedState")
        removingDirs.append(savedApplicationState)
        let webKit = library
            .appendingPathComponent("WebKik")
            .appendingPathComponent(bundleIdentifier)
        removingDirs.append(webKit)
        let preference = library
            .appendingPathComponent("Preferences")
            .appendingPathComponent("\(bundleIdentifier).plist")
        removingDirs.append(preference)
        let cookies = library
            .appendingPathComponent("Cookies")
        removingDirs.append(cookies)
        let webImage = library
            .appendingPathComponent("Caches")
            .appendingPathComponent("com.hackemist.SDImageCache")
        removingDirs.append(webImage)
        let webContent = library
            .appendingPathComponent("Caches")
            .appendingPathComponent("com.apple.WebKit.WebContent")
        removingDirs.append(webContent)
        let ourCache = library
            .appendingPathComponent("Caches")
            .appendingPathComponent(bundleIdentifier)
        removingDirs.append(ourCache)
        let digger = library
            .appendingPathComponent("Caches")
            .appendingPathComponent("Digger")
        removingDirs.append(digger)

        let tmp = URL(fileURLWithPath: NSTemporaryDirectory())
        removingDirs.append(tmp.appendingPathComponent(bundleIdentifier))

        for element in removingDirs {
            debugPrint(element)
            try? FileManager.default.removeItem(at: element)
        }

        SPIndicator.present(title: NSLocalizedString("DONE", comment: "Done"),
                            message: nil,
                            preset: .done,
                            haptic: .success,
                            from: .top,
                            completion: nil)
    }

    @objc
    func rebootApplication() {
        InterfaceBridge.removeRecoveryFlag(with: #function, userRequested: true)
        AuxiliaryExecuteWrapper.suspendApplication()
        sleep(1)
        exit(0)
    }
}
