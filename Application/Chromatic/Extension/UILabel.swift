//
//  UILabel.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/14.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import UIKit

extension UILabel {
    func highlight(text: String?, font: UIFont? = nil, color: UIColor? = nil) {
        guard let fullText = self.text, let target = text else {
            return
        }

        let attribText = NSMutableAttributedString(string: fullText)
        let range: NSRange = attribText.mutableString.range(of: target, options: .caseInsensitive)

        var attributes: [NSAttributedString.Key: Any] = [:]
        if let font {
            attributes[.font] = font
        }
        if let color {
            attributes[.foregroundColor] = color
        }
        attribText.addAttributes(attributes, range: range)
        attributedText = attribText
    }

    func limitedLeadingHighlight(text: String?, color: UIColor? = nil) {
        guard var fullText = self.text, let target = text else {
            return
        }
        if let range: Range<String.Index> = fullText.range(of: target) {
            let index: Int = fullText.distance(from: fullText.startIndex, to: range.lowerBound)
            if index > 15 {
                fullText.removeFirst(index - 15)
                fullText = "... " + fullText
            }
        } else {
            return // not found
        }

        let attribText = NSMutableAttributedString(string: fullText)
        let range: NSRange = attribText.mutableString.range(of: target, options: .caseInsensitive)

        var attributes: [NSAttributedString.Key: Any] = [:]
        if let font {
            attributes[.font] = font
        }
        if let color {
            attributes[.foregroundColor] = color
        }
        attribText.addAttributes(attributes, range: range)
        attributedText = attribText
    }
}
