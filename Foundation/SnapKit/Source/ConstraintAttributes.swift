//
//  SnapKit
//
//  Copyright (c) 2011-Present SnapKit Team - https://github.com/SnapKit
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#if os(iOS) || os(tvOS)
    import UIKit
#else
    import AppKit
#endif

internal struct ConstraintAttributes: OptionSet, ExpressibleByIntegerLiteral {
    typealias IntegerLiteralType = UInt

    internal init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    internal init(_ rawValue: UInt) {
        self.init(rawValue: rawValue)
    }

    internal init(nilLiteral _: ()) {
        rawValue = 0
    }

    internal init(integerLiteral rawValue: IntegerLiteralType) {
        self.init(rawValue: rawValue)
    }

    internal private(set) var rawValue: UInt
    internal static var allZeros: ConstraintAttributes { 0 }
    internal static func convertFromNilLiteral() -> ConstraintAttributes { 0 }
    internal var boolValue: Bool { rawValue != 0 }

    internal func toRaw() -> UInt { rawValue }
    internal static func fromRaw(_ raw: UInt) -> ConstraintAttributes? { self.init(raw) }
    internal static func fromMask(_ raw: UInt) -> ConstraintAttributes { self.init(raw) }

    // normal

    internal static var none: ConstraintAttributes { 0 }
    internal static var left: ConstraintAttributes { 1 }
    internal static var top: ConstraintAttributes { 2 }
    internal static var right: ConstraintAttributes { 4 }
    internal static var bottom: ConstraintAttributes { 8 }
    internal static var leading: ConstraintAttributes { 16 }
    internal static var trailing: ConstraintAttributes { 32 }
    internal static var width: ConstraintAttributes { 64 }
    internal static var height: ConstraintAttributes { 128 }
    internal static var centerX: ConstraintAttributes { 256 }
    internal static var centerY: ConstraintAttributes { 512 }
    internal static var lastBaseline: ConstraintAttributes { 1024 }

    @available(iOS 8.0, OSX 10.11, *)
    internal static var firstBaseline: ConstraintAttributes { 2048 }

    @available(iOS 8.0, *)
    internal static var leftMargin: ConstraintAttributes { 4096 }

    @available(iOS 8.0, *)
    internal static var rightMargin: ConstraintAttributes { 8192 }

    @available(iOS 8.0, *)
    internal static var topMargin: ConstraintAttributes { 16384 }

    @available(iOS 8.0, *)
    internal static var bottomMargin: ConstraintAttributes { 32768 }

    @available(iOS 8.0, *)
    internal static var leadingMargin: ConstraintAttributes { 65536 }

    @available(iOS 8.0, *)
    internal static var trailingMargin: ConstraintAttributes { 131_072 }

    @available(iOS 8.0, *)
    internal static var centerXWithinMargins: ConstraintAttributes { 262_144 }

    @available(iOS 8.0, *)
    internal static var centerYWithinMargins: ConstraintAttributes { 524_288 }

    // aggregates

    internal static var edges: ConstraintAttributes { 15 }
    internal static var directionalEdges: ConstraintAttributes { 58 }
    internal static var size: ConstraintAttributes { 192 }
    internal static var center: ConstraintAttributes { 768 }

    @available(iOS 8.0, *)
    internal static var margins: ConstraintAttributes { 61440 }

    @available(iOS 8.0, *)
    internal static var directionalMargins: ConstraintAttributes { 245_760 }

    @available(iOS 8.0, *)
    internal static var centerWithinMargins: ConstraintAttributes { 786_432 }

    internal var layoutAttributes: [LayoutAttribute] {
        var attrs = [LayoutAttribute]()
        if contains(ConstraintAttributes.left) {
            attrs.append(.left)
        }
        if contains(ConstraintAttributes.top) {
            attrs.append(.top)
        }
        if contains(ConstraintAttributes.right) {
            attrs.append(.right)
        }
        if contains(ConstraintAttributes.bottom) {
            attrs.append(.bottom)
        }
        if contains(ConstraintAttributes.leading) {
            attrs.append(.leading)
        }
        if contains(ConstraintAttributes.trailing) {
            attrs.append(.trailing)
        }
        if contains(ConstraintAttributes.width) {
            attrs.append(.width)
        }
        if contains(ConstraintAttributes.height) {
            attrs.append(.height)
        }
        if contains(ConstraintAttributes.centerX) {
            attrs.append(.centerX)
        }
        if contains(ConstraintAttributes.centerY) {
            attrs.append(.centerY)
        }
        if contains(ConstraintAttributes.lastBaseline) {
            attrs.append(.lastBaseline)
        }

        #if os(iOS) || os(tvOS)
            if contains(ConstraintAttributes.firstBaseline) {
                attrs.append(.firstBaseline)
            }
            if contains(ConstraintAttributes.leftMargin) {
                attrs.append(.leftMargin)
            }
            if contains(ConstraintAttributes.rightMargin) {
                attrs.append(.rightMargin)
            }
            if contains(ConstraintAttributes.topMargin) {
                attrs.append(.topMargin)
            }
            if contains(ConstraintAttributes.bottomMargin) {
                attrs.append(.bottomMargin)
            }
            if contains(ConstraintAttributes.leadingMargin) {
                attrs.append(.leadingMargin)
            }
            if contains(ConstraintAttributes.trailingMargin) {
                attrs.append(.trailingMargin)
            }
            if contains(ConstraintAttributes.centerXWithinMargins) {
                attrs.append(.centerXWithinMargins)
            }
            if contains(ConstraintAttributes.centerYWithinMargins) {
                attrs.append(.centerYWithinMargins)
            }
        #endif

        return attrs
    }
}

internal func + (left: ConstraintAttributes, right: ConstraintAttributes) -> ConstraintAttributes {
    left.union(right)
}

internal func += (left: inout ConstraintAttributes, right: ConstraintAttributes) {
    left.formUnion(right)
}

internal func -= (left: inout ConstraintAttributes, right: ConstraintAttributes) {
    left.subtract(right)
}

internal func == (left: ConstraintAttributes, right: ConstraintAttributes) -> Bool {
    left.rawValue == right.rawValue
}
