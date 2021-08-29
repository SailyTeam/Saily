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

public extension ConstraintView {
    @available(*, deprecated, message: "Use newer snp.* syntax.")
    var snp_left: ConstraintItem { snp.left }

    @available(*, deprecated, message: "Use newer snp.* syntax.")
    var snp_top: ConstraintItem { snp.top }

    @available(*, deprecated, message: "Use newer snp.* syntax.")
    var snp_right: ConstraintItem { snp.right }

    @available(*, deprecated, message: "Use newer snp.* syntax.")
    var snp_bottom: ConstraintItem { snp.bottom }

    @available(*, deprecated, message: "Use newer snp.* syntax.")
    var snp_leading: ConstraintItem { snp.leading }

    @available(*, deprecated, message: "Use newer snp.* syntax.")
    var snp_trailing: ConstraintItem { snp.trailing }

    @available(*, deprecated, message: "Use newer snp.* syntax.")
    var snp_width: ConstraintItem { snp.width }

    @available(*, deprecated, message: "Use newer snp.* syntax.")
    var snp_height: ConstraintItem { snp.height }

    @available(*, deprecated, message: "Use newer snp.* syntax.")
    var snp_centerX: ConstraintItem { snp.centerX }

    @available(*, deprecated, message: "Use newer snp.* syntax.")
    var snp_centerY: ConstraintItem { snp.centerY }

    @available(*, deprecated, message: "Use newer snp.* syntax.")
    var snp_baseline: ConstraintItem { snp.baseline }

    @available(*, deprecated, message: "Use newer snp.* syntax.")
    @available(iOS 8.0, OSX 10.11, *)
    var snp_lastBaseline: ConstraintItem { snp.lastBaseline }

    @available(iOS, deprecated, message: "Use newer snp.* syntax.")
    @available(iOS 8.0, OSX 10.11, *)
    var snp_firstBaseline: ConstraintItem { snp.firstBaseline }

    @available(iOS, deprecated, message: "Use newer snp.* syntax.")
    @available(iOS 8.0, *)
    var snp_leftMargin: ConstraintItem { snp.leftMargin }

    @available(iOS, deprecated, message: "Use newer snp.* syntax.")
    @available(iOS 8.0, *)
    var snp_topMargin: ConstraintItem { snp.topMargin }

    @available(iOS, deprecated, message: "Use newer snp.* syntax.")
    @available(iOS 8.0, *)
    var snp_rightMargin: ConstraintItem { snp.rightMargin }

    @available(iOS, deprecated, message: "Use newer snp.* syntax.")
    @available(iOS 8.0, *)
    var snp_bottomMargin: ConstraintItem { snp.bottomMargin }

    @available(iOS, deprecated, message: "Use newer snp.* syntax.")
    @available(iOS 8.0, *)
    var snp_leadingMargin: ConstraintItem { snp.leadingMargin }

    @available(iOS, deprecated, message: "Use newer snp.* syntax.")
    @available(iOS 8.0, *)
    var snp_trailingMargin: ConstraintItem { snp.trailingMargin }

    @available(iOS, deprecated, message: "Use newer snp.* syntax.")
    @available(iOS 8.0, *)
    var snp_centerXWithinMargins: ConstraintItem { snp.centerXWithinMargins }

    @available(iOS, deprecated, message: "Use newer snp.* syntax.")
    @available(iOS 8.0, *)
    var snp_centerYWithinMargins: ConstraintItem { snp.centerYWithinMargins }

    @available(*, deprecated, message: "Use newer snp.* syntax.")
    var snp_edges: ConstraintItem { snp.edges }

    @available(*, deprecated, message: "Use newer snp.* syntax.")
    var snp_size: ConstraintItem { snp.size }

    @available(*, deprecated, message: "Use newer snp.* syntax.")
    var snp_center: ConstraintItem { snp.center }

    @available(iOS, deprecated, message: "Use newer snp.* syntax.")
    @available(iOS 8.0, *)
    var snp_margins: ConstraintItem { snp.margins }

    @available(iOS, deprecated, message: "Use newer snp.* syntax.")
    @available(iOS 8.0, *)
    var snp_centerWithinMargins: ConstraintItem { snp.centerWithinMargins }

    @available(*, deprecated, message: "Use newer snp.* syntax.")
    func snp_prepareConstraints(_ closure: (_ make: ConstraintMaker) -> Void) -> [Constraint] {
        snp.prepareConstraints(closure)
    }

    @available(*, deprecated, message: "Use newer snp.* syntax.")
    func snp_makeConstraints(_ closure: (_ make: ConstraintMaker) -> Void) {
        snp.makeConstraints(closure)
    }

    @available(*, deprecated, message: "Use newer snp.* syntax.")
    func snp_remakeConstraints(_ closure: (_ make: ConstraintMaker) -> Void) {
        snp.remakeConstraints(closure)
    }

    @available(*, deprecated, message: "Use newer snp.* syntax.")
    func snp_updateConstraints(_ closure: (_ make: ConstraintMaker) -> Void) {
        snp.updateConstraints(closure)
    }

    @available(*, deprecated, message: "Use newer snp.* syntax.")
    func snp_removeConstraints() {
        snp.removeConstraints()
    }

    var snp: ConstraintViewDSL {
        ConstraintViewDSL(view: self)
    }
}
