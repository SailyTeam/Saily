//
//  DTScrollView.swift
//  Pods
//
//  Created by Admin on 18/01/2017.
//
//

import UIKit

public class DTScrollView: UIScrollView {
    
    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
     // Drawing code
     }
     */
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        panGestureRecognizer.delegate = self
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

//MARK: UIGestureRecognizerDelegate
extension DTScrollView: UIGestureRecognizerDelegate {
    public override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == panGestureRecognizer {
            if gestureRecognizer.numberOfTouches == 1 && zoomScale == 1.0 {
                return false
            }
        }
        
        return true
    }
}
