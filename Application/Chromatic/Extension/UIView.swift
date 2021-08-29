//
//  UIView.swift
//  Chromatic
//
//  Created by Lakr Aream on 2021/8/8.
//  Copyright © 2021 Lakr Aream. All rights reserved.
//

import UIKit

private let kDefaultShadowColor = UIColor(light: .gray, dark: .black)

extension UIView {
    func dropShadow(ofColor color: UIColor = kDefaultShadowColor,
                    radius: CGFloat = 4,
                    offset: CGSize = .zero,
                    opacity: Float = 0.16)
    {
        layer.shadowColor = color.cgColor
        layer.shadowOffset = offset
        layer.shadowRadius = radius
        layer.shadowOpacity = opacity
        layer.masksToBounds = false
        clipsToBounds = false
    }

    func puddingAnimate() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.1,
                           delay: 0,
                           usingSpringWithDamping: 1,
                           initialSpringVelocity: 1,
                           options: .curveEaseInOut,
                           animations: {
                               self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
                           }) { _ in
                DispatchQueue.main.async {
                    UIView.animate(withDuration: 0.5,
                                   delay: 0,
                                   usingSpringWithDamping: 1,
                                   initialSpringVelocity: 1,
                                   options: .curveEaseInOut,
                                   animations: {
                                       self.transform = .identity
                                   })
                }
            }
        }
    }
}
