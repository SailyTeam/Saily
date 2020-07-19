//
//  RepoPaymentManager.swift
//  Protein
//
//  Created by Lakr Aream on 2020/7/18.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import UIKit
import Security
import AuthenticationServices

class RepoPaymentManager: NSObject {
    
    static let shared = RepoPaymentManager("2474C8E2-7CA2-45D0-8B6D-AF84DF4263E8")
    
    required init(_ token: String = "") {
        assert(token == "2474C8E2-7CA2-45D0-8B6D-AF84DF4263E8", "[RepoPaymentManager] Does not allowed to be used with customized instance")
    }
    
    func queryEndpointAndSaveToRam(urlAsKey: String, fromUpdate: Bool = false) -> String? {
        if !fromUpdate {
            for item in RepoManager.shared.repos where item.url.urlString == urlAsKey {
                return item.paymentInfo["endpoint"]
            }
            return nil
        }
        guard let url = URL(string: urlAsKey) else {
            return nil
        }
        let request = URLRequest(url: url.absoluteURL.appendingPathComponent("payment_endpoint"), cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: TimeInterval(ConfigManager.shared.Networking.maxWaitTimeToDownloadRepo))
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        let sem = DispatchSemaphore(value: 0)
        var get: String? = nil
        let task = session.dataTask(with: request) { (data, _, err) in
            defer { sem.signal() }
            if err == nil, let data = data, let str = String(data: data, encoding: .utf8) {
                var clean = str
                clean.cleanAndReplaceLineBreaker()
                clean.removeNewLine()
                clean.removeSpaces()
                while clean.hasSuffix("/") {
                    clean.removeLast()
                }
                get = clean
            }
            
        }
        task.resume()
        let _ = sem.wait(wallTimeout: .now() + Double(ConfigManager.shared.Networking.maxWaitTimeToDownloadRepo))
        if let get = get,
            let test = URL(string: get), test.absoluteString.count < 512 {
            Tools.rprint("[RepoPaymentManager] Detected payment endpoint at: " + test.urlString + " for: " + urlAsKey + " 💰")
            return get
        }
        return nil
    }
    
    func reportPaidReposWithItsEndpoint() -> [(String, String)] {
        var ret = [String : String]()
        for item in RepoManager.shared.repos where item.paymentInfo["endpoint"] != nil {
            ret[item.url.urlString] = item.paymentInfo["endpoint"]!
        }
        var sortObject = [(String, String)]()
        let sortedKeys = ret.keys.sorted()
        for item in sortedKeys {
            if let value = ret[item] {
                sortObject.append((item, value))
            }
        }
        return sortObject
    }
    
    func startUserAuthenticate(inWindow: UIWindow, inAlertContainer: UIViewController?,
                               andRepoUrlAsKey: String, withEndpoint: String?, whenCompletion: @escaping () -> ()) {
        guard let endpoint = withEndpoint,
            let udid = ConfigManager.shared.obtainRealDeviceID() else {
            whenCompletion()
            return
        }
        if obtainUserSignInfomation(forRepoUrlAsKey: andRepoUrlAsKey) != nil {
            Tools.rprint("[RepoPaymentManager] User already signed in: " + andRepoUrlAsKey)
            whenCompletion()
            return
        }

        if ConfigManager.shared.CydiaConfig.mess {
            let alert = UIAlertController(title: "Error".localized(), message: "RandomDeviceInfoMustBeTurnOff".localized(), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss".localized(), style: .default, handler: nil))
            inAlertContainer?.present(alert, animated: true, completion: nil)
            return
        }
        
        guard var authUrl = URL(string: endpoint)?.appendingPathComponent("authenticate") else {
            whenCompletion()
            return
        }
        authUrl = authUrl.appending("udid", value: udid)
        authUrl = authUrl.appending("model", value: ConfigManager.shared.CydiaConfig.machine)
        
        Tools.rprint("[RepoPaymentManager] Requesting auth: " + authUrl.absoluteString)
        
        // Starting authenticate session
        
        let item = ASWebAuthenticationSessionWindowProvider(window: inWindow)
        let session = ASWebAuthenticationSession(url: authUrl, callbackURLScheme: "sileo") { (url, err) in
            
            defer { whenCompletion() }
            
            let _ = item // avoid dealloc
            
            guard let url = url, err == nil else {
                let alert = UIAlertController(title: "Error".localized(), message: "LoginFailedLeadingHint".localized() + (err?.localizedDescription ?? "LoginFailedTrailingHint".localized()), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Dismiss".localized(), style: .default, handler: nil))
                inAlertContainer?.present(alert, animated: true, completion: nil)
                return
            }
            
            guard let param = url.queryParameters,
                let token = param["token"],
                let secert = param["payment_secret"] else {
                    let alert = UIAlertController(title: "Error".localized(), message: "LoginFailedLeadingHint".localized() + (err?.localizedDescription ?? "LoginFailedTrailingHint".localized()), preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Dismiss".localized(), style: .default, handler: nil))
                    inAlertContainer?.present(alert, animated: true, completion: nil)
                    return
            }
            
            Tools.rprint("[RepoPaymentManager] User authentication completed with token: " + token)
            self.recordUserInfomation(forRepoUrlAsKey: andRepoUrlAsKey, token: token, scecrt: secert)
            
        }
        session.presentationContextProvider = item
        session.start()
        
    }
    
    func recordUserInfomation(forRepoUrlAsKey: String, token: String, scecrt: String) {
        let _ = KeyChain.save(key: String.sha256From(data: (forRepoUrlAsKey + "token").data), data: token.data)
        let _ = KeyChain.save(key: String.sha256From(data: (forRepoUrlAsKey + "secert").data), data: scecrt.data)
    }
    
    struct UserLoginReport {
        let repo: String
        let token: String
        let secert: String
    }
    
    func obtainUserSignInfomation(forRepoUrlAsKey: String?) -> UserLoginReport? {
        
        guard let forRepoUrlAsKey = forRepoUrlAsKey else {
            return nil
        }
        
        let tokenKey = String.sha256From(data: (forRepoUrlAsKey + "token").data)
        let sceKey = String.sha256From(data: (forRepoUrlAsKey + "secert").data)
        
        if let tokenRaw = KeyChain.load(key: tokenKey), let token = String(data: tokenRaw, encoding: .utf8),
            let sceRaw = KeyChain.load(key: sceKey), let secert = String(data: sceRaw, encoding: .utf8) {
            return UserLoginReport(repo: forRepoUrlAsKey, token: token, secert: secert)
        }
        
        return nil
    }
    
    func deleteSignInRecord(forRepoUrlAsKey: String?) {
        if let key = forRepoUrlAsKey {
            if let ret = obtainUserSignInfomation(forRepoUrlAsKey: key) {
                let token = ret.token
                if let endPoint = queryEndpointAndSaveToRam(urlAsKey: key), let url = URL(string: endPoint)?.appendingPathComponent("sign_out") {
                    var payload: [String : String] = [:]
                    payload["token"] = token
                    payload["udid"] = ConfigManager.shared.obtainRealDeviceID() // otherwise it will return remote failed
                    payload["device"] = ConfigManager.shared.CydiaConfig.machine
                    if let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: .fragmentsAllowed) {
                        DispatchQueue.global(qos: .background).async {
                            var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: TimeInterval(ConfigManager.shared.Networking.maxWaitTimeToDownloadRepo))
                            request.httpMethod = "POST"
                            request.httpBody = jsonData
                            let session = URLSession(configuration: .default)
                            let task = session.dataTask(with: request) { (data, resp, err) in
                                if let data = data, let retStr = String(data: data, encoding: .utf8) {
                                    Tools.rprint("[RepoPaymentManager] Sign out returned: " + retStr + " at: " + (forRepoUrlAsKey ?? "?"))
                                }
                            }
                            task.resume()
                        }
                    }
                }
            }
            let tokenKey = String.sha256From(data: (key + "token").data)
            let sceKey = String.sha256From(data: (key + "secert").data)
            KeyChain.delete(key: tokenKey)
            KeyChain.delete(key: sceKey)
        }
    }
    
    struct UserInfo {
        let item: [String]
        let name: String?
        let email: String?
    }
    
    func obtainUserInfo(withUrlAsKey: String?, completion: @escaping (UserInfo?) -> ()) {
        guard let url = withUrlAsKey,
            let endpointRaw = queryEndpointAndSaveToRam(urlAsKey: url),
            let endpoint = URL(string: endpointRaw),
            let report = obtainUserSignInfomation(forRepoUrlAsKey: url) else {
                completion(nil)
                return
        }
        
        var request = URLRequest(url: endpoint.appendingPathComponent("user_info"), cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: Double(ConfigManager.shared.Networking.maxWaitTimeToDownloadRepo))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField:"Accept")
        request.setValue("application/json", forHTTPHeaderField:"Content-Type")
        var payload: [String : String] = [:]
        payload["token"] = report.token
        payload["udid"] = ConfigManager.shared.obtainRealDeviceID() // otherwise it will return remote failed
        payload["device"] = ConfigManager.shared.CydiaConfig.machine
        let json = (try? JSONSerialization.data(withJSONObject: payload, options: .fragmentsAllowed)) ?? Data()
        request.httpBody = json
        
        let session = URLSession(configuration: .default)
        let task = session.dataTask(with: request) { (data, resp, err) in
            var userInfoRet: UserInfo?
            if let data = data, err == nil,
                let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String : Any] {
                let user = json["user"] as? [String : Any] ?? [:]
                userInfoRet = UserInfo(item: json["items"] as? [String] ?? [], name: user["name"] as? String, email: user["email"] as? String)
                completion(userInfoRet)
                return
            }
            completion(nil)
        }
        task.resume()
    }
    
    struct PackageInfo {
        let price: String?
        let purchased: Bool?
        let available: Bool?
//        let error: String?
//        let recovery_url: String?
//        let invalidate: Any
    }
    
    func obtainPackageInfo(withUrlAsKey: String, withPkgIdentity: String, completion: @escaping (PackageInfo?) -> ()) {
        guard let endpointRaw = queryEndpointAndSaveToRam(urlAsKey: withUrlAsKey),
            let url = URL(string: endpointRaw + "/package/" + withPkgIdentity + "/info"),
            let userInfo = obtainUserSignInfomation(forRepoUrlAsKey: withUrlAsKey) else {
                completion(nil)
            return
        }
        
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: Double(ConfigManager.shared.Networking.maxWaitTimeToDownloadRepo))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField:"Accept")
        request.setValue("application/json", forHTTPHeaderField:"Content-Type")
        var payload: [String : String] = [:]
        payload["token"] = userInfo.token
        payload["udid"] = ConfigManager.shared.obtainRealDeviceID() // otherwise it will return remote failed
        payload["device"] = ConfigManager.shared.CydiaConfig.machine
        let json = (try? JSONSerialization.data(withJSONObject: payload, options: .fragmentsAllowed)) ?? Data()
        request.httpBody = json
        
        let session = URLSession(configuration: .default)
        let task = session.dataTask(with: request) { (data, resp, err) in
            if let data = data, err == nil,
                let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String : Any] {
                let info = PackageInfo(price: json["price"] as? String, purchased: json["purchased"] as? Bool, available: json["available"] as? Bool)
                completion(info)
                return
            }
            completion(nil)
        }
        task.resume()
    }
    
    enum PurchaseResult {
        case succeed
        case action
        case fails
    }
    
    func initPurchase(withUrlAsKey: String, withPkgIdentity: String, withWindow: UIWindow) -> PurchaseResult {
        guard let endpointRaw = queryEndpointAndSaveToRam(urlAsKey: withUrlAsKey),
            let url = URL(string: endpointRaw + "/package/" + withPkgIdentity + "/purchase"),
            let userInfo = obtainUserSignInfomation(forRepoUrlAsKey: withUrlAsKey) else {
                return .fails
        }
        
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: Double(ConfigManager.shared.Networking.maxWaitTimeToDownloadRepo))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField:"Accept")
        request.setValue("application/json", forHTTPHeaderField:"Content-Type")
        var payload: [String : String] = [:]
        payload["token"] = userInfo.token
        payload["udid"] = ConfigManager.shared.obtainRealDeviceID() // otherwise it will return remote failed
        payload["device"] = ConfigManager.shared.CydiaConfig.machine
        payload["payment_secret"] = userInfo.secert
        let json = (try? JSONSerialization.data(withJSONObject: payload, options: .fragmentsAllowed)) ?? Data()
        request.httpBody = json
        
        let sem = DispatchSemaphore(value: 0)
        var jsonGet: [String : Any]?
        let session = URLSession(configuration: .default)
        let task = session.dataTask(with: request) { (data, resp, err) in
            defer { sem.signal() }
            if let data = data, err == nil,
                let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String : Any] {
                jsonGet = json
            }
        }
        task.resume()
        let _ = sem.wait(timeout: .now() + Double(ConfigManager.shared.Networking.maxWaitTimeToDownloadRepo))
        if let jsonGet = jsonGet, let status = jsonGet["status"] as? Int {
            if status == 0 {
                return .succeed
            }
            if let urlRaw = jsonGet["url"] as? String,
                let url = URL(string: urlRaw) {
                DispatchQueue.main.async {
                    let foo = ASWebAuthenticationSessionWindowProvider(window: withWindow)
                    let session = ASWebAuthenticationSession(url: url, callbackURLScheme: "sileo") { (url, error) in
                        let _ = foo
                    }
                    session.presentationContextProvider = foo
                    session.start()
                }
                return .action
            }
        }
        return .fails
    }
    
    func queryDownloadLink(withPackage: PackageStruct) -> String? {
        
        guard let withUrlAsKey = withPackage.fromRepoUrlRef,
            let endpointRaw = queryEndpointAndSaveToRam(urlAsKey: withUrlAsKey),
            let url = URL(string: endpointRaw + "/package/" + withPackage.identity + "/authorize_download"),
            let userInfo = obtainUserSignInfomation(forRepoUrlAsKey: withUrlAsKey) else {
                return nil
        }
        
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: Double(ConfigManager.shared.Networking.maxWaitTimeToDownloadRepo))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField:"Accept")
        request.setValue("application/json", forHTTPHeaderField:"Content-Type")
        var payload: [String : String] = [:]
        payload["token"] = userInfo.token
        payload["udid"] = ConfigManager.shared.obtainRealDeviceID() // otherwise it will return remote failed
        payload["device"] = ConfigManager.shared.CydiaConfig.machine
        payload["version"] = withPackage.newestVersion()
        payload["repo"] = withPackage.fromRepoUrlRef
        payload["payment_secret"] = userInfo.secert
        let json = (try? JSONSerialization.data(withJSONObject: payload, options: .fragmentsAllowed)) ?? Data()
        request.httpBody = json
        
        let sem = DispatchSemaphore(value: 0)
        var jsonGet: [String : Any]?
        let session = URLSession(configuration: .default)
        let task = session.dataTask(with: request) { (data, resp, err) in
            defer { sem.signal() }
            if let data = data, err == nil,
                let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String : Any] {
                jsonGet = json
            }
        }
        task.resume()
        let _ = sem.wait(timeout: .now() + Double(ConfigManager.shared.Networking.maxWaitTimeToDownloadRepo))
        if let jsonGet = jsonGet, let url = jsonGet["url"] as? String {
            return url
        }
        return nil
    }
    
}

fileprivate class ASWebAuthenticationSessionWindowProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    
    private let windowCache: UIWindow
    required init(window: UIWindow) {
        windowCache = window
        super.init()
    }
    
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return windowCache
    }
    
}

fileprivate class KeyChain {

    class func save(key: String, data: Data) -> OSStatus {
        let query = [
            kSecClass as String       : kSecClassGenericPassword as String,
            kSecAttrAccount as String : key,
            kSecValueData as String   : data ] as [String : Any]

        SecItemDelete(query as CFDictionary)

        return SecItemAdd(query as CFDictionary, nil)
    }
    
    class func delete(key: String) {
        let query = [
            kSecClass as String       : kSecClassGenericPassword as String,
            kSecAttrAccount as String : key] as [String : Any]
        SecItemDelete(query as CFDictionary)
    }

    class func load(key: String) -> Data? {
        let query = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrAccount as String : key,
            kSecReturnData as String  : kCFBooleanTrue!,
            kSecMatchLimit as String  : kSecMatchLimitOne ] as [String : Any]

        var dataTypeRef: AnyObject? = nil

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
