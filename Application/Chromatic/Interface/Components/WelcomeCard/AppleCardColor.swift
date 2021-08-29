//
//  AppleCardColorView.swift
//  Chromatic
//
//  Created by Lakr Aream on 2020/4/18.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import PropertyWrapper
import SwiftThrottle
import UIKit

class AppleCardColorView: UIView {
    private var isAinUse: Bool = false
    private var containerA = UIView()
    private var containerB = UIView()

    let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffect.Style.regular))

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    required init() {
        super.init(frame: CGRect())

        backgroundColor = .systemBackground

        addSubview(containerA)
        containerA.snp.makeConstraints { x in
            x.edges.equalToSuperview()
        }
        addSubview(containerB)
        containerB.snp.makeConstraints { x in
            x.edges.equalToSuperview()
        }
        clipsToBounds = true
        addSubview(blurEffectView)
        blurEffectView.snp.makeConstraints { x in
            x.edges.equalToSuperview()
        }

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reloadColors),
                                               name: .AppleCardColorUpdated, object: nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            AppleCardColorProvider.shared.cacheWidth = Int(self.frame.width)
            AppleCardColorProvider.shared.cacheHeight = Int(self.frame.height)
            self.reloadColors()
        }
    }

    private var reloadThrottle = Throttle(minimumDelay: 3, queue: .main)
    @objc func reloadColors() {
        reloadThrottle.throttle {
            let targetContainer = self.isAinUse ? self.containerB : self.containerA
            let oldContainer = self.isAinUse ? self.containerA : self.containerB

            self.isAinUse = !self.isAinUse

            targetContainer.alpha = 0
            targetContainer.subviews.forEach { view in
                view.removeFromSuperview()
            }

            //                         from     x        y        r  to    x        y        r
            var viewContainer = [Int: (CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, UIView)]()
            //                         0        1        2        3        4        5        6

            for (index, item) in AppleCardColorProvider.shared.records.enumerated() {
                let view = UIView()
                targetContainer.addSubview(view)
                view.backgroundColor = UIColor(hexString: item.color)
                view.alpha = /* CGFloat(Double.random(in: 0.4...1.0)) */ 0.6
                view.layer.cornerRadius = CGFloat(item.r)

                let getx = CGFloat(item.x)
                let gety = CGFloat(item.y)
                let getr = CGFloat(item.r * 2)
                let rndx = CGFloat.random(in: -200 ... 200)
                let rndy = CGFloat.random(in: -200 ... 200)
                let rndr = CGFloat.random(in: 0.5 ... 2)

                let fromx = getx + rndx
                let fromy = gety + rndy
                let fromsize = getr * rndr

                view.snp.makeConstraints { x in
                    x.width.equalTo(fromsize)
                    x.height.equalTo(fromsize)
                    x.centerX.equalTo(targetContainer.snp.leading).offset(fromx)
                    x.centerY.equalTo(targetContainer.snp.top).offset(fromy)
                }
                view.layoutIfNeeded()
                viewContainer[index] = (fromx, fromy, fromsize, getx, gety, getr, view)
            }
            self.bringSubviewToFront(targetContainer)
            self.bringSubviewToFront(self.blurEffectView)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                UIView.animate(withDuration: 1.5) {
                    targetContainer.alpha = 1
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                UIView.animate(withDuration: 2.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.8, options: .curveEaseInOut, animations: {
                    for (_, load) in viewContainer {
                        load.6.snp.updateConstraints { x in
                            x.width.equalTo(load.5)
                            x.height.equalTo(load.5)
                            x.centerX.equalTo(targetContainer.snp.leading).offset(load.3)
                            x.centerY.equalTo(targetContainer.snp.top).offset(load.4)
                        }
                    }
                    self.layoutIfNeeded()
                }) { _ in
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                UIView.animate(withDuration: 1) {
                    oldContainer.alpha = 0
                }
            }
        }
    }
}

class AppleCardColorProvider {
    static let shared = AppleCardColorProvider()
    private init() {}

    let maxColor = 16

    let notificationThrottle = Throttle(minimumDelay: 1, queue: .main)

    private let encoder = PropertyListEncoder()
    private let decoder = PropertyListDecoder()

    @UserDefaultsWrapper(key: "wiki.qaq.chromatic.AppleCard.Colors", defaultValue: Data())
    private var recordData: Data

    struct Record: Codable {
        let x: Int
        let y: Int
        let color: String
        let r: Int
    }

    typealias RecordType = [Record]
    public var records: RecordType {
        set {
            if let data = try? encoder.encode(newValue) {
                recordData = data
            }
            notificationThrottle.throttle {
                NotificationCenter.default.post(name: .AppleCardColorUpdated, object: nil)
            }
        }
        get {
            if let result = try? decoder.decode(RecordType.self, from: recordData) {
                return result
            } else {
                return []
            }
        }
    }

    public var _cacheWidth: Int = 320
    public var cacheWidth: Int {
        set {
            if newValue < 10 {
                return
            }
            _cacheWidth = newValue
        }
        get {
            _cacheWidth
        }
    }

    private var _cacheHeight: Int = 180
    public var cacheHeight: Int {
        set {
            if newValue < 10 {
                return
            }
            _cacheHeight = newValue
        }
        get {
            _cacheHeight
        }
    }

    func addColor(withCount: Int) {
        if withCount < 1 {
            return
        }
        var capture = records
        for _ in 0 ... withCount {
            var rangeX = Int(cacheWidth)
            var rangeY = Int(cacheHeight)
            var rangeR = Int((rangeY + rangeX) / 16)
            if rangeX < 0 { rangeX = 0 }
            if rangeY < 0 { rangeY = 0 }
            if rangeR < 18 { rangeR = 18 }
            let color = UIColor.randomAsPudding

            let x = Int.random(in: -10 ... (rangeX + 10))
            let y = Int.random(in: -10 ... (rangeY + 10))
            let r = Int.random(in: 15 ... rangeR)

            capture.append(.init(x: x, y: y, color: color.hexString, r: r))
        }
        while capture.count > maxColor {
            capture.removeFirst()
        }
        records = capture
    }

    func clear() {
        records = []
    }
}
