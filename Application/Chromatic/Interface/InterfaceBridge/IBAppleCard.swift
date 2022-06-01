//
//  SFAppleCard.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/29.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import DropDown
import SwiftMD5
import UIKit

extension InterfaceBridge {
    static func appleCardTouched(dropDownAnchor: UIView) {
        let dropDown = DropDown()
        dropDown.dataSource = allCardOptions
            .map(\.text)
            .invisibleSpacePadding()
        dropDown.anchorView = dropDownAnchor
        dropDown.selectionAction = { (index: Int, _: String) in
            allCardOptions[index].block(dropDownAnchor.parentViewController ?? UIViewController())
        }
        dropDown.show(onTopOf: dropDownAnchor.window)
    }
}

private struct CardOptions {
    let text: String
    let block: (UIViewController) -> Void
}

private let allCardOptions: [CardOptions] = [
    .init(text: NSLocalizedString("SET_GRAVATAR", comment: "Set Gravatar"), block: { controller in

        let alert = UIAlertController(title: NSLocalizedString("SET_GRAVATAR", comment: "Set Gravatar"),
                                      message: NSLocalizedString("INPUT_YOUR_EMAIL_FOR_GRAVATAR", comment: "Input your email for gravatar"),
                                      preferredStyle: .alert)
        alert.addTextField { _ in }
        alert.addAction(UIAlertAction(title: NSLocalizedString("CONFIRM", comment: "Confirm"), style: .default, handler: { [weak alert] _ in
            if let text = alert?.textFields?[0].text, text.contains("@") {
                let md5hash = SwiftMD5.md5From(text)
                if let url = URL(string: "https://www.gravatar.com/avatar/" + md5hash + "?s=512") {
                    let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
                    DispatchQueue.global().async {
                        URLSession
                            .shared
                            .dataTask(with: request) { data, _, _ in
                                if let data = data,
                                   let img = UIImage(data: data),
                                   let pngData = img.pngData(),
                                   pngData.count < 5_242_880 // limit on 5m
                                {
                                    UserDefaults
                                        .standard
                                        .setValue(pngData, forKey: "wiki.qaq.chromatic.userAvatar")
                                    NotificationCenter.default.post(name: .AppleCardAvatarUpdated,
                                                                    object: nil,
                                                                    userInfo: nil)
                                }
                            }
                            .resume()
                    }
                }
            }

        }))
        controller.present(alert, animated: true, completion: nil)
    }),
    .init(text: NSLocalizedString("RELOAD_ICLOUD_AVATAR", comment: "Reload iCloud Avatar"), block: { _ in
        UserDefaults
            .standard
            .removeObject(forKey: "wiki.qaq.chromatic.userAvatar")
        AppleAvatar.unblockLoad()
        AppleAvatar.prepareIconIfAvailable()
        NotificationCenter.default.post(name: .AppleCardAvatarUpdated,
                                        object: nil,
                                        userInfo: nil)
    }),
    .init(text: NSLocalizedString("REMOVE_AVATAR", comment: "Remove Avatar"), block: { _ in
        UserDefaults
            .standard
            .removeObject(forKey: "wiki.qaq.chromatic.userAvatar")
        AppleAvatar.blockLoad()
        NotificationCenter.default.post(name: .AppleCardAvatarUpdated,
                                        object: nil,
                                        userInfo: nil)
    }),
    .init(text: NSLocalizedString("RESET_COLORS", comment: "Reset Colors"), block: { _ in
        AppleCardColorProvider.shared.clear()
        NotificationCenter.default.post(name: .AppleCardColorUpdated,
                                        object: nil,
                                        userInfo: nil)
    }),
]
