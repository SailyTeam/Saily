//
//  Helper.swift
//  Pods
//
//  Created by Admin on 16/03/2017.
//
//

import QuartzCore
import UIKit

func clip<T : Comparable>(_ x0: T, _ x1: T, _ v: T) -> T {
    return max(x0, min(x1, v))
}

func lerp<T : FloatingPoint>(_ v0: T, _ v1: T, _ t: T) -> T {
    return v0 + (v1 - v0) * t
}

extension UIView {
    func isRightToLeft() -> Bool {
        return UIView.userInterfaceLayoutDirection(for: semanticContentAttribute) == .rightToLeft
    }
}
