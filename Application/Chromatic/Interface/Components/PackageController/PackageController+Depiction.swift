//
//  PackageController+Depiction.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/17.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import AptRepository
import JsonDepiction
import SDWebImage
import UIKit

extension PackageController {
    func defaultDepiction() -> UIView {
        var targetJsonData: [String: Any] = [:]
        targetJsonData["minVersion"] = "0.1"
        targetJsonData["class"] = "DepictionTabView"

        var tabRoot: [String: Any] = ["tabname": NSLocalizedString("PACKAGE_DETAIL", comment: "Package Detail"),
                                      "class": "DepictionStackView"]
        var tabViewsArray: [[String: Any]] = []

        if let descMarkDown = packageObject.latestMetadata?["description"] {
            var newmd: [String: Any] = [:]
            newmd["class"] = "DepictionMarkdownView"
            newmd["useSpacing"] = "true"
            newmd["markdown"] = descMarkDown
            tabViewsArray.append(newmd)
            tabViewsArray.append(["class": "DepictionSeparatorView"])
        }

        var version = [String: Any]()
        version["title"] = NSLocalizedString("VERSION", comment: "Version")
        version["text"] = packageObject.latestMetadata?["version"] ?? "0.0.0.???"
        version["class"] = "DepictionTableTextView"
        tabViewsArray.append(version)

        var section = [String: Any]()
        section["title"] = NSLocalizedString("SECTION", comment: "Section")
        section["text"] = packageObject.latestMetadata?["section"] ?? "Unknown"
        section["class"] = "DepictionTableTextView"
        tabViewsArray.append(section)

        var author = [String: Any]()
        author["title"] = NSLocalizedString("AUTHOR", comment: "Author")
        author["text"] = packageObject.latestMetadata?["author"] ?? "Unknown"
        author["class"] = "DepictionTableTextView"
        tabViewsArray.append(author)

        var maintainer = [String: Any]()
        maintainer["title"] = NSLocalizedString("MAINTAINER", comment: "Maintainer")
        maintainer["text"] = packageObject.latestMetadata?["maintainer"] ?? "Unknown"
        maintainer["class"] = "DepictionTableTextView"
        tabViewsArray.append(maintainer)

        tabRoot["views"] = tabViewsArray
        targetJsonData["tabs"] = [tabRoot]

        return DepictionBaseView.view(dictionary: targetJsonData,
                                      viewController: UIViewController(),
                                      tintColor: .systemOrange,
                                      isActionable: false) ?? UIView()
    }

    func downloadDepictionIfAvailable(onComplete: @escaping (UIView?) -> Void) {
        DispatchQueue.global().async { [self] in
            switch PackageCenter.default.depiction(of: packageObject) {
            case let .web(url: url):
                DispatchQueue.main.async {
                    let view = ExpandedWebView()
                    view.load(url: url)
                    view.onHeightUpdate = { [weak self] height in
                        let decision = height + 100
                        if self?.depictionViewHeight != decision {
                            self?.depictionViewHeight = decision
                        }
                    }
                    onComplete(view)
                }
            case let .json(url):
                URLSession
                    .shared
                    .dataTask(with: url) { data, _, _ in
                        if let data = data,
                           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                        {
                            if let urlStr = json["headerImage"] as? String,
                               let urlBanner = URL(string: urlStr)
                            {
                                DispatchQueue.main.async {
                                    SDWebImageManager
                                        .shared
                                        .loadImage(with: urlBanner,
                                                   options: .highPriority,
                                                   progress: nil)
                                    { [weak self] image, _, _, _, _, _ in
                                        guard let self = self else { return }
                                        if let image = image {
                                            self.bannerImageView.image = image
                                            self.bannerImageIconView.isHidden = true
                                        }
                                    }
                                }
                            }
                            let colorStr = json["tintColor"] as? String
                            let color = UIColor(css: colorStr) ?? .systemOrange
                            DispatchQueue.main.async {
                                let proxy = PackageControllerProxy()
                                proxy.parentController = self
                                self.bannerPackageView.buttonBackground.backgroundColor = color
                                if let view = DepictionBaseView.view(dictionary: json,
                                                                     viewController: proxy,
                                                                     tintColor: color,
                                                                     isActionable: true)
                                {
                                    onComplete(view)
                                }
                            }
                        }
                    }
                    .resume()
            default:
                break
            }
        }
    }
}
