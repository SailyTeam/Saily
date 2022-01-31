//
//  DTPhotoViewerControllerDataSource.swift
//  Pods
//
//  Created by Admin on 17/01/2017.
//
//

import UIKit

@objc public protocol DTPhotoViewerControllerDataSource: NSObjectProtocol {
    /// Total number of photo in viewer.
    func numberOfItems(in photoViewerController: DTPhotoViewerController) -> Int
    
    /// Configure each photo in viewer
    /// Implementation for photoViewerController:configurePhotoAt:withImageView is mandatory.
    /// Not implementing this method will cause viewer not to work properly.
    func photoViewerController(_ photoViewerController: DTPhotoViewerController, configurePhotoAt index: Int, withImageView imageView: UIImageView)
    
    /// This is usually used if you have custom DTPhotoCollectionViewCell and configure each photo differently.
    /// Remember this method cannot be a replacement of photoViewerController:configurePhotoAt:withImageView
    @objc optional func photoViewerController(_ photoViewerController: DTPhotoViewerController, configureCell cell: DTPhotoCollectionViewCell, forPhotoAt index: Int)
    
    /// This method provide the specific referenced view for each photo item in viewer that will be used for smoother dismissal transition.
    @objc optional func photoViewerController(_ photoViewerController: DTPhotoViewerController, referencedViewForPhotoAt index: Int) -> UIView?
}
