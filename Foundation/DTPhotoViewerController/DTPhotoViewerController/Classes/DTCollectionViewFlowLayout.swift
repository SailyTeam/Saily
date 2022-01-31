//
//  DTCollectionViewFlowLayout.swift
//  Pods
//
//  Created by Admin on 17/01/2017.
//
//

import UIKit

class DTCollectionViewFlowLayout: UICollectionViewFlowLayout {
    var currentIndex: Int?
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        invalidateLayout()
        return true
    }
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        if let index = currentIndex, let collectionView = collectionView {
            currentIndex = nil
            return CGPoint(x: CGFloat(index) * collectionView.frame.size.width, y: 0)
        }
        
        return super.targetContentOffset(forProposedContentOffset: proposedContentOffset)
    }
}
