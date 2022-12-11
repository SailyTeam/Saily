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
    @available(*, deprecated, renamed: "snp.left")
    var snp_left: ConstraintItem { snp.left }

    @available(*, deprecated, renamed: "snp.top")
    var snp_top: ConstraintItem { snp.top }

    @available(*, deprecated, renamed: "snp.right")
    var snp_right: ConstraintItem { snp.right }

    @available(*, deprecated, renamed: "snp.bottom")
    var snp_bottom: ConstraintItem { snp.bottom }

    @available(*, deprecated, renamed: "snp.leading")
    var snp_leading: ConstraintItem { snp.leading }

    @available(*, deprecated, renamed: "snp.trailing")
    var snp_trailing: ConstraintItem { snp.trailing }

    @available(*, deprecated, renamed: "snp.width")
    var snp_width: ConstraintItem { snp.width }

    @available(*, deprecated, renamed: "snp.height")
    var snp_height: ConstraintItem { snp.height }

    @available(*, deprecated, renamed: "snp.centerX")
    var snp_centerX: ConstraintItem { snp.centerX }

    @available(*, deprecated, renamed: "snp.centerY")
    var snp_centerY: ConstraintItem { snp.centerY }

    @available(*, deprecated, renamed: "snp.baseline")
    var snp_baseline: ConstraintItem { snp.baseline }

    @available(*, deprecated, renamed: "snp.lastBaseline")
    @available(iOS 8.0, OSX 10.11, *)
    var snp_lastBaseline: ConstraintItem { snp.lastBaseline }

    @available(iOS, deprecated, renamed: "snp.firstBaseline")
    @available(iOS 8.0, OSX 10.11, *)
    var snp_firstBaseline: ConstraintItem { snp.firstBaseline }

    @available(iOS, deprecated, renamed: "snp.leftMargin")
    @available(iOS 8.0, *)
    var snp_leftMargin: ConstraintItem { snp.leftMargin }

    @available(iOS, deprecated, renamed: "snp.topMargin")
    @available(iOS 8.0, *)
    var snp_topMargin: ConstraintItem { snp.topMargin }

    @available(iOS, deprecated, renamed: "snp.rightMargin")
    @available(iOS 8.0, *)
    var snp_rightMargin: ConstraintItem { snp.rightMargin }

    @available(iOS, deprecated, renamed: "snp.bottomMargin")
    @available(iOS 8.0, *)
    var snp_bottomMargin: ConstraintItem { snp.bottomMargin }

    @available(iOS, deprecated, renamed: "snp.leadingMargin")
    @available(iOS 8.0, *)
    var snp_leadingMargin: ConstraintItem { snp.leadingMargin }

    @available(iOS, deprecated, renamed: "snp.trailingMargin")
    @available(iOS 8.0, *)
    var snp_trailingMargin: ConstraintItem { snp.trailingMargin }

    @available(iOS, deprecated, renamed: "snp.centerXWithinMargins")
    @available(iOS 8.0, *)
    var snp_centerXWithinMargins: ConstraintItem { snp.centerXWithinMargins }

    @available(iOS, deprecated, renamed: "snp.centerYWithinMargins")
    @available(iOS 8.0, *)
    var snp_centerYWithinMargins: ConstraintItem { snp.centerYWithinMargins }

    @available(*, deprecated, renamed: "snp.edges")
    var snp_edges: ConstraintItem { snp.edges }

    @available(*, deprecated, renamed: "snp.size")
    var snp_size: ConstraintItem { snp.size }

    @available(*, deprecated, renamed: "snp.center")
    var snp_center: ConstraintItem { snp.center }

    @available(iOS, deprecated, renamed: "snp.margins")
    @available(iOS 8.0, *)
    var snp_margins: ConstraintItem { snp.margins }

    @available(iOS, deprecated, renamed: "snp.centerWithinMargins")
    @available(iOS 8.0, *)
    var snp_centerWithinMargins: ConstraintItem { snp.centerWithinMargins }

    @available(*, deprecated, renamed: "snp.prepareConstraints(_:)")
    func snp_prepareConstraints(_ closure: (_ make: ConstraintMaker) -> Void) -> [Constraint] {
        snp.prepareConstraints(closure)
    }

    @available(*, deprecated, renamed: "snp.makeConstraints(_:)")
    func snp_makeConstraints(_ closure: (_ make: ConstraintMaker) -> Void) {
        snp.makeConstraints(closure)
    }

    @available(*, deprecated, renamed: "snp.remakeConstraints(_:)")
    func snp_remakeConstraints(_ closure: (_ make: ConstraintMaker) -> Void) {
        snp.remakeConstraints(closure)
    }

    @available(*, deprecated, renamed: "snp.updateConstraints(_:)")
    func snp_updateConstraints(_ closure: (_ make: ConstraintMaker) -> Void) {
        snp.updateConstraints(closure)
    }

    @available(*, deprecated, renamed: "snp.removeConstraints()")
    func snp_removeConstraints() {
        snp.removeConstraints()
    }

    var snp: ConstraintViewDSL {
        ConstraintViewDSL(view: self)
    }
}
