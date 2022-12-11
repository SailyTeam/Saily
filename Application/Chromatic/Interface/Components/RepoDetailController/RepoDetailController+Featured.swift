//
//  RepoDetailController+Featured.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/17.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import AptRepository
import Dog
import SDWebImage
import UIKit

extension RepoDetailController {
    func setupFeatured(with json: [String: Any], height: CGFloat) -> UIScrollView {
        let container = UIScrollView()
        container.alwaysBounceHorizontal = true
        container.showsVerticalScrollIndicator = false
        container.showsHorizontalScrollIndicator = false
        var anchor = UIView()
        container.addSubview(anchor)
        container.clipsToBounds = false
        let gap = 10
        anchor.snp.makeConstraints { x in
            x.leading.equalTo(container).offset(-gap)
            x.top.equalToSuperview()
            x.height.equalTo(height)
            x.width.equalTo(0)
        }
        var contentSize = 0
        if let banners = json["banners"] as? [[String: Any]] {
            banners.forEach { banner in
                guard let view = FeaturedBanner(banner: banner, inside: repo) else {
                    return
                }
                container.addSubview(view)
                view.snp.makeConstraints { x in
                    x.leading.equalTo(anchor.snp.trailing).offset(gap)
                    x.top.equalToSuperview()
                    x.bottom.equalTo(anchor)
                    x.width.equalTo(300)
                }
                anchor = view
                contentSize += 300 + gap
            }
        }
        contentSize += gap
        container.contentSize = CGSize(width: contentSize, height: 0)
        return container
    }
}

private class FeaturedBanner: UIView {
    let button = UIButton()
    let name = UILabel()
    let imageView = UIImageView()
    let package: Package

    init?(banner: [String: Any], inside repo: Repository) {
        guard let url = URL(string: banner["url"] as? String ?? ""),
              let identity = banner["package"] as? String,
              let title = banner["title"] as? String,
              let read = repo.metaPackage[identity.lowercased()]
        else {
            Dog.shared.join("FeaturedBanner", "broken metadata found when loading banner item")
            return nil
        }

        package = read

        super.init(frame: CGRect())

        addSubview(imageView)
        addSubview(name)
        addSubview(button)
        button.snp.makeConstraints { x in
            x.edges.equalToSuperview()
        }

        name.text = title
        name.font = .systemFont(ofSize: 12, weight: .semibold)
        name.alpha = 0.5
        name.textAlignment = .center
        name.snp.makeConstraints { x in
            x.leading.equalToSuperview()
            x.trailing.equalToSuperview()
            x.bottom.equalToSuperview()
            x.height.equalTo(30)
        }

        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.image = UIImage(named: "BannerImagePlaceholder")
        imageView.sd_setImage(with: url,
                              placeholderImage: imageView.image,
                              options: .highPriority,
                              context: nil)
        imageView.snp.makeConstraints { x in
            x.leading.equalToSuperview()
            x.trailing.equalToSuperview()
            x.bottom.equalTo(name.snp.top).offset(4)
            x.top.equalToSuperview()
        }

        button.addTarget(self, action: #selector(openPackage), for: .touchUpInside)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError() }

    @objc
    func openPackage() {
        let target = PackageController(package: package)
        parentViewController?.present(next: target)
    }
}
