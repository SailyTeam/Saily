//
//  DepictionScreenshotsView.swift
//  Sileo
//
//  Created by CoolStar on 7/6/19.
//  Copyright © 2019 CoolStar. All rights reserved.
//

import AVKit
import DTPhotoViewerController
import SDWebImage
import UIKit

class DepictionScreenshotsView: DepictionBaseView, UIScrollViewDelegate {
    private let depiction: [String: Any]
    private let scrollView = UIScrollView(frame: .zero)

    private let itemSize: CGSize
    private let itemCornerRadius: CGFloat

    private var screenshotViews: [UIView] = []

    private var player: AVPlayer?
    private var playerViewController: AVPlayerViewController?

    private let isPaging: Bool

    required convenience init?(dictionary: [String: Any], viewController: UIViewController, tintColor: UIColor, isActionable: Bool) {
        self.init(dictionary: dictionary, viewController: viewController, tintColor: tintColor, isPaging: false, isActionable: isActionable)
    }

    @objc required init?(dictionary: [String: Any], viewController: UIViewController, tintColor: UIColor, isPaging: Bool, isActionable: Bool) {
        var dictionary = dictionary

        let deviceName = UIDevice.current.userInterfaceIdiom == .pad ? "ipad" : "iphone"
        if let specificDict = dictionary[deviceName] as? [String: Any] {
            dictionary = specificDict
        }

        guard let rawItemSize = dictionary["itemSize"] as? String else {
            return nil
        }
        let itemSize = NSCoder.cgSize(for: rawItemSize)
        if itemSize == .zero {
            return nil
        }
        self.itemSize = itemSize

        guard let itemCornerRadius = dictionary["itemCornerRadius"] as? CGFloat else {
            return nil
        }
        self.itemCornerRadius = itemCornerRadius
        self.isPaging = isPaging

        guard let screenshots = dictionary["screenshots"] as? [[String: Any]] else {
            return nil
        }

        depiction = dictionary

        super.init(dictionary: dictionary, viewController: viewController, tintColor: tintColor, isActionable: isActionable)

        scrollView.delegate = self
        scrollView.decelerationRate = .fast
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = isPaging
        addSubview(scrollView)

        var idx = 0
        for screenshot in screenshots {
            guard let urlStr = screenshot["url"] as? String else {
                continue
            }
            guard let url = URL(string: urlStr) else {
                continue
            }
            guard let accessibilityText = screenshot["accessibilityText"] as? String else {
                continue
            }

            let isVideoView = (screenshot["video"] as? Bool) ?? false

            if isVideoView {
                player = AVPlayer(url: url)
                player?.isMuted = true

                playerViewController = AVPlayerViewController()
                playerViewController?.player = player

                let videoView = playerViewController?.view
                if itemCornerRadius > 0 {
                    videoView?.layer.cornerRadius = itemCornerRadius
                    videoView?.clipsToBounds = true
                }
                if let videoView = videoView {
                    screenshotViews.append(videoView)
                    scrollView.addSubview(videoView)
                }
            } else {
                let screenshotView = UIButton(frame: .zero)
                screenshotView.addTarget(self, action: #selector(fullScreenImage), for: .touchUpInside)

                SDWebImageManager.shared.loadImage(with: url,
                                                   options: .highPriority,
                                                   progress: nil)
                { [weak self] image, _, _, _, _, _ in
                    screenshotView.setBackgroundImage(image, for: .normal)
                    self?.layoutSubviews()
                }
                screenshotView.accessibilityLabel = accessibilityText
                screenshotView.accessibilityIgnoresInvertColors = true
                screenshotView.layer.cornerRadius = itemCornerRadius
                screenshotView.clipsToBounds = true
                screenshotView.tag = idx

                screenshotViews.append(screenshotView)
                scrollView.addSubview(screenshotView)
            }
            idx += 1
        }
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func depictionHeight(width _: CGFloat) -> CGFloat {
        (isPaging ? fullViewHeight() : itemSize.height) + 32
    }

    func fullViewHeight() -> CGFloat {
        guard let parentViewController = parentViewController else {
            return 0
        }
        let verticalInsets = parentViewController.view.safeAreaInsets.top + parentViewController.view.safeAreaInsets.bottom
        return parentViewController.view.bounds.height - 32 - verticalInsets
    }

    @objc func fullScreenImage(_ sender: Any) {
        guard let senderButton = sender as? UIButton,
              let image = senderButton.backgroundImage(for: .normal)
        else {
            return
        }
        let controller = DTPhotoViewerController(referencedView: senderButton, image: image)
        var presenter = window?.rootViewController
        // we want this to be present as root as possible
        // and iirc, present on a presented controller will result crash
        // loop over to find the possible solution
        while let next = presenter?.presentedViewController {
            presenter = next
        }
        presenter?.present(controller, animated: true, completion: nil)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let oldSize = itemSize
        let spacing = CGFloat(16)
        var x = spacing
        var viewHeight = itemSize.height

        if isPaging {
            let viewWidth = (parentViewController?.view.bounds.width ?? 0) - (spacing * 4)
            x *= 2

            viewHeight = fullViewHeight()

            var scale = viewWidth / oldSize.width
            if oldSize.height * scale > viewHeight {
                scale = viewHeight / oldSize.height
            }
            let imageSize = CGSize(width: oldSize.width * scale, height: oldSize.height * scale)

            for screenshotView in screenshotViews {
                var size = imageSize
                if let screenshotViewButton = screenshotView as? UIButton {
                    if let backgroundImage = screenshotViewButton.currentBackgroundImage {
                        size = backgroundImage.size
                    }
                }

                size.height = size.height * imageSize.width / size.width
                size.width = imageSize.width

                if viewWidth / size.width < viewHeight / size.width {
                    scale = viewWidth / size.width
                } else {
                    scale = viewHeight / size.height
                }

                size.height *= scale
                size.width *= scale

                screenshotView.frame = CGRect(origin: CGPoint(x: x + (viewWidth / 2 - size.width / 2),
                                                              y: 16 + (viewHeight / 2 - size.height / 2)),
                                              size: size)
                screenshotView.layer.cornerRadius = itemCornerRadius * scale
                x += viewWidth + spacing
            }

            if x < parentViewController?.view.bounds.width ?? 0 {
                x = parentViewController?.view.bounds.width ?? 0
            } else {
                x += spacing
            }
        } else {
            for screenshotView in screenshotViews {
                var size = itemSize
                if let screenshotViewButton = screenshotView as? UIButton {
                    if let backgroundImage = screenshotViewButton.currentBackgroundImage {
                        size = backgroundImage.size
                    }
                }

                let rawImageSize = size

                size.width = size.width * itemSize.height / size.height
                size.height = itemSize.height

                var scaling = CGFloat(1)
                var yOffset = CGFloat(0)
                let maxWidth = bounds.width - (spacing * 2)

                if size.width > maxWidth {
                    scaling = maxWidth / size.width
                    size.width *= scaling

                    let scaledHeight = size.width * rawImageSize.height / rawImageSize.width

                    yOffset = (itemSize.height - scaledHeight) / 2
                    size.height *= scaling
                }

                screenshotView.frame = CGRect(origin: CGPoint(x: x, y: 16 + yOffset), size: size)
                screenshotView.layer.cornerRadius = itemCornerRadius * scaling
                x += size.width + spacing
            }
        }

        scrollView.contentSize = CGSize(width: x, height: viewHeight + 32)
        if x < bounds.width && !isPaging {
            scrollView.frame = CGRect(x: (bounds.width - x) / 2, y: 0, width: x, height: bounds.height)
        } else {
            scrollView.frame = bounds
        }

        if itemSize != oldSize || isPaging {
            subviewHeightChanged()
        }
    }

    func viewSegmentWidth() -> CGFloat {
        let spacing = CGFloat(16)
        guard let parentViewController = parentViewController else {
            return 0
        }
        return parentViewController.view.bounds.width - (spacing * 3)
    }

    func pageIndex(contentOffset: CGFloat) -> Int {
        let endX = Float(contentOffset)
        return Int(min(10, max(0, round(endX / Float(viewSegmentWidth())))))
    }

    func currentPageIndex() -> Int {
        pageIndex(contentOffset: scrollView.contentOffset.x)
    }

    func contentOffset(pageIndex: Int) -> CGFloat {
        CGFloat(pageIndex) * viewSegmentWidth()
    }

    func scrollToPageIndex(_ pageIndex: Int, animated: Bool) {
        scrollView.setContentOffset(CGPoint(x: contentOffset(pageIndex: pageIndex), y: 0), animated: animated)
    }

    func scrollViewWillEndDragging(_: UIScrollView, withVelocity _: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if !isPaging {
            return
        }

        let targetIndex = pageIndex(contentOffset: targetContentOffset.pointee.x)
        targetContentOffset.pointee.x = contentOffset(pageIndex: targetIndex)
    }
}
