//
//  UIView.swift
//  Protein
//
//  Created by Lakr Aream on 2020/4/18.
//  Copyright © 2020 Lakr Aream. All rights reserved.
//

import UIKit

extension UIView {

    var obtainParentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder?.next
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
    
    func puddingAnimate() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.1, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseInOut, animations: {
                self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
                UIDevice.haptic(style: .light)
            }) { (_) in
                DispatchQueue.main.async {UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseInOut, animations: {
                    self.transform = .identity
                    })
                }
            }
        }
    }
    
    func clearShadow() {
        layer.shadowColor = UIColor.clear.cgColor
    }
    
    func dropShadow(ofColor color: UIColor = UIColor(named: "G-Shadow")!, radius: CGFloat = 4, offset: CGSize = .zero, opacity: Float = 0.16) {
        layer.shadowColor = color.cgColor
        layer.shadowOffset = offset
        layer.shadowRadius = radius
        layer.shadowOpacity = opacity
        layer.masksToBounds = false
        clipsToBounds = false
    }

    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: self.bounds.size)
        let image = renderer.image { ctx in
            self.drawHierarchy(in: self.bounds, afterScreenUpdates: true)
        }
        return image
    }
    
    var universalWidth: CGFloat {
        get {
            let size = self.bounds.size
            return size.width > size.height ? size.width : size.height
        }
    }
    
    var universalHeight: CGFloat {
        get {
            let size = self.bounds.size
            return size.width < size.height ? size.width : size.height
        }
    }
    
    class func fromNib(named: String? = nil) -> Self {
        let name = named ?? "\(Self.self)"
        guard
            let nib = Bundle.main.loadNibNamed(name, owner: nil, options: nil)
            else { fatalError("missing expected nib named: \(name)") }
        guard
            /// we're using `first` here because compact map chokes compiler on
            /// optimized release, so you can't use two views in one nib if you wanted to
            /// and are now looking at this
            let view = nib.first as? Self
            else { fatalError("view of type \(Self.self) not found in \(nib)") }
        return view
    }
}
