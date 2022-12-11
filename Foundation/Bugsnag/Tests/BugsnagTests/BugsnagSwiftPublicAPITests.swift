//
//  BugsnagSwiftPublicAPITests.swift
//  Tests
//
//  Created by Robin Macharg on 15/05/2020.
//  Copyright © 2020 Bugsnag. All rights reserved.
//

import XCTest

/**
 * Test all public APIs from Swift.  Purely existence tests, no attempt to verify correctness
 */

class FakePlugin: NSObject, BugsnagPlugin {
    func load(_: BugsnagClient) {}
    func unload() {}
}

// MetadataStore conformance - presence of required methods is a test in and of itself
class myMetadata: NSObject, BugsnagMetadataStore, BugsnagClassLevelMetadataStore {
    static func addMetadata(_: [AnyHashable: Any], section _: String) {}
    static func addMetadata(_: Any?, key _: String, section _: String) {}
    static func getMetadata(section _: String) -> NSMutableDictionary? { NSMutableDictionary() }
    static func getMetadata(section _: String, key _: String) -> Any? { nil }
    static func clearMetadata(section _: String) {}
    static func clearMetadata(section _: String, key _: String) {}

    func addMetadata(_: [AnyHashable: Any], section _: String) {}
    func addMetadata(_: Any?, key _: String, section _: String) {}
    func getMetadata(section _: String) -> NSMutableDictionary? { NSMutableDictionary() }
    func getMetadata(section _: String, key _: String) -> Any? { nil }
    func clearMetadata(section _: String) {}
    func clearMetadata(section _: String, key _: String) {}
}

class BugsnagSwiftPublicAPITests: XCTestCase {
    let apiKey = "01234567890123456789012345678901"
    let ex = NSException(name: NSExceptionName("exception"),
                         reason: "myReason",
                         userInfo: nil)
    let err = NSError(domain: "dom", code: 123, userInfo: nil)
    let sessionBlock: BugsnagOnSessionBlock = { _ -> Bool in false }
    let onSendErrorBlock: BugsnagOnSendErrorBlock = { _ -> Bool in false }
    let onBreadcrumbBlock: BugsnagOnBreadcrumbBlock = { _ -> Bool in false }

    func testBugsnagClass() throws {
        Bugsnag.start(withApiKey: apiKey)
        Bugsnag.start(with: BugsnagConfiguration(apiKey))

        let _ = Bugsnag.lastRunInfo?.crashed

        Bugsnag.notify(ex)
        Bugsnag.notify(ex) { _ -> Bool in false }
        Bugsnag.notifyError(err)
        Bugsnag.notifyError(err) { _ -> Bool in false }

        Bugsnag.leaveBreadcrumb(withMessage: "msg")
        Bugsnag.leaveBreadcrumb(forNotificationName: "notif")
        Bugsnag.leaveBreadcrumb("msg", metadata: ["foo": "bar"], type: .error)

        Bugsnag.startSession()
        Bugsnag.pauseSession()
        Bugsnag.resumeSession()

        Bugsnag.setContext("ctx")
        let _ = Bugsnag.context()

        Bugsnag.setUser("me", withEmail: "memail@foo.com", andName: "you")
        let _ = Bugsnag.user()

        let onSession = Bugsnag.addOnSession(block: sessionBlock)
        Bugsnag.addOnSession { (_: BugsnagSession) -> Bool in
            true
        }
        Bugsnag.removeOnSession(onSession)

        let onBreadcrumb = Bugsnag.addOnBreadcrumb(block: onBreadcrumbBlock)
        Bugsnag.addOnBreadcrumb { (_: BugsnagBreadcrumb) -> Bool in
            true
        }
        Bugsnag.removeOnBreadcrumb(onBreadcrumb)
    }

    func testBugsnagConfigurationClass() throws {
        let config = BugsnagConfiguration(apiKey)

        config.apiKey = apiKey
        config.releaseStage = "stage1"
        config.enabledReleaseStages = nil
        config.enabledReleaseStages = ["one", "two", "three"]
        config.redactedKeys = nil
        config.redactedKeys = ["1", 2, 3]
        let re = try! NSRegularExpression(pattern: "test", options: [])
        config.redactedKeys = ["a", "a", "b", re]
        config.context = nil
        config.context = "ctx"
        config.appVersion = nil
        config.appVersion = "vers"
        config.session = URLSession(configuration: URLSessionConfiguration.default)
        #if !os(watchOS)
            config.sendThreads = .always
        #endif

        config.onCrashHandler = nil
        config.onCrashHandler = { _ in }
        let crashHandler: (@convention(c) (UnsafePointer<BSG_KSCrashReportWriter>) -> Void)? = { _ in }
        config.onCrashHandler = crashHandler

        config.autoDetectErrors = true
        config.autoTrackSessions = true
        config.enabledBreadcrumbTypes = .all
        config.bundleVersion = nil
        config.bundleVersion = "bundle"
        config.appType = nil
        config.appType = "appType"
        config.maxBreadcrumbs = 999
        config.persistUser = true

        let errorTypes = BugsnagErrorTypes()
        errorTypes.cppExceptions = true
        #if !os(watchOS)
            errorTypes.ooms = true
            errorTypes.machExceptions = true
            errorTypes.signals = true
        #endif
        errorTypes.unhandledExceptions = true
        errorTypes.unhandledRejections = true
        config.enabledErrorTypes = errorTypes

        config.endpoints = BugsnagEndpointConfiguration()
        config.endpoints = BugsnagEndpointConfiguration(notify: "http://test.com", sessions: "http://test.com")

        config.setUser("user", withEmail: "email", andName: "name")
        let onSession = config.addOnSession(block: sessionBlock)
        config.addOnSession { (_: BugsnagSession) -> Bool in
            true
        }
        config.removeOnSession(onSession)
        config.addOnSendError(block: onSendErrorBlock)
        config.addOnSendError { (_: BugsnagEvent) -> Bool in
            true
        }
        config.removeOnSendError(onSession)
        let onBreadcrumb = config.addOnBreadcrumb(block: onBreadcrumbBlock)
        config.addOnBreadcrumb { (_: BugsnagBreadcrumb) -> Bool in
            true
        }
        config.removeOnBreadcrumb(onBreadcrumb)

        let plugin = FakePlugin()
        config.add(plugin)
    }

    // Also test <BugsnagMetadataStore> behaviour
    func testBugsnagMetadataClass() throws {
        var md = BugsnagMetadata()
        md = BugsnagMetadata(dictionary: ["foo": "bar"])

        md.addMetadata(["key": "secret"], section: "mental")
        md.addMetadata("spock", key: "kirk", section: "enterprise")
        md.getMetadata(section: "mental")
        md.getMetadata(section: "mental", key: "key")
        md.clearMetadata(section: "enterprise")
        md.clearMetadata(section: "enterprise", key: "key")
    }

    func testBugsnagEventClass() throws {
        let event = BugsnagEvent()

        event.context = nil
        event.context = "ctx"
        event.errors = []
        event.errors = [BugsnagError()]
        event.groupingHash = nil
        event.groupingHash = "1234"
        event.breadcrumbs = []
        event.breadcrumbs = [BugsnagBreadcrumb()]
        event.apiKey = apiKey
        _ = event.device
        _ = event.app
        _ = event.unhandled
        event.threads = []
        event.threads = [BugsnagThread()]
        event.originalError = nil
        event.originalError = 123
        event.originalError = BugsnagError()
        _ = event.user
        event.setUser("user", withEmail: "email", andName: "name")
        event.severity = .error
        _ = event.severity
    }

    func testBugsnagAppWithStateClass() throws {
        let app = BugsnagAppWithState()

        app.bundleVersion = nil
        app.bundleVersion = "bundle"
        _ = app.bundleVersion

        app.codeBundleId = nil
        app.codeBundleId = "bundle"
        _ = app.codeBundleId

        app.dsymUuid = nil
        app.dsymUuid = "bundle"
        _ = app.dsymUuid

        app.id = nil
        app.id = "bundle"
        _ = app.id

        app.releaseStage = nil
        app.releaseStage = "bundle"
        _ = app.releaseStage

        app.type = nil
        app.type = "bundle"
        _ = app.type

        app.version = nil
        app.version = "bundle"
        _ = app.version

        // withState

        app.duration = nil
        app.duration = 0
        app.duration = 1.1
        app.duration = -45
        app.duration = NSNumber(booleanLiteral: true)
        _ = app.duration

        app.durationInForeground = nil
        app.durationInForeground = 0
        app.durationInForeground = 1.1
        app.durationInForeground = -45
        app.durationInForeground = NSNumber(booleanLiteral: true)
        _ = app.durationInForeground

        app.inForeground = true
        _ = app.inForeground
    }

    func testBugsnagBreadcrumbClass() throws {
        let breadcrumb = BugsnagBreadcrumb()
        breadcrumb.type = .manual
        breadcrumb.message = "message"
        breadcrumb.metadata = [:]
    }

    func testBugsnagClientClass() throws {
        var client = BugsnagClient()
        let config = BugsnagConfiguration(apiKey)
        client = BugsnagClient(configuration: config)
        client.notify(ex)
        client.notify(ex) { _ -> Bool in false }
        client.notifyError(err)
        client.notifyError(err) { _ -> Bool in false }

        client.leaveBreadcrumb(withMessage: "msg")
        client.leaveBreadcrumb("msg", metadata: [:], type: .manual)
        client.leaveBreadcrumb(forNotificationName: "name")

        client.startSession()
        client.pauseSession()
        client.resumeSession()

        client.context = nil
        client.context = ""
        _ = client.context

        let _ = client.lastRunInfo?.crashed

        client.setUser("me", withEmail: "memail@foo.com", andName: "you")
        let _ = client.user()

        let onSession = client.addOnSession(block: sessionBlock)
        client.addOnSession { (_: BugsnagSession) -> Bool in
            true
        }
        client.removeOnSession(onSession)

        let onBreadcrumb = client.addOnBreadcrumb(block: onBreadcrumbBlock)
        client.addOnBreadcrumb { (_: BugsnagBreadcrumb) -> Bool in
            true
        }
        client.removeOnBreadcrumb(onBreadcrumb)
    }

    func testBugsnagDeviceWithStateClass() throws {
        let device = BugsnagDeviceWithState()

        device.jailbroken = false
        _ = device.jailbroken

        device.id = nil
        device.id = "id"
        _ = device.id

        device.locale = nil
        device.locale = "locale"
        _ = device.locale

        device.manufacturer = nil
        device.manufacturer = "man"
        _ = device.manufacturer
        device.model = nil
        device.model = "model"
        _ = device.model
        device.modelNumber = nil
        device.modelNumber = "model"
        _ = device.modelNumber
        device.osName = nil
        device.osName = "name"
        _ = device.osName
        device.osVersion = nil
        device.osVersion = "version"
        _ = device.osVersion
        device.runtimeVersions = nil
        device.runtimeVersions = [:]
        device.runtimeVersions = ["a": "b"]
        _ = device.runtimeVersions
        device.totalMemory = nil
        device.totalMemory = 1234
        _ = device.totalMemory

        // withState

        device.freeDisk = nil
        device.freeDisk = 0
        device.freeDisk = 1.1
        device.freeDisk = -45
        device.freeDisk = NSNumber(booleanLiteral: true)
        _ = device.freeDisk

        device.freeMemory = nil
        device.freeMemory = 0
        device.freeMemory = 1.1
        device.freeMemory = -45
        device.freeMemory = NSNumber(booleanLiteral: true)
        _ = device.freeMemory

        device.orientation = nil
        device.orientation = "upside your head"
        _ = device.orientation

        device.time = nil
        device.time = Date()
        _ = device.time
    }

    func testBugsnagEndpointConfigurationlass() throws {
        let epc = BugsnagEndpointConfiguration()
        epc.notify = "notify"
        epc.sessions = "sessions"
    }

    // Also error types
    func testBugsnagErrorClass() throws {
        let e = BugsnagError()
        e.errorClass = nil
        e.errorClass = "class"
        _ = e.errorClass
        e.errorMessage = nil
        e.errorMessage = "msg"
        _ = e.errorMessage

        e.type = .cocoa
        e.type = .c
        e.type = .reactNativeJs
    }

    func testBugsnagSessionClass() throws {
        let session = BugsnagSession()
        session.id = "id"
        _ = session.id
        session.startedAt = Date()
        _ = session.startedAt
        _ = session.app
        _ = session.device
        _ = session.user
        session.setUser("user", withEmail: "email", andName: "name")
    }

    func testBugsnagStackframeClass() throws {
        let sf = BugsnagStackframe()
        sf.method = nil
        sf.method = "method"
        _ = sf.method
        sf.machoFile = nil
        sf.machoFile = "file"
        _ = sf.machoFile
        sf.machoUuid = nil
        sf.machoUuid = "uuid"
        _ = sf.machoUuid
        sf.frameAddress = nil
        sf.frameAddress = 123
        _ = sf.frameAddress
        sf.machoVmAddress = nil
        sf.machoVmAddress = 123
        _ = sf.machoVmAddress
        sf.symbolAddress = nil
        sf.symbolAddress = 123
        _ = sf.symbolAddress
        sf.machoLoadAddress = nil
        sf.machoLoadAddress = 123
        _ = sf.machoLoadAddress
        sf.isPc = true
        _ = sf.isPc
        sf.isLr = true
        _ = sf.isLr
    }

    func testBugsnagThreadClass() throws {
        let thread = BugsnagThread()
        thread.id = nil
        thread.id = "id"
        _ = thread.id
        thread.name = nil
        thread.name = "name"
        _ = thread.name
        thread.type = .cocoa
        _ = thread.errorReportingThread
        _ = thread.stacktrace
    }

    func testBugsnagUserClass() throws {
        let user = BugsnagUser()
        _ = user.id
        _ = user.email
        _ = user.name
    }
}
