//
//  PaymentManager.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/25.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import AptRepository
import AuthenticationServices
import Dog
import Security
import SPIndicator
import UIKit

class PaymentManager {
    static let shared = PaymentManager()

    private init() {}

    // MARK: - STRUCT

    struct UserTokenInfo {
        let repo: URL
        let token: String
        let secert: String
    }

    struct UserAccount {
        let item: [String]
        let name: String?
        let email: String?
    }

    struct PackageInfo {
        let price: String?
        let purchased: Bool?
        let available: Bool?
    }

    enum PurchaseResult {
        case succeed
        case action
        case failed
    }

    // MARK: - FUNCTION

    func postNotification() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .RepositoryPaymenChanged, object: nil)
        }
    }

    func startUserAuthenticate(window: UIWindow,
                               controller: UIViewController?,
                               repoUrl: URL,
                               completionCallback: @escaping () -> Void)
    {
        guard let repo = RepositoryCenter
            .default
            .obtainImmutableRepository(withUrl: repoUrl),
            let endpoint = repo.endpoint
        else {
            completionCallback()
            return
        }
        if obtainStoredTokenInfomation(for: repo) != nil {
            Dog.shared.join(self, "user already signed in \(repo.url.absoluteString)")
            completionCallback()
            return
        }
        if !DeviceInfo.current.useRealDeviceInfo {
            let alert = UIAlertController(title: NSLocalizedString("ERROR", comment: "Error"),
                                          message: NSLocalizedString("CANNOT_SIGNIN_PAYMENT_WITHOUT_REAL_DEVICE_ID", comment: "Cannot sign in without using real device identities, check your settings."),
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("DISMISS", comment: "Dismiss"),
                                          style: .default,
                                          handler: nil))
            controller?.present(alert, animated: true, completion: nil)
            completionCallback()
            return
        }

        let authUrl = endpoint
            .appendingPathComponent("authenticate")
            // follow the order in a strict way
            .appendingQueryParameters(["udid": DeviceInfo.current.udid])
            .appendingQueryParameters(["model": DeviceInfo.current.machine])

        let item = ASWebAuthenticationSessionWindowProvider(window: window)
        let session = ASWebAuthenticationSession(url: authUrl, callbackURLScheme: "sileo") { url, err in
            defer { completionCallback() }
            _ = item // avoid dealloc
            guard let url = url, err == nil else {
                SPIndicator.present(title: NSLocalizedString("ERROR", comment: "Error"),
                                    message: NSLocalizedString("SIGNIN_FAILED", comment: "Signin Failed"),
                                    preset: .error,
                                    haptic: .error,
                                    from: .top,
                                    completion: nil)
                return
            }

            guard let param = url.queryParameters,
                  let token = param["token"],
                  let secert = param["payment_secret"]
            else {
                let alert = UIAlertController(title: NSLocalizedString("ERROR", comment: "Error"),
                                              message: NSLocalizedString("BROKEN_RESOURCE", comment: "Broken Resource"),
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("DISMISS", comment: "Dismiss"),
                                              style: .default,
                                              handler: nil))
                controller?.present(alert, animated: true, completion: nil)
                return
            }
            Dog.shared.join(self, "authentication completed with token \(token.count) long for \(repo.url.absoluteString)")
            self.recordUserInfomation(for: repo, token: token, secret: secert)
        }
        session.presentationContextProvider = item
        session.start()
    }

    func recordUserInfomation(for repo: Repository, token: String, secret: String) {
        guard let tokenData = token.data(using: .utf8),
              let secertData = secret.data(using: .utf8)
        else {
            Dog.shared.join(self, "failed to compile token/scecrt data", level: .error)
            return
        }
        let tokenKCKey = "KeyChain.[\(repo.url.absoluteString)].token"
        let secertKCKey = "KeyChain.[\(repo.url.absoluteString)].secert"
        _ = KeyChain.save(key: tokenKCKey, data: tokenData)
        _ = KeyChain.save(key: secertKCKey, data: secertData)
        postNotification()
    }

    func obtainStoredTokenInfomation(for repo: Repository) -> UserTokenInfo? {
        let tokenKCKey = "KeyChain.[\(repo.url.absoluteString)].token"
        let secertKCKey = "KeyChain.[\(repo.url.absoluteString)].secert"

        if let tokenRaw = KeyChain.load(key: tokenKCKey),
           let token = String(data: tokenRaw, encoding: .utf8),
           let sceRaw = KeyChain.load(key: secertKCKey),
           let secert = String(data: sceRaw, encoding: .utf8)
        {
            return .init(repo: repo.url, token: token, secert: secert)
        }
        return nil
    }

    func deleteSignInRecord(for repoUrl: URL) {
        guard let repo = RepositoryCenter
            .default
            .obtainImmutableRepository(withUrl: repoUrl)
        else {
            return
        }
        guard let info = obtainStoredTokenInfomation(for: repo) else { return }
        let tokenKCKey = "KeyChain.[\(repo.url.absoluteString)].token"
        let secertKCKey = "KeyChain.[\(repo.url.absoluteString)].secert"
        KeyChain.delete(key: tokenKCKey)
        KeyChain.delete(key: secertKCKey)
        postNotification()
        guard let endpoint = repo.endpoint?.appendingPathComponent("sign_out") else {
            return
        }
        var payload: [String: String] = [:]
        payload["token"] = info.token
        payload["udid"] = DeviceInfo.current.udid // otherwise it will return remote failed
        payload["device"] = DeviceInfo.current.machine
        guard let jsonData = try? JSONSerialization
            .data(withJSONObject: payload, options: .fragmentsAllowed)
        else {
            return
        }
        var request = URLRequest(url: endpoint, timeoutInterval: 10)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        URLSession
            .shared
            .dataTask(with: request) { data, _, _ in
                if let data = data, let str = String(data: data, encoding: .utf8) {
                    Dog.shared.join(self, "signing out on \(repo.url.absoluteString) replied with \(str)")
                }
            }
            .resume()
    }

    func obtainUserAccountInfo(for repo: URL, completion: @escaping (UserAccount?) -> Void) {
        guard let repo = RepositoryCenter
            .default
            .obtainImmutableRepository(withUrl: repo),
            let endpoint = repo.endpoint,
            let userInfo = obtainStoredTokenInfomation(for: repo)
        else {
            return
        }

        var request = URLRequest(url: endpoint.appendingPathComponent("user_info"), timeoutInterval: 10)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        var payload: [String: String] = [:]
        payload["token"] = userInfo.token
        payload["udid"] = DeviceInfo.current.udid // otherwise it will return remote failed
        payload["device"] = DeviceInfo.current.machine
        let json = (try? JSONSerialization.data(withJSONObject: payload, options: .fragmentsAllowed)) ?? Data()
        request.httpBody = json

        URLSession
            .shared
            .dataTask(with: request) { data, _, _ in
                var account: UserAccount?
                defer { completion(account) }
                if let data = data,
                   let json = try? JSONSerialization
                   .jsonObject(with: data, options: .allowFragments) as? [String: Any]
                {
                    let user = json["user"] as? [String: Any] ?? [:]
                    account = UserAccount(item: json["items"] as? [String] ?? [],
                                          name: user["name"] as? String,
                                          email: user["email"] as? String)
                }
            }
            .resume()
    }

    func obtainPackageInfo(for repo: URL,
                           withPackageIdentity identity: String,
                           completion: @escaping (PackageInfo?) -> Void)
    {
        guard let repo = RepositoryCenter
            .default
            .obtainImmutableRepository(withUrl: repo),
            let endpoint = repo
            .endpoint?
            .appendingPathComponent("package")
            .appendingPathComponent(identity)
            .appendingPathComponent("info"),
            let userInfo = obtainStoredTokenInfomation(for: repo)
        else {
            return
        }

        var request = URLRequest(url: endpoint, timeoutInterval: 10)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        var payload: [String: String] = [:]
        payload["token"] = userInfo.token
        payload["udid"] = DeviceInfo.current.udid // otherwise it will return remote failed
        payload["device"] = DeviceInfo.current.machine
        let json = (try? JSONSerialization.data(withJSONObject: payload, options: .fragmentsAllowed)) ?? Data()
        request.httpBody = json

        URLSession
            .shared
            .dataTask(with: request) { data, _, _ in
                var info: PackageInfo?
                defer { completion(info) }
                if let data = data,
                   let json = try? JSONSerialization
                   .jsonObject(with: data, options: .allowFragments) as? [String: Any]
                {
                    info = PackageInfo(price: json["price"] as? String,
                                       purchased: json["purchased"] as? Bool,
                                       available: json["available"] as? Bool)
                    completion(info)
                }
            }
            .resume()
    }

    func initPurchaseAndWait(for repo: URL,
                             withPackageIdentity identity: String,
                             window: UIWindow)
        -> PurchaseResult
    {
        guard let repo = RepositoryCenter
            .default
            .obtainImmutableRepository(withUrl: repo),
            let endpoint = repo
            .endpoint?
            .appendingPathComponent("package")
            .appendingPathComponent(identity)
            .appendingPathComponent("purchase"),
            let userInfo = obtainStoredTokenInfomation(for: repo)
        else {
            return .failed
        }

        var request = URLRequest(url: endpoint, timeoutInterval: 10)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        var payload: [String: String] = [:]
        payload["token"] = userInfo.token
        payload["udid"] = DeviceInfo.current.udid // otherwise it will return remote failed
        payload["device"] = DeviceInfo.current.machine
        payload["payment_secret"] = userInfo.secert
        let payloadJson = (try? JSONSerialization.data(withJSONObject: payload, options: .fragmentsAllowed)) ?? Data()
        request.httpBody = payloadJson

        let sem = DispatchSemaphore(value: 0)
        var jsonBuilder: [String: Any]?
        URLSession
            .shared
            .dataTask(with: request) { data, _, _ in
                defer { sem.signal() }
                if let data = data,
                   let read = try? JSONSerialization
                   .jsonObject(with: data, options: .allowFragments) as? [String: Any]
                {
                    jsonBuilder = read
                }
            }
            .resume()
        _ = sem.wait(timeout: .now() + 10)
        guard let json = jsonBuilder else {
            return .failed
        }
        guard let status = json["status"] as? Int else {
            return .failed
        }
        if status == 0 {
            return .succeed
        }
        if let action = json["url"] as? String,
           let url = URL(string: action)
        {
            DispatchQueue.main.async {
                let foo = ASWebAuthenticationSessionWindowProvider(window: window)
                let session = ASWebAuthenticationSession(url: url, callbackURLScheme: "sileo") { _, _ in
                    _ = foo
                }
                session.presentationContextProvider = foo
                session.start()
            }
            return .action
        }
        return .failed
    }

    func queryDownloadLinkAndWait(withPackage package: Package) -> URL? {
        guard let represent = package.repoRef,
              let repo = RepositoryCenter
              .default
              .obtainImmutableRepository(withUrl: represent),
              let endpoint = repo
              .endpoint?
              .appendingPathComponent("package")
              .appendingPathComponent(package.identity)
              .appendingPathComponent("authorize_download"),
              let userInfo = obtainStoredTokenInfomation(for: repo)
        else {
            return nil
        }

        var request = URLRequest(url: endpoint, timeoutInterval: 10)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        var payload: [String: String] = [:]
        payload["token"] = userInfo.token
        payload["udid"] = DeviceInfo.current.udid // otherwise it will return remote failed
        payload["device"] = DeviceInfo.current.machine
        payload["version"] = package.latestVersion
        payload["repo"] = package.repoRef?.absoluteString ?? ""
        payload["payment_secret"] = userInfo.secert
        let payloadJson = (try? JSONSerialization.data(withJSONObject: payload, options: .fragmentsAllowed)) ?? Data()
        request.httpBody = payloadJson

        let sem = DispatchSemaphore(value: 0)
        var jsonBuilder: [String: Any]?
        URLSession
            .shared
            .dataTask(with: request) { data, _, _ in
                defer { sem.signal() }
                if let data = data,
                   let read = try? JSONSerialization
                   .jsonObject(with: data, options: .allowFragments) as? [String: Any]
                {
                    jsonBuilder = read
                }
            }
            .resume()
        _ = sem.wait(timeout: .now() + 10)
        guard let json = jsonBuilder,
              let value = json["url"] as? String,
              let url = URL(string: value)
        else { return nil }
        return url
    }
}

// MARK: - HELPER

private class ASWebAuthenticationSessionWindowProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    private let windowCache: UIWindow
    required init(window: UIWindow) {
        windowCache = window
        super.init()
    }

    func presentationAnchor(for _: ASWebAuthenticationSession) -> ASPresentationAnchor {
        windowCache
    }
}

private class KeyChain {
    class func save(key: String, data: Data) -> OSStatus {
        let query = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
        ] as [String: Any]

        SecItemDelete(query as CFDictionary)

        return SecItemAdd(query as CFDictionary, nil)
    }

    class func delete(key: String) {
        let query = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrAccount as String: key,
        ] as [String: Any]
        SecItemDelete(query as CFDictionary)
    }

    class func load(key: String) -> Data? {
        let query = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ] as [String: Any]

        var dataTypeRef: AnyObject?

        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == noErr {
            return dataTypeRef as! Data?
        } else {
            return nil
        }
    }

    class func createUniqueID() -> String {
        let uuid: CFUUID = CFUUIDCreate(nil)
        let cfStr: CFString = CFUUIDCreateString(nil, uuid)

        let swiftString: String = cfStr as String
        return swiftString
    }
}
