//
//  IBPackageCollection.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/9/12.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import AptRepository
import UIKit

extension InterfaceBridge {
    static func calculatesPackageCellSize(availableWidth available: CGFloat) -> CGSize {
        var foo = 0
        return calculatesPackageCellSize(availableWidth: available, andItemsPerRow: &foo)
    }

    static func calculatesPackageCellSize(availableWidth available: CGFloat, andItemsPerRow: inout Int) -> CGSize {
        debugPrint("calculatesPackageCellSize \(available)")

        var itemsPerRow = 1
        let padding: CGFloat = 8
        var result = CGSize()
        result.width = 2000

        // get me the itemsPerRow
        let maximumWidth: CGFloat = 280 // soft limit
        // | padding [minimalWidth] padding [minimalWidth] padding |
        if available > maximumWidth * 2 + padding * 3 {
            // just in case, dont loop forever
            while result.width > maximumWidth, itemsPerRow <= 10 {
                itemsPerRow += 1
                // [minimalWidth] padding |
                var recalculate = (available - padding) / CGFloat(itemsPerRow)
                // [minimalWidth]
                recalculate -= padding
                result.width = recalculate
                result.height = result.width * 0.25
            }
        } else {
            itemsPerRow = 1
        }

        if itemsPerRow < 2 {
            // no padding for single element
            andItemsPerRow = itemsPerRow
            return CGSize(width: available, height: 50)
        }

        // now, do the final math
        var recalculate = (available - padding) / CGFloat(itemsPerRow)
        // [minimalWidth]
        recalculate -= padding
        result.width = recalculate
        result.height = 50

        // don't crash my app any how
        if result.width < 0 { result.width = 0 }

        andItemsPerRow = itemsPerRow

        return result
    }

    static func packageContextMenuConfiguration(for package: Package, reference fromView: UIView) -> UIContextMenuConfiguration {
        UIContextMenuConfiguration(identifier: nil) {
            let target = PackageController(package: package)
            target.previewContentSizeOverwrite = CGSize(width: 780, height: 1000)
            return target
        } actionProvider: { _ in
            let actions = PackageMenuAction
                .allMenuActions
                .filter { $0.elegantForPerform(package) }
                .map { action in
                    UIAction(
                        title: action.descriptor.describe(),
                        image: action.descriptor.icon()
                    ) { _ in action.block(package, fromView) }
                }
            return UIMenu(title: "", children: actions)
        }
    }
}
