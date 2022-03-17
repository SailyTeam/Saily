//
//  DTPhotoViewerController.swift
//  DTPhotoViewerController
//
//  Created by Vo Duc Tung on 29/04/16.
//  Copyright © 2016 Vo Duc Tung. All rights reserved.
//

import AVKit
import Photos
import UIKit

private let kPhotoCollectionViewCellIdentifier = "wiki.qaq.kPhotoCollectionViewCell"

open class DTPhotoViewerController: UIViewController {
    /// Scroll direction
    /// Default value is UICollectionViewScrollDirectionVertical
    public var scrollDirection: UICollectionView.ScrollDirection = .horizontal {
        didSet {
            // Update collection view flow layout
            (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.scrollDirection = scrollDirection
        }
    }

    /// Datasource
    /// Providing number of image items to controller and how to confiure image for each image view in it.
    public weak var dataSource: DTPhotoViewerControllerDataSource?

    /// Delegate
    public weak var delegate: DTPhotoViewerControllerDelegate?

    /// Indicates if status bar should be hidden after photo viewer controller is presented.
    /// Default value is true
    open var shouldHideStatusBarOnPresent = true

    /// Indicates status bar style when photo viewer controller is being presenting
    /// Default value if UIStatusBarStyle.default
    open var statusBarStyleOnPresenting: UIStatusBarStyle = .default

    /// Indicates status bar animation style when changing hidden status
    /// Default value if UIStatusBarStyle.slide
    open var statusBarAnimationStyle: UIStatusBarAnimation = .slide

    /// Indicates status bar style after photo viewer controller is being dismissing
    /// Include when pan gesture recognizer is active.
    /// Default value if UIStatusBarStyle.LightContent
    open var statusBarStyleOnDismissing: UIStatusBarStyle = .lightContent

    /// Background color of the viewer.
    /// Default value is black.
    open var backgroundColor: UIColor = .black {
        didSet {
            backgroundView.backgroundColor = backgroundColor
        }
    }

    /// Indicates if referencedView should be shown or hidden automatically during presentation and dismissal.
    /// Setting automaticallyUpdateReferencedViewVisibility to false means you need to update isHidden property of this view by yourself.
    /// Setting automaticallyUpdateReferencedViewVisibility will also set referencedView isHidden property to false.
    /// Default value is true
    open var automaticallyUpdateReferencedViewVisibility = true {
        didSet {
            if !automaticallyUpdateReferencedViewVisibility {
                referencedView?.isHidden = false
            }
        }
    }

    /// Indicates where image should be scaled smaller when being dragged.
    /// Default value is true.
    open var scaleWhileDragging = true

    /// This variable sets original frame of image view to animate from
    open fileprivate(set) var referenceSize: CGSize = .zero

    /// This is the image view that is mainly used for the presentation and dismissal effect.
    /// How it animates from the original view to fullscreen and vice versa.
    public fileprivate(set) var imageView: UIImageView

    /// The view where photo viewer originally animates from.
    /// Provide this correctly so that you can have a nice effect.
    public internal(set) weak var referencedView: UIView? {
        didSet {
            // Unhide old referenced view and hide the new one
            oldValue?.isHidden = false
            if automaticallyUpdateReferencedViewVisibility {
                referencedView?.isHidden = true
            }
        }
    }

    /// Collection view.
    /// This will be used when displaying multiple images.
    fileprivate(set) var collectionView: UICollectionView
    public var scrollView: UIScrollView {
        collectionView
    }

    /// View used for fading effect during presentation and dismissal animation or when controller is being dragged.
    public internal(set) var backgroundView: UIView

    /// Pan gesture for dragging controller
    public internal(set) var panGestureRecognizer: UIPanGestureRecognizer!

    /// Double tap gesture
    public internal(set) var doubleTapGestureRecognizer: UITapGestureRecognizer!

    /// Single tap gesture
    public internal(set) var singleTapGestureRecognizer: UITapGestureRecognizer!

    fileprivate var _shouldHideStatusBar = false
    fileprivate var _shouldUseStatusBarStyle = false

    /// Transition animator
    /// Customizable if you wish to provide your own transitions.
    open lazy var animator: DTPhotoViewerBaseAnimator = DTPhotoAnimator()

    public init(referencedView: UIView?, image: UIImage?) {
        let flowLayout = DTCollectionViewFlowLayout()
        flowLayout.scrollDirection = scrollDirection
        flowLayout.sectionInset = UIEdgeInsets.zero
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0

        // Collection view
        collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: flowLayout)
        collectionView.register(DTPhotoCollectionViewCell.self, forCellWithReuseIdentifier: kPhotoCollectionViewCellIdentifier)
        collectionView.backgroundColor = UIColor.clear
        collectionView.isPagingEnabled = true

        backgroundView = UIView(frame: CGRect.zero)

        // Image view
        let newImageView = DTImageView(frame: CGRect.zero)
        imageView = newImageView

        super.init(nibName: nil, bundle: nil)

        transitioningDelegate = self

        imageView.image = image
        self.referencedView = referencedView
        collectionView.dataSource = self

        modalPresentationStyle = UIModalPresentationStyle.overFullScreen
        modalPresentationCapturesStatusBarAppearance = true

        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }

        hidesBottomBarWhenPushed = true
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func viewDidLoad() {
        if let view = referencedView {
            // Content mode should be identical between image view and reference view
            imageView.contentMode = view.contentMode
        }

        hidesBottomBarWhenPushed = true

        // Background view
        view.addSubview(backgroundView)
        backgroundView.alpha = 0
        backgroundView.backgroundColor = backgroundColor

        // Image view
        // Configure this block for changing image size when image changed
        (imageView as? DTImageView)?.imageChangeBlock = { [weak self] (image: UIImage?) in
            // Update image frame whenever image changes and when the imageView is not being visible
            // imageView is only being visible during presentation or dismissal
            // For that reason, we should not update frame of imageView no matter what.
            if let strongSelf = self, let image = image, strongSelf.imageView.isHidden == true {
                strongSelf.imageView.frame.size = strongSelf.imageViewSizeForImage(image)
                strongSelf.imageView.center = strongSelf.view.center

                // No datasource, only 1 item in collection view --> reloadData
                guard let _ = strongSelf.dataSource else {
                    strongSelf.collectionView.reloadData()
                    return
                }
            }
        }

        imageView.frame = frameForReferencedView()
        imageView.clipsToBounds = true

        // Scroll view
        scrollView.delegate = self
        view.addSubview(imageView)
        view.addSubview(scrollView)

        // Tap gesture recognizer
        singleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(_handleTapGesture))
        singleTapGestureRecognizer.numberOfTapsRequired = 1
        singleTapGestureRecognizer.numberOfTouchesRequired = 1

        // Pan gesture recognizer
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(_handlePanGesture))
        panGestureRecognizer.maximumNumberOfTouches = 1
        view.isUserInteractionEnabled = true

        // Double tap gesture recognizer
        doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(_handleDoubleTapGesture))
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        doubleTapGestureRecognizer.numberOfTouchesRequired = 1
        singleTapGestureRecognizer.require(toFail: doubleTapGestureRecognizer)

        scrollView.addGestureRecognizer(doubleTapGestureRecognizer)
        scrollView.addGestureRecognizer(singleTapGestureRecognizer)
        view.addGestureRecognizer(panGestureRecognizer)

        super.viewDidLoad()
    }

    override open func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        backgroundView.frame = view.bounds
        scrollView.frame = view.bounds

        // Update iamge view frame everytime view changes frame
        (imageView as? DTImageView)?.imageChangeBlock?(imageView.image)
    }

    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        // Update layout
        (collectionView.collectionViewLayout as? DTCollectionViewFlowLayout)?.currentIndex = currentPhotoIndex
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if !animated {
            presentingAnimation()
            presentationAnimationDidFinish()
        } else {
            presentationAnimationWillStart()
        }
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override open func viewWillDisappear(_ animated: Bool) {
        // Update image view before animation
        updateImageView(scrollView: scrollView)

        super.viewWillDisappear(animated)

        if !animated {
            dismissingAnimation()
            dismissalAnimationDidFinish()
        } else {
            dismissalAnimationWillStart()
        }
    }

    override open var prefersStatusBarHidden: Bool {
        if shouldHideStatusBarOnPresent {
            return _shouldHideStatusBar
        }
        return false
    }

    override open var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        statusBarAnimationStyle
    }

    override open var preferredStatusBarStyle: UIStatusBarStyle {
        if _shouldUseStatusBarStyle {
            return statusBarStyleOnPresenting
        }
        return statusBarStyleOnDismissing
    }

    // MARK: Private methods

    fileprivate func startAnimation() {
        // Hide reference image view
        if automaticallyUpdateReferencedViewVisibility {
            referencedView?.isHidden = true
        }

        // Animate to center
        _animateToCenter()
    }

    func _animateToCenter() {
        UIView.animate(withDuration: animator.presentingDuration, animations: {
            self.presentingAnimation()
        }) { _ in
            // Presenting animation ended
            self.presentationAnimationDidFinish()
        }
    }

    func _hideImageView(_ imageViewHidden: Bool) {
        // Hide image view should show collection view and vice versa
        imageView.isHidden = imageViewHidden
        scrollView.isHidden = !imageViewHidden
    }

    func _dismiss() {
        dismiss(animated: true, completion: nil)
    }

    @objc func _handleTapGesture(_: UITapGestureRecognizer) {
        // Method to override
        didReceiveTapGesture()

        // Delegate method
        delegate?.photoViewerControllerDidReceiveTapGesture?(self)
    }

    @objc func _handleDoubleTapGesture(_ gesture: UITapGestureRecognizer) {
        // Method to override
        didReceiveDoubleTapGesture()

        // Delegate method
        delegate?.photoViewerControllerDidReceiveDoubleTapGesture?(self)

        let indexPath = IndexPath(item: currentPhotoIndex, section: 0)

        if let cell = collectionView.cellForItem(at: indexPath) as? DTPhotoCollectionViewCell {
            // Double tap
            // imageViewerControllerDidDoubleTapImageView()

            if cell.scrollView.zoomScale == cell.scrollView.minimumZoomScale {
                let location = gesture.location(in: view)
                let center = cell.imageView.convert(location, from: view)

                // Zoom in
                cell.minimumZoomScale = 1.0
                let rect = zoomRect(for: cell.imageView, withScale: cell.scrollView.maximumZoomScale, withCenter: center)
                cell.scrollView.zoom(to: rect, animated: true)
            } else {
                // Zoom out
                cell.minimumZoomScale = 1.0
                cell.scrollView.setZoomScale(cell.scrollView.minimumZoomScale, animated: true)
            }
        }
    }

    private func frameForReferencedView() -> CGRect {
        if let referencedView = referencedView {
            if let superview = referencedView.superview {
                var frame = (superview.convert(referencedView.frame, to: view))

                if abs(frame.size.width - referencedView.frame.size.width) > 1 {
                    // This is workaround for bug in ios 8, everything is double.
                    frame = CGRect(x: frame.origin.x / 2, y: frame.origin.y / 2, width: frame.size.width / 2, height: frame.size.height / 2)
                }

                return frame
            }
        }

        // Work around when there is no reference view, dragging might behave oddly
        // Should be fixed in the future
        let defaultSize: CGFloat = 1
        return CGRect(x: view.frame.midX - defaultSize / 2, y: view.frame.midY - defaultSize / 2, width: defaultSize, height: defaultSize)
    }

    private func currentPhotoIndex(for scrollView: UIScrollView) -> Int {
        if scrollDirection == .horizontal {
            if scrollView.frame.width == 0 {
                return 0
            }
            if view.isRightToLeft() {
                return Int(round((scrollView.contentSize.width - scrollView.frame.width - scrollView.contentOffset.x) / scrollView.frame.width))
            } else {
                return Int(round(scrollView.contentOffset.x / scrollView.frame.width))
            }
        } else {
            if scrollView.frame.height == 0 {
                return 0
            }
            return Int(scrollView.contentOffset.y / scrollView.frame.height)
        }
    }

    // Update zoom inside UICollectionViewCell
    fileprivate func _updateZoomScaleForSize(cell: DTPhotoCollectionViewCell, size: CGSize) {
        let widthScale = size.width / cell.imageView.bounds.width
        let heightScale = size.height / cell.imageView.bounds.height
        let zoomScale = min(widthScale, heightScale)

        cell.maximumZoomScale = zoomScale
    }

    fileprivate func zoomRect(for imageView: UIImageView, withScale scale: CGFloat, withCenter center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero

        // The zoom rect is in the content view's coordinates.
        // At a zoom scale of 1.0, it would be the size of the
        // imageScrollView's bounds.
        // As the zoom scale decreases, so more content is visible,
        // the size of the rect grows.
        zoomRect.size.height = imageView.frame.size.height / scale
        zoomRect.size.width = imageView.frame.size.width / scale

        // choose an origin so as to get the right center.
        zoomRect.origin.x = center.x - (zoomRect.size.width / 2.0)
        zoomRect.origin.y = center.y - (zoomRect.size.height / 2.0)

        return zoomRect
    }

    @objc func _handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        if let gestureView = gesture.view {
            switch gesture.state {
            case .began:

                // Delegate method
                delegate?.photoViewerController?(self, willBeginPanGestureRecognizer: panGestureRecognizer)

                // Update image view when starting to drag
                updateImageView(scrollView: scrollView)

                // Make status bar visible when beginning to drag image view
                updateStatusBar(isHidden: false, defaultStatusBarStyle: false)

                // Hide collection view & display image view
                _hideImageView(false)

                // Method to override
                willBegin(panGestureRecognizer: panGestureRecognizer)

            case .changed:
                let translation = gesture.translation(in: gestureView)
                imageView.center = CGPoint(x: view.center.x + translation.x, y: view.center.y + translation.y)

                // Change opacity of background view based on vertical distance from center
                let yDistance = CGFloat(abs(imageView.center.y - view.center.y))
                var alpha = 1.0 - yDistance / (gestureView.center.y)

                if alpha < 0 {
                    alpha = 0
                }

                backgroundView.alpha = alpha

                // Scale image
                // Should not go smaller than max ratio
                if let image = imageView.image, scaleWhileDragging {
                    let referenceSize = frameForReferencedView().size

                    // If alpha = 0, then scale is max ratio, if alpha = 1, then scale is 1
                    let scale = alpha

                    // imageView.transform = CGAffineTransformMakeScale(scale, scale)
                    // Do not use transform to scale down image view
                    // Instead change width & height
                    if scale < 1, scale >= 0 {
                        let maxSize = imageViewSizeForImage(image)
                        let scaleSize = CGSize(width: maxSize.width * scale, height: maxSize.height * scale)

                        if scaleSize.width >= referenceSize.width || scaleSize.height >= referenceSize.height {
                            imageView.frame.size = scaleSize
                        }
                    }
                }

            default:
                // Animate back to center
                if backgroundView.alpha < 0.8 {
                    _dismiss()
                } else {
                    _animateToCenter()
                }

                // Method to override
                didEnd(panGestureRecognizer: panGestureRecognizer)

                // Delegate method
                delegate?.photoViewerController?(self, didEndPanGestureRecognizer: panGestureRecognizer)
            }
        }
    }

    private func imageViewSizeForImage(_ image: UIImage?) -> CGSize {
        if let image = image {
            let rect = AVMakeRect(aspectRatio: image.size, insideRect: view.bounds)
            return rect.size
        }

        return CGSize.zero
    }

    func presentingAnimation() {
        // Hide reference view
        if automaticallyUpdateReferencedViewVisibility {
            referencedView?.isHidden = true
        }

        // Calculate final frame
        var destinationFrame = CGRect.zero
        destinationFrame.size = imageViewSizeForImage(imageView.image)

        // Animate image view to the center
        imageView.frame = destinationFrame
        imageView.center = view.center

        // Change status bar to black style
        updateStatusBar(isHidden: true, defaultStatusBarStyle: true)

        // Animate background alpha
        backgroundView.alpha = 1.0
    }

    private func updateStatusBar(isHidden: Bool, defaultStatusBarStyle isDefaultStyle: Bool) {
        _shouldUseStatusBarStyle = isDefaultStyle
        _shouldHideStatusBar = isHidden
        setNeedsStatusBarAppearanceUpdate()
    }

    func dismissingAnimation() {
        imageView.frame = frameForReferencedView()
        backgroundView.alpha = 0
    }

    func presentationAnimationDidFinish() {
        // Method to override
        didEndPresentingAnimation()

        // Delegate method
        delegate?.photoViewerControllerDidEndPresentingAnimation?(self)

        // Hide animating image view and show collection view
        _hideImageView(true)
    }

    func presentationAnimationWillStart() {
        // Hide collection view and show image view
        _hideImageView(false)
    }

    func dismissalAnimationWillStart() {
        // Hide collection view and show image view
        _hideImageView(false)
    }

    func dismissalAnimationDidFinish() {
        if automaticallyUpdateReferencedViewVisibility {
            referencedView?.isHidden = false
        }
    }

    // MARK: Public behavior methods

    open func didScrollToPhoto(at _: Int) {}

    open func didZoomOnPhoto(at _: Int, atScale _: CGFloat) {}

    open func didEndZoomingOnPhoto(at _: Int, atScale _: CGFloat) {}

    open func willZoomOnPhoto(at _: Int) {}

    open func didReceiveTapGesture() {}

    open func didReceiveDoubleTapGesture() {}

    open func willBegin(panGestureRecognizer _: UIPanGestureRecognizer) {}

    open func didEnd(panGestureRecognizer _: UIPanGestureRecognizer) {}

    open func didEndPresentingAnimation() {}
}

// MARK: - UIViewControllerTransitioningDelegate

extension DTPhotoViewerController: UIViewControllerTransitioningDelegate {
    public func animationController(forPresented _: UIViewController, presenting _: UIViewController, source _: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        animator
    }

    public func animationController(forDismissed _: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        animator
    }
}

// MARK: UICollectionViewDataSource

extension DTPhotoViewerController: UICollectionViewDataSource {
    // MARK: Public methods

    public var currentPhotoIndex: Int {
        currentPhotoIndex(for: scrollView)
    }

    public var zoomScale: CGFloat {
        let index = currentPhotoIndex
        let indexPath = IndexPath(item: index, section: 0)

        if let cell = collectionView.cellForItem(at: indexPath) as? DTPhotoCollectionViewCell {
            return cell.scrollView.zoomScale
        }

        return 1.0
    }

    public func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        if let dataSource = dataSource {
            return dataSource.numberOfItems(in: self)
        }
        return 1
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kPhotoCollectionViewCellIdentifier, for: indexPath) as! DTPhotoCollectionViewCell
        cell.delegate = self

        if let dataSource = dataSource {
            if dataSource.numberOfItems(in: self) > 0 {
                dataSource.photoViewerController(self, configurePhotoAt: indexPath.row, withImageView: cell.imageView)
                dataSource.photoViewerController?(self, configureCell: cell, forPhotoAt: indexPath.row)

                return cell
            }
        }

        cell.imageView.image = imageView.image
        return cell
    }
}

// MARK: Open methods

extension DTPhotoViewerController {
    // For each reuse identifier that the collection view will use, register either a class or a nib from which to instantiate a cell.
    // If a nib is registered, it must contain exactly 1 top level object which is a DTPhotoCollectionViewCell.
    // If a class is registered, it will be instantiated via alloc/initWithFrame:
    open func registerClassPhotoViewer(_ cellClass: Swift.AnyClass?) {
        collectionView.register(cellClass, forCellWithReuseIdentifier: kPhotoCollectionViewCellIdentifier)
    }

    open func registerNibForPhotoViewer(_ nib: UINib?) {
        collectionView.register(nib, forCellWithReuseIdentifier: kPhotoCollectionViewCellIdentifier)
    }

    // Update data before calling theses methods
    open func reloadData() {
        collectionView.reloadData()
    }

    open func insertPhotos(at indexes: [Int], completion: ((Bool) -> Void)?) {
        let indexPaths = indexPathsForIndexes(indexes: indexes)

        collectionView.performBatchUpdates({
            self.collectionView.insertItems(at: indexPaths)
        }, completion: completion)
    }

    open func deletePhotos(at indexes: [Int], completion: ((Bool) -> Void)?) {
        let indexPaths = indexPathsForIndexes(indexes: indexes)

        collectionView.performBatchUpdates({
            self.collectionView.deleteItems(at: indexPaths)
        }, completion: completion)
    }

    open func reloadPhotos(at indexes: [Int]) {
        let indexPaths = indexPathsForIndexes(indexes: indexes)

        collectionView.reloadItems(at: indexPaths)
    }

    open func movePhoto(at index: Int, to newIndex: Int) {
        let indexPath = IndexPath(item: index, section: 0)
        let newIndexPath = IndexPath(item: newIndex, section: 0)

        collectionView.moveItem(at: indexPath, to: newIndexPath)
    }

    open func scrollToPhoto(at index: Int, animated: Bool) {
        if collectionView.numberOfItems(inSection: 0) > index {
            let indexPath = IndexPath(item: index, section: 0)

            let position: UICollectionView.ScrollPosition

            if scrollDirection == .vertical {
                position = .bottom
            } else {
                position = .right
            }

            collectionView.scrollToItem(at: indexPath, at: position, animated: animated)

            if !animated {
                // Need to call these methods since scrollView delegate method won't be called when not animated
                // Method to override
                didScrollToPhoto(at: index)

                // Call delegate
                delegate?.photoViewerController?(self, didScrollToPhotoAt: index)
            }
        }
    }

    // Helper for indexpaths
    func indexPathsForIndexes(indexes: [Int]) -> [IndexPath] {
        indexes.map {
            IndexPath(item: $0, section: 0)
        }
    }
}

// MARK: DTPhotoCollectionViewCellDelegate

extension DTPhotoViewerController: DTPhotoCollectionViewCellDelegate {
    open func collectionViewCellDidZoomOnPhoto(_ cell: DTPhotoCollectionViewCell, atScale scale: CGFloat) {
        if let indexPath = collectionView.indexPath(for: cell) {
            // Method to override
            didZoomOnPhoto(at: indexPath.row, atScale: scale)

            // Call delegate
            delegate?.photoViewerController?(self, didZoomOnPhotoAtIndex: indexPath.row, atScale: scale)
        }
    }

    open func collectionViewCellDidEndZoomingOnPhoto(_ cell: DTPhotoCollectionViewCell, atScale scale: CGFloat) {
        if let indexPath = collectionView.indexPath(for: cell) {
            // Method to override
            didEndZoomingOnPhoto(at: indexPath.row, atScale: scale)

            // Call delegate
            delegate?.photoViewerController?(self, didEndZoomingOnPhotoAtIndex: indexPath.row, atScale: scale)
        }
    }

    open func collectionViewCellWillZoomOnPhoto(_ cell: DTPhotoCollectionViewCell) {
        if let indexPath = collectionView.indexPath(for: cell) {
            // Method to override
            willZoomOnPhoto(at: indexPath.row)

            // Call delegate
            delegate?.photoViewerController?(self, willZoomOnPhotoAtIndex: indexPath.row)
        }
    }
}
