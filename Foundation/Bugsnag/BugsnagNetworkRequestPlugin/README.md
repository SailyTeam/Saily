# Network request monitoring plugin for the Bugsnag exception reporter

[![iOS Documentation](https://img.shields.io/badge/ios_documentation-latest-blue.svg)](https://docs.bugsnag.com/platforms/ios/customizing-breadcrumbs/#capturing-network-requests)
[![tvOS Documentation](https://img.shields.io/badge/tvos_documentation-latest-blue.svg)](https://docs.bugsnag.com/platforms/tvos/customizing-breadcrumbs/#capturing-network-requests)
[![macOS Documentation](https://img.shields.io/badge/macos_documentation-latest-blue.svg)](https://docs.bugsnag.com/platforms/macos/customizing-breadcrumbs/#capturing-network-requests)

The Bugsnag crash reporter for Cocoa library automatically detects crashes and fatal signals in your iOS 9.0+, macOS 10.11+ and tvOS 9.2+ applications, collecting diagnostic information and immediately notifying your development team, helping you to understand and resolve issues as fast as possible. Learn more about [iOS crash reporting with Bugsnag](https://www.bugsnag.com/platforms/ios-crash-reporting/).

**BugsnagNetworkRequestPlugin** integrates with Bugsnag to monitor network requests made via `NSURLSession` and attaches breadcrumbs to help diagnose the events leading to an error.

To capture network breadcrumbs, install the `BugsnagNetworkRequestPlugin` plugin and then [enable it in your BugsnagConfiguration](https://docs.bugsnag.com/platforms/ios/customizing-breadcrumbs/#enabling-the-plugin).

BugsnagNetworkRequestPlugin supports iOS 10.0+, macOS 10.12+ and tvOS 10.0+.
