//
//  ImagePickerController.swift
//
//  Created by Truc Pham on 9/15/20.
//  Copyright © 2021 Truc Pham (VN). All rights reserved.
//

import Foundation
import UIKit



class PopoverViewController: UIViewController {
    
   static func popoverViewController(_ viewController: UIViewController,
                                                fromView: UIView) {
        let window = UIApplication.shared.keyWindow!
        
        let popoverViewController = PopoverViewController()
        popoverViewController.contentViewController = viewController
        popoverViewController.fromView = fromView
        
        popoverViewController.showInView(window)
        window.rootViewController!.addChild(popoverViewController)
    }
    
    static func dismissPopoverViewController() {
        let window = UIApplication.shared.keyWindow!
        
        for vc in window.rootViewController!.children {
            if vc is PopoverViewController {
                (vc as! PopoverViewController).dismiss()
            }
        }
    }
    
    private class PopoverView: UIView {
        
        var contentView: UIView! {
            didSet {
                self.contentView.layer.cornerRadius = 5
                self.contentView.clipsToBounds = true
                self.contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                self.addSubview(self.contentView)
            }
        }
        
        let arrowWidth: CGFloat = 20
        let arrowHeight: CGFloat = 10
        var arrowColor : UIColor {
            if #available(iOS 13, *) {
                return UIColor.systemGray6
            } else {
                return UIColor.white
            }
        }
        var arrowOffset = CGPoint.zero
        
        fileprivate let arrowImageView: UIImageView = UIImageView()
        
        init() {
            super.init(frame: CGRect.zero)
            self.commonInit()
        }
        
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            self.commonInit()
        }
        
        func commonInit() {
            self.arrowImageView.image = self.arrowImage()
            self.addSubview(self.arrowImageView)
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            self.arrowImageView.frame = CGRect(x: (self.bounds.width - self.arrowWidth) / 2 + self.arrowOffset.x,
                                               y: self.arrowOffset.y,
                                               width: self.arrowWidth, height: self.arrowHeight)
            self.contentView.frame = CGRect(x: 0, y: self.arrowHeight, width: self.bounds.width,
                                            height: self.bounds.height - self.arrowHeight)
        }
        
        func arrowImage() -> UIImage {
            UIGraphicsBeginImageContextWithOptions(CGSize(width: arrowWidth, height: arrowHeight), false, UIScreen.main.scale)
            
            let context = UIGraphicsGetCurrentContext()
            UIColor.clear.setFill()
            context?.fill(CGRect(x: 0, y: 0, width: arrowWidth, height: arrowHeight))
            
            let arrowPath = CGMutablePath()
            
            arrowPath.move(to: CGPoint(x: self.arrowWidth / 2, y: 0))
            arrowPath.addLine(to: CGPoint(x: self.arrowWidth, y: self.arrowHeight))
            arrowPath.addLine(to: CGPoint(x: 0, y: self.arrowHeight))
            arrowPath.closeSubpath()
            
            context?.addPath(arrowPath)
            
            context?.setFillColor(self.arrowColor.cgColor)
            context?.drawPath(using: CGPathDrawingMode.fill)
            
            let arrowImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return arrowImage!
        }
    }
    
    
    private var contentViewController: UIViewController!
    private var fromView: UIView!
    private var popoverView: PopoverView!
    
    // MARK: - Observers
    
    private var preferredContentSizeObserver: NSKeyValueObservation?
    
    override func loadView() {
        super.loadView()
        
        let backgroundView = UIControl(frame: self.view.frame)
        backgroundView.backgroundColor = UIColor.clear
        backgroundView.addTarget(self, action: #selector(dismiss as () -> Void), for: .touchUpInside)
        backgroundView.autoresizingMask = self.view.autoresizingMask
        self.view = backgroundView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor(white: 0, alpha: 0.6)
        self.popoverView = PopoverView()
        self.view.addSubview(self.popoverView)
    }
    
    @available(iOS, deprecated: 8.0)
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        super.didRotate(from: fromInterfaceOrientation)
        
        UIView.animate(withDuration: 0.2, animations: {
            self.popoverView.frame = self.calculatePopoverViewFrame()
        })
    }
    
    func showInView(_ view: UIView) {
        view.addSubview(self.view)
        
        self.popoverView.contentView = self.contentViewController.view
        self.popoverView.frame = self.calculatePopoverViewFrame()
        
        let fromViewInWindow = self.fromView.convertOriginToWindow()
        self.popoverView.arrowOffset = CGPoint(x: fromViewInWindow.x + (self.fromView.bounds.width - self.view.bounds.width) / 2,
                                               y: 0)
        
        self.preferredContentSizeObserver = self.contentViewController.observe(\.preferredContentSize, options: .new, changeHandler: { [weak self] (vc, changes) in
            if changes.newValue != nil {
                self?.animatePopoverViewAfterChange()
            }
        })
        
        self.popoverView.transform = self.popoverView.transform.translatedBy(x: 0, y: -(self.popoverView.bounds.height / 2)).scaledBy(x: 0.1, y: 0.1)
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1.3, options: .allowUserInteraction, animations: {
            self.popoverView.transform = CGAffineTransform.identity
            self.view.backgroundColor = UIColor(white: 0.4, alpha: 0.4)
        }, completion: nil)
    }
    
    @objc func dismiss() {
        self.preferredContentSizeObserver?.invalidate()
        
        UIView.animate(withDuration: 0.2, animations: {
            self.popoverView.transform = self.popoverView.transform.translatedBy(x: 0, y: -(self.popoverView.bounds.height / 2)).scaledBy(x: 0.01, y: 0.01)
            self.view.backgroundColor = UIColor.clear
        }, completion: { result in
            self.view.removeFromSuperview()
            self.removeFromParent()
        })
    }
    
    func calculatePopoverViewFrame() -> CGRect {
        let popoverY = self.fromView.convertOriginToWindow().y + self.fromView.bounds.height
        
        let preferredContentSize = self.contentViewController.preferredContentSize
        var popoverWidth = preferredContentSize.width
        if popoverWidth == UIView.noIntrinsicMetric {
            if UI_USER_INTERFACE_IDIOM() == .pad {
                popoverWidth = self.view.bounds.width * 0.6
            } else {
                popoverWidth = self.view.bounds.width
            }
        }
        
        let popoverHeight = min(preferredContentSize.height + self.popoverView.arrowHeight, view.bounds.height - popoverY - 40)
        
        return CGRect(
            x: (self.view.bounds.width - popoverWidth) / 2,
            y: popoverY,
            width: popoverWidth,
            height: popoverHeight
        )
    }
    
    // MARK: - Animation
    
    private func animatePopoverViewAfterChange() {
        UIView.animate(withDuration: 0.2, animations: {
            self.popoverView.frame = self.calculatePopoverViewFrame()
        })
    }
    
}
