//
//  Tools+Data.swift
//  Protein
//
//  Created by Lakr Aream on 2020/4/19.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import Foundation

extension Tools {
    
    static let darkModeJS = """
    var darkModeCss = `
    * {
    background-color: #000000 !important;
    color: #fff !important;
    }
    `
    var documentHead = document.head || document.getElementsByTagName('head')[0];
    var darkModeStyle = style = document.createElement('style');
    documentHead.appendChild(style);
    style.type = 'text/css';
    if (style.styleSheet){
    // This is required for IE8 and below.
    style.styleSheet.cssText = css;
    } else {
    style.appendChild(document.createTextNode(darkModeCss));
    }
    """

}
