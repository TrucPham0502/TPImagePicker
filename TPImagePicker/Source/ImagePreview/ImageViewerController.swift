//
//  ImagePickerController.swift
//
//  Created by Truc Pham on 9/15/20.
//  Copyright © 2021 Truc Pham (VN). All rights reserved.
//


import UIKit
import AVKit
import Photos
import PhotosUI
@objc
protocol ImageViewerControllerDelegate {
    @objc optional func imageViewer(_ imageViewer: ImageViewerController, didClose index : Int)
    @objc optional func imageViewer(_ imageViewer: ImageViewerController, viewDidLoad index : Int)
    @objc optional func imageViewer(_ imageViewer: ImageViewerController, viewDidDisappear index : Int)
    @objc optional func imageViewer(_ imageViewer: ImageViewerController, viewDidAppear index : Int)
    
}

class ImageViewerController:UIViewController, UIGestureRecognizerDelegate {
    
    var index:Int = 0
    weak var delegate:ImageViewerControllerDelegate?
    var imageItem: ImageItem!
    var animateOnDidAppear:Bool = false
    var sourceView : UIImageView?
    var videoPlayer : AVPlayer?
    var backgroundView:UIView? {
        guard let _parent = parent as? ImageCarouselViewController
            else { return nil}
        return _parent.backgroundView
    }
    var footerView : UIView? {
        guard let _parent = parent as? ImageCarouselViewController
            else { return nil}
        return _parent.footerView
    }
    var navBar: UIView? {
        guard let _parent = parent as? ImageCarouselViewController
            else { return nil}
        return _parent.navBar
    }
    
    // MARK: Layout Constraints
    private var top:NSLayoutConstraint!
    private var leading:NSLayoutConstraint!
    private var trailing:NSLayoutConstraint!
    private var bottom:NSLayoutConstraint!
    
    private var imageView:UIImageView!
    private var scrollView:UIScrollView!
   
    private var lastLocation:CGPoint = .zero
    private var isAnimating:Bool = false
    private var maxZoomScale:CGFloat = 1.0
    
    /// custom max zoom
    var maxSizeAddition : CGSize = .init(width: 500, height: 500)
    
    init(sourceView:UIImageView? = nil) {
        super.init(nibName: nil, bundle: nil)
        self.sourceView = sourceView
     
        modalPresentationStyle = .overFullScreen
        modalPresentationCapturesStatusBarAppearance = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let view = UIView()
        
        view.backgroundColor = .clear
        self.view = view
        
        scrollView = UIScrollView()
        scrollView.delegate = self
        scrollView.showsVerticalScrollIndicator = false
      
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        } else {
            // Fallback on earlier versions
        }
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
        scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
        view.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 0).isActive = true
        view.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: 0).isActive = true
        
        scrollView.backgroundColor = .clear
        
        imageView = UIImageView(frame: .zero)
        scrollView.addSubview(imageView)
        
        imageView.isUserInteractionEnabled = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        top = imageView.topAnchor.constraint(equalTo: scrollView.topAnchor)
        leading = imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor)
        trailing = scrollView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor)
        bottom = scrollView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor)
        
        top.isActive = true
        leading.isActive = true
        trailing.isActive = true
        bottom.isActive = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        switch imageItem {
        case .image(let img):
            imageView.image = img
            imageView.layoutIfNeeded()
        case .url(let url, let placeholder):
            imageView.image = placeholder
//            imageView.sd_setImage(
//                with: url,
//                placeholderImage: placeholder ?? sourceView?.image,
//                options: [],
//                progress: nil) {[weak self] (img, err, type, url) in
//                    DispatchQueue.main.async {
//                        UIView.performWithoutAnimation {
//                            self?.imageView.layoutIfNeeded()
//
//                        }
//                    }
//                }
        case let .asset(asset, placeholder):
            imageView.image = placeholder
            imageView.layoutIfNeeded()
            if let asset = asset {
                switch asset.mediaType {
                case .image:
                    switch asset.mediaSubType {
                    case .photoLive:
                        asset.requestLivePhoto { (live) in
                            let photoView = PHLivePhotoView(frame: self.imageView.bounds)
                            photoView.livePhoto = live
                            photoView.contentMode = .scaleAspectFit
                            self.imageView.addSubview(photoView)
                        }
                    default:
                        asset.requestFullSizePhoto(progress: { pro, stop, error in
                            print(pro)  
                        }, complete: {[weak self] (image) in
                            self?.imageView.image = image
                        })
                    }
                    
                case .video:
                    asset.requestAVAsset { (avasset) in
                        if let avasset = avasset {
                            let playerItem = AVPlayerItem(asset: avasset)
                            self.videoPlayer = AVPlayer(playerItem: playerItem)
                            let playerLayer = AVPlayerLayer(player: self.videoPlayer)
                            playerLayer.frame = self.imageView.bounds
                            playerLayer.videoGravity = .resizeAspect
                            self.imageView.layer.addSublayer(playerLayer)
                            self.videoPlayer?.play()
                        }
                    }
                default:
                    break
                }
               
            }
            
        default:
            break
        }
        
        addGestureRecognizers()
        self.delegate?.imageViewer?(self, viewDidLoad: index)
    }
    

    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.sourceView?.alpha = 1.0
        self.delegate?.imageViewer?(self, viewDidDisappear: self.index)
        self.videoPlayer?.pause()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.sourceView?.layer.opacity = 0.0
        self.videoPlayer?.play()
        self.delegate?.imageViewer?(self, viewDidAppear: index)
        guard animateOnDidAppear == true else {
            // skip animation
            return
        }
        animateOnDidAppear = false
        executeOpeningAnimation()
        
        
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updateConstraintsForSize(view.bounds.size)
        updateMinMaxZoomScaleForSize(view.bounds.size)
    }
    
    // MARK: Add Gesture Recognizers
    func addGestureRecognizers() {
        
        let panGesture = UIPanGestureRecognizer(
            target: self, action: #selector(didPan(_:)))
        panGesture.cancelsTouchesInView = false
        panGesture.delegate = self
        scrollView.addGestureRecognizer(panGesture)

        let pinchRecognizer = UITapGestureRecognizer(
            target: self, action: #selector(didPinch(_:)))
        pinchRecognizer.numberOfTapsRequired = 1
        pinchRecognizer.numberOfTouchesRequired = 2
        scrollView.addGestureRecognizer(pinchRecognizer)
        
        let singleTapGesture = UITapGestureRecognizer(
            target: self, action: #selector(didSingleTap(_:)))
        singleTapGesture.numberOfTapsRequired = 1
        singleTapGesture.numberOfTouchesRequired = 1
        scrollView.addGestureRecognizer(singleTapGesture)
        
        let doubleTapRecognizer = UITapGestureRecognizer(
            target: self, action: #selector(didDoubleTap(_:)))
        doubleTapRecognizer.numberOfTapsRequired = 2
        doubleTapRecognizer.numberOfTouchesRequired = 1
        scrollView.addGestureRecognizer(doubleTapRecognizer)
       
        singleTapGesture.require(toFail: doubleTapRecognizer)
    }
    
    @objc
    func didPan(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard
            isAnimating == false,
            scrollView.zoomScale == scrollView.minimumZoomScale
            else { return }
        
        let container:UIView! = imageView
        if gestureRecognizer.state == .began {
            navBar?.alpha = 0
            footerView?.alpha = 0
            lastLocation = container.center
        }
        
        if gestureRecognizer.state != .cancelled {
            let translation: CGPoint = gestureRecognizer
                .translation(in: view)
            container.center = CGPoint(
                x: lastLocation.x + translation.x,
                y: lastLocation.y + translation.y)
        }

        let diffY = view.center.y - container.center.y
        let alpha = 1.0 - abs(diffY/view.center.y)
        backgroundView?.alpha = alpha
        if gestureRecognizer.state == .ended {
            if abs(diffY) > 60 {
                executeViewDismissalAnimation(diffY)
            } else {
                executeCancelAnimation()
            }
        }
    }
    
    @objc
    func didPinch(_ recognizer: UITapGestureRecognizer) {
        var newZoomScale = scrollView.zoomScale / 1.5
        newZoomScale = max(newZoomScale, scrollView.minimumZoomScale)
        scrollView.setZoomScale(newZoomScale, animated: true)
    }
    
    @objc
    func didSingleTap(_ recognizer: UITapGestureRecognizer) {
        
        let currentNavAlpha = self.navBar?.alpha ?? 0.0
        UIView.animate(withDuration: 0.235) {
            self.navBar?.alpha = currentNavAlpha > 0.5 ? 0.0 : 1.0
            self.footerView?.alpha = currentNavAlpha > 0.5 ? 0.0 : 1.0
        }
    }
    
    @objc
    func didDoubleTap(_ recognizer:UITapGestureRecognizer) {
        let pointInView = recognizer.location(in: imageView)
        zoomInOrOut(at: pointInView)
    }

    func gestureRecognizerShouldBegin(
        _ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard scrollView.zoomScale == scrollView.minimumZoomScale,
            let panGesture = gestureRecognizer as? UIPanGestureRecognizer else { return false }

        let velocity = panGesture.velocity(in: scrollView)
        return abs(velocity.y) > abs(velocity.x)
    }
}

// MARK: Adjusting the dimensions
extension ImageViewerController {
    
    func updateMinMaxZoomScaleForSize(_ size: CGSize) {
        if imageView.bounds.width == 0 || imageView.bounds.height == 0 {
            return
        }
        
        let minScale = min(
            size.width/imageView.bounds.width,
            size.height/imageView.bounds.height)
        let maxScale = max(
            (size.width + maxSizeAddition.width) / imageView.bounds.width,
            (size.height + maxSizeAddition.height) / imageView.bounds.height)
        
        scrollView.minimumZoomScale = minScale
        scrollView.zoomScale = minScale
        maxZoomScale = maxScale
        scrollView.maximumZoomScale = maxZoomScale * 1.1
    }
    
    
    func zoomInOrOut(at point:CGPoint) {
        let newZoomScale = scrollView.zoomScale == scrollView.minimumZoomScale
            ? maxZoomScale : scrollView.minimumZoomScale
        let size = scrollView.bounds.size
        let w = size.width / newZoomScale
        let h = size.height / newZoomScale
        let x = point.x - (w * 0.5)
        let y = point.y - (h * 0.5)
        let rect = CGRect(x: x, y: y, width: w, height: h)
        scrollView.zoom(to: rect, animated: true)
    }
    
    func updateConstraintsForSize(_ size: CGSize) {
        let yOffset = max(0, (size.height - imageView.frame.height) / 2)
        top.constant = yOffset
        bottom.constant = yOffset
        
        let xOffset = max(0, (size.width - imageView.frame.width) / 2)
        leading.constant = xOffset
        trailing.constant = xOffset
        view.layoutIfNeeded()
    }

}

// MARK: Animation Related stuff
extension ImageViewerController {
    
    private func executeOpeningAnimation() {
        
        guard let _sourceView = sourceView else { return }
        
        let dummyImageView:UIImageView = UIImageView(
            frame: _sourceView.convert(_sourceView.bounds, to: nil))
        dummyImageView.clipsToBounds = true
        dummyImageView.contentMode = .scaleAspectFill
        dummyImageView.alpha = 1.0
        dummyImageView.image = imageView.image
        view.addSubview(dummyImageView)
        view.sendSubviewToBack(dummyImageView)
        
        _sourceView.alpha = 1.0
        imageView.alpha = 0.0
        backgroundView?.alpha = 0.0
        isAnimating = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {[weak self] in
            guard let _self = self else { return }
            UIView.animate(withDuration: 0.237, animations: {
                dummyImageView.contentMode = .scaleAspectFit
                dummyImageView.frame = _self.view.frame
                _self.backgroundView?.alpha = 1.0
                _sourceView.alpha = 0.0
            }) { _ in
                _self.imageView.alpha = 1.0
                dummyImageView.removeFromSuperview()
                _self.isAnimating = false
            }
        }
    }
    
    private func executeCancelAnimation() {
        self.isAnimating = true
        UIView.animate(
            withDuration: 0.237,
            animations: {
                self.imageView.center = self.view.center
                self.backgroundView?.alpha = 1.0
        }) {[weak self] _ in
            self?.isAnimating = false
        }
    }
    
    private func executeViewDismissalAnimation(_ diffY:CGFloat) {
        isAnimating = true
        
        let dummyImageView:UIImageView = UIImageView(frame: imageView.frame)
        dummyImageView.image = imageView.image
        dummyImageView.clipsToBounds = false
        dummyImageView.contentMode = .scaleAspectFill
        view.addSubview(dummyImageView)
        imageView.isHidden = true
        
        let exitFrame:CGRect = { () -> CGRect in
            guard let _sourceFrame = self.sourceView?.convert(self.sourceView?.bounds ?? .zero, to: nil)
                else {
                    var imageViewFrame = self.imageView.frame
                    if diffY > 0 {
                        imageViewFrame.origin.y = -imageViewFrame.size.height
                    } else {
                        imageViewFrame.origin.y = view.frame.size.height
                    }
                    return imageViewFrame
            }
            return _sourceFrame
        }()
        
        UIView.animate(withDuration: 0.237, animations: {
            dummyImageView.frame = exitFrame
            dummyImageView.clipsToBounds = true
            self.backgroundView?.alpha = 0.0
            self.navBar?.alpha = 0.0
        }) { success in
            self.dismiss(animated: false) {
                dummyImageView.removeFromSuperview()
                self.sourceView?.alpha = 1.0
                self.delegate?.imageViewer?(self, didClose: self.index)
            }
        }
    }
}

extension ImageViewerController:UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        updateConstraintsForSize(view.bounds.size)
    }
}


// MARK: Shortcuts
extension ImageViewerController {
    static func create(
        index: Int,
        imageItem:ImageItem,
        sourceView:UIImageView?,
        delegate:ImageViewerControllerDelegate) -> ImageViewerController {
        
        let newVC = ImageViewerController()
        newVC.index = index
        newVC.imageItem = imageItem
        newVC.sourceView = sourceView
        newVC.delegate = delegate
        return newVC
    }
}

