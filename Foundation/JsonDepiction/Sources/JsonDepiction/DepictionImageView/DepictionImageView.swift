//
//  DepictionImageView.swift
//  Sileo
//
//  Created by CoolStar on 7/6/19.
//  Copyright © 2019 CoolStar. All rights reserved.
//

import SDWebImage
import UIKit

class DepictionImageView: DepictionBaseView {
    let alignment: Int

    let imageView: UIImageView?

    var width: CGFloat
    var height: CGFloat
    let xPadding: CGFloat

    required init?(dictionary: [String: Any], viewController: UIViewController, tintColor: UIColor, isActionable: Bool) {
        guard let url = dictionary["URL"] as? String else {
            return nil
        }
        let width = (dictionary["width"] as? CGFloat) ?? CGFloat(0)
        let height = (dictionary["height"] as? CGFloat) ?? CGFloat(0)
        guard width != 0 || height != 0 else {
            return nil
        }
        guard let cornerRadius = dictionary["cornerRadius"] as? CGFloat else {
            return nil
        }
        self.width = width
        self.height = height
        alignment = (dictionary["alignment"] as? Int) ?? 0
        xPadding = (dictionary["xPadding"] as? CGFloat) ?? CGFloat(0)

        imageView = UIImageView(frame: .zero)

        super.init(dictionary: dictionary, viewController: viewController, tintColor: tintColor, isActionable: isActionable)

        SDWebImageManager.shared.loadImage(with: URL(string: url),
                                           options: .highPriority,
                                           progress: nil) { [weak self] image, _, _, _, _, _ in
            if let image = image, let self = self {
                self.imageView?.image = image
                let size = image.size
                if self.width == 0 {
                    self.width = self.height * (size.width / size.height)
                }
                if self.height == 0 {
                    self.height = self.width * (size.height / size.width)
                }
                self.delegate?.subviewHeightChanged()
            }
        }

        imageView?.layer.cornerRadius = cornerRadius
        imageView?.contentMode = .scaleAspectFit
        imageView?.clipsToBounds = true
        addSubview(imageView!)
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func depictionHeight(width: CGFloat) -> CGFloat {
        var height = height
        if self.width > (width - xPadding) {
            height = self.height * (width / self.width)
        }
        return height
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        var width = width
        if width > bounds.width - xPadding {
            width = bounds.width - xPadding
        }

        var x = CGFloat(0)
        switch alignment {
        case 2: do {
                x = bounds.width - width
                break
            }
        case 1: do {
                x = (bounds.width - width) / 2.0
                break
            }
        default: do {
                x = 0
                break
            }
        }

        var height = height
        if width != self.width {
            height = self.height * width / self.width
        }
        imageView?.frame = CGRect(x: x, y: 0, width: width, height: height)
    }
}
