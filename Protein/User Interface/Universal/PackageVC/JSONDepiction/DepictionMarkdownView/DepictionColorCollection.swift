//
//  DepictionColorCollection.swift
//  Sileo
//
//  Created by CoolStar on 11/19/19.
//  Copyright © 2019 CoolStar. All rights reserved.
//

import UIKit
import Down

public struct DepictionColorCollection: ColorCollection {

    public var heading1 = SEColors.downLabel
    public var heading2 = SEColors.downLabel
    public var heading3 = SEColors.downLabel
    public var heading4 = SEColors.downLabel
    public var heading5 = SEColors.downLabel
    public var heading6 = SEColors.downLabel
    public var body = SEColors.downLabel
    public var code = SEColors.downLabel
    public var link = DownColor.systemBlue
    public var quote = DownColor.darkGray
    public var quoteStripe = DownColor.darkGray
    public var thematicBreak = DownColor(white: 0.9, alpha: 1)
    public var listItemPrefix = DownColor.lightGray
    public var codeBlockBackground = DownColor(red: 0.96, green: 0.97, blue: 0.98, alpha: 1)
    
}
