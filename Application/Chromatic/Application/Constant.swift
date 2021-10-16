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
    """

let cRepositoryRedirection: [URL: URL] = [
    // procurs
    URL(string: "https://apt.procurs.us/Release")!:
        URL(string: "https://apt.procurs.us/dists/iphoneos-arm64/1700/Release")!,
    URL(string: "https://apt.procurs.us/Packages")!:
        URL(string: "https://apt.procurs.us/dists/iphoneos-arm64/1700/main/binary-iphoneos-arm/Packages")!,
    // bigboss
    URL(string: "http://apt.thebigboss.org/repofiles/cydia/CydiaIcon.png")!:
        URL(string: "http://apt.thebigboss.org/repofiles/cydia/dists/stable/CydiaIcon.png")!,
    URL(string: "http://apt.thebigboss.org/repofiles/cydia/Release")!:
        URL(string: "http://apt.thebigboss.org/repofiles/cydia/dists/stable/Release")!,
    URL(string: "http://apt.thebigboss.org/repofiles/cydia/Packages")!:
        URL(string: "http://apt.thebigboss.org/repofiles/cydia/dists/stable/main/binary-iphoneos-arm/Packages")!,
]

let cUserActivityDropPackageNewWindow = "wiki.qaq.cUserActivityDropPackageNewWindow"
