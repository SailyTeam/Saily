//
//  Constant.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/5.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import UIKit

let cWebLocationSource = "https://github.com/SailyTeam/Saily"
let cWebLocationLicense = "https://raw.githubusercontent.com/SailyTeam/Saily/master/LICENSE"
let cWebLocationDocs = "https://github.com/SailyTeam/Saily"
let cWebLocationIssue = "https://github.com/SailyTeam/Saily/issues"

let cLXUIDefaultBackgroundColor = UIColor(light: UIColor(red: 250, green: 250, blue: 250)!, dark: .black)

let packageDefaultAvatar = UIImage(named: "mod")
let preferredPopOverSize = CGSize(width: 700, height: 555)

let DirectInstallInjectedPackageLocationKey = "wiki.qaq.chromatic.directInstall"

let darkModeJavascript =
    """
    function getMeta(metaName) {
        const metas = document.getElementsByTagName('meta');
        for (let i = 0; i < metas.length; i++) {
        if (metas[i].getAttribute('name') === metaName) {
            return metas[i].getAttribute('content');
        }
      }
      return '';
    }
    let schemeData = getMeta('color-scheme');
    if (schemeData.includes("dark")) { /* don't return */ } else {
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
        if (style.styleSheet) {
            // This is required for IE8 and below.
            style.styleSheet.cssText = css;
        } else {
            style.appendChild(document.createTextNode(darkModeCss));
        }
    }
    """

let cUserActivityDropPackage = "wiki.qaq.chromatic.drop.package"
