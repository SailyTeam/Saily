//
//  File.swift
//
//
//  Created by Abdul Chathil on 12/30/20.
//
#if canImport(SwiftUI)
    import SwiftUI
    public extension Image {
        init(fluent: FluentIcon) {
            self.init(fluent.resourceString, bundle: .module)
        }
    }
#endif

#if canImport(UIKit)
    import UIKit
    public extension UIImage {
        static func fluent(_ icon: FluentIcon) -> UIImage {
            UIImage(named: icon.resourceString, in: .module, with: nil)?
                .withRenderingMode(.alwaysTemplate)
                ?? UIImage()
        }
    }
#endif

#if canImport(AppKit)
    #if targetEnvironment(macCatalyst)
    // Use UIKit above instead.
    #else
        import AppKit
        public extension NSImage {
            static func fluent(_ icon: FluentIcon) -> NSImage {
                Bundle.module.image(forResource: icon.resourceString) ?? NSImage()
            }
        }
    #endif
#endif
