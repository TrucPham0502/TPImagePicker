//
//  ImagePickerController.swift
//
//  Created by Truc Pham on 9/15/20.
//  Copyright © 2021 Truc Pham (VN). All rights reserved.
//


import UIKit

@objc
protocol ImageCarouselViewControllerDelegate {
    @objc optional func imageViewer(_ controller : ImageCarouselViewController, viewer : ImageViewerController, viewDidLoad index : Int)
    @objc optional func imageViewer(_ controller : ImageCarouselViewController, viewer : ImageViewerController, viewDidDisappear index : Int)
    @objc optional func imageViewer(_ controller : ImageCarouselViewController, viewer : ImageViewerController, didClose index: Int)
    @objc optional func imageViewer(_ controller : ImageCarouselViewController, viewer : ImageViewerController, viewDidAppear index: Int)
    func imageViewer(_ view : ImageCarouselViewController, sourceView index : Int) -> UIImageView?
}

protocol ImageDataSource {
    func numberOfImages() -> Int
    func imageItem(at index:Int) -> ImageItem
    func removeItem(at index: Int)
}

class ImageCarouselViewController : UIPageViewController {
    weak var imageCarouselViewDelegate : ImageCarouselViewControllerDelegate?
    var imageDatasource:ImageDataSource?
    var index = 0
    var sourceView : UIImageView? {
        return imageCarouselViewDelegate?.imageViewer(self, sourceView: index)
    }
    var theme:ImageViewerTheme = .light {
        didSet {
            backgroundView.backgroundColor = theme.color
        }
    }
    
    var currentPage : ImageViewerController? {
        self.viewControllers?.first as? ImageViewerController
    }
    
    var options:[ImageViewerOption] = []
    
    var navBar: UIView? {
        didSet {
            addNavBar()
        }
    }
    
    private(set) lazy var backgroundView: UIView = {
        let _v = UIView()
        _v.backgroundColor = theme.color
        _v.alpha = 0.0
        return _v
    }()
    var footerView: UIView? {
        didSet {
            addFooter()
        }
    }
    
    static func create(
        imageDataSource: ImageDataSource?,
        options:[ImageViewerOption] = [],
        initialIndex:Int = 0) -> ImageCarouselViewController {
        
        let pageOptions = [UIPageViewController.OptionsKey.interPageSpacing: 20]
        
        let imageCarousel = ImageCarouselViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: pageOptions)
        
        imageCarousel.modalPresentationStyle = .overFullScreen
        imageCarousel.modalPresentationCapturesStatusBarAppearance = true
        
        imageCarousel.imageDatasource = imageDataSource
        imageCarousel.options = options
        imageCarousel.index = initialIndex
        
        return imageCarousel
    }
    
    private func addNavBar() {
        if let nav = navBar {
            nav.removeFromSuperview()
            nav.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(nav)
            NSLayoutConstraint.activate([
                nav.topAnchor.constraint(equalTo: self.view.topAnchor),
                nav.heightAnchor.constraint(equalToConstant: 80),
                nav.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                nav.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
            ])
        }
    }

    
    private func addBackgroundView() {
        view.addSubview(backgroundView)
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
        backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
        view.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor, constant: 0).isActive = true
        view.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: 0).isActive = true
        view.sendSubviewToBack(backgroundView)
    }
    private func addFooter()
    {
        if let footer = footerView {
            footer.removeFromSuperview()
            footer.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(footer)
            NSLayoutConstraint.activate([
                footer.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
                footer.heightAnchor.constraint(equalToConstant: 80),
                footer.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                footer.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
            ])
        }
    }
    
    func deletePhotoSuccess()
    {
        guard let page = currentPage else {
            dismiss(animated: true, completion: nil)
            return
        }
        guard let imageDatasource = imageDatasource else { return }
        imageDatasource.removeItem(at: page.index)
        if imageDatasource.numberOfImages() == 0
        {
            dismiss(animated: true, completion: nil)
            return
        }
        let newIndex = page.index > imageDatasource.numberOfImages() - 1 ? page.index - 1 : page.index
        let newPage = ImageViewerController.create(
            index: newIndex,
            imageItem:  imageDatasource.imageItem(at: newIndex),
            sourceView: sourceView,
            delegate: self)
        setViewControllers([newPage], direction: .forward, animated: true, completion: nil)
    }
    
    
    func downHandler() {
        guard let page = currentPage else { return }
        guard let item = self.imageDatasource?.imageItem(at: page.index) else {
            return
        }
        var image : UIImage?
        switch item {
        case .image(let img):
            image = img
            break
        case .url(_, placeholder: let placeholder):
            image = placeholder
            break
        default:
            break
        }
        if let image = image {
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(savedImage), nil)
        }
    }

    @objc
    func savedImage(_ im:UIImage, error:Error?, context:UnsafeMutableRawPointer?) {
        if let err = error {
            print(err)
            return
        }
    }
    
    private func applyOptions() {
        options.forEach {
            switch $0 {
            case .theme(let theme):
                self.theme = theme
            case .delegate(let delegate):
                self.imageCarouselViewDelegate = delegate
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addBackgroundView()
        applyOptions()
        
        view.backgroundColor = .clear
        dataSource = self
        
        let initialVC = ImageViewerController(sourceView: sourceView)
        initialVC.index = index
        if let imageDatasource = imageDatasource {
            initialVC.imageItem = imageDatasource.imageItem(at: index)
        } else {
            initialVC.imageItem = .image(sourceView?.image)
        }
        initialVC.animateOnDidAppear = true
        initialVC.delegate = self
        setViewControllers([initialVC], direction: .forward, animated: true, completion: nil)
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animate(withDuration: 0.235) {
            self.navBar?.alpha = 1.0
            self.footerView?.alpha = 1.0
        }
    }
    
    @objc
    private func dismiss(_ sender: Any) {
        dismissMe(completion: nil)
    }
    
    public func dismissMe(completion: (() -> Void)? = nil) {
        sourceView?.alpha = 1.0
        UIView.animate(withDuration: 0.235, animations: {
            self.view.alpha = 0.0
        }) { _ in
            self.dismiss(animated: false, completion: completion)
        }
    }
    
    override public var preferredStatusBarStyle: UIStatusBarStyle {
        if theme == .dark {
            return .lightContent
        }
        return .default
    }
}

extension ImageCarouselViewController:UIPageViewControllerDataSource {
    public func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        guard let vc = viewController as? ImageViewerController else { return nil }
        guard let imageDatasource = imageDatasource else { return nil }
        if imageDatasource.numberOfImages() == 0
        {
            return nil
        }
        guard vc.index > 0 else { return nil }
        
        let newIndex = vc.index - 1
        index = newIndex
        return ImageViewerController.create(
            index: newIndex,
            imageItem:  imageDatasource.imageItem(at: newIndex),
            sourceView: sourceView,
            delegate: self)
    }
    
    public func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        guard let vc = viewController as? ImageViewerController else { return nil }
        guard let imageDatasource = imageDatasource else {
            return nil
        }
        if imageDatasource.numberOfImages() == 0
        {
            return nil
        }
        guard vc.index <= (imageDatasource.numberOfImages() - 2) else { return nil }
        
        let newIndex = vc.index + 1
        index = newIndex
        return ImageViewerController.create(
            index: newIndex,
            imageItem:  imageDatasource.imageItem(at: newIndex),
            sourceView: sourceView,
            delegate: self)
    }
    
}

extension ImageCarouselViewController : ImageViewerControllerDelegate {
    func imageViewer(_ imageViewer: ImageViewerController, viewDidLoad index: Int) {
        imageCarouselViewDelegate?.imageViewer?(self, viewer: imageViewer, viewDidLoad: index)
    }
    func imageViewer(_ imageViewer: ImageViewerController, viewDidDisappear index: Int) {
        imageCarouselViewDelegate?.imageViewer?(self, viewer: imageViewer, viewDidDisappear: index)
    }
    func imageViewer(_ imageViewer: ImageViewerController, didClose index: Int) {
        imageCarouselViewDelegate?.imageViewer?(self, viewer: imageViewer, didClose: index)
    }
    
    func imageViewer(_ imageViewer: ImageViewerController, viewDidAppear index: Int) {
        imageCarouselViewDelegate?.imageViewer?(self, viewer: imageViewer, viewDidAppear: index)
    }
}
