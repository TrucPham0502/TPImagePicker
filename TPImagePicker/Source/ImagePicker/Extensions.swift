//
//  Extensions.swift
//  TPImagePicker
//
//  Created by Truc Pham on 25/05/2021.
//

import Foundation
import UIKit
extension UITableViewCell {
    class var reuseIdentifier: String {
        return String(describing: self)
    }
    
    class var nib: UINib {
        return UINib(nibName: String(describing: self), bundle: nil)
    }
}
extension UICollectionViewCell {
    class var reuseIdentifier: String {
        return String(describing: self)
    }
    
    class var nib: UINib {
        return UINib(nibName: String(describing: self), bundle: nil)
    }
}
extension TimeInterval {
    private var seconds: Int {
        return Int(Double(self).rounded()) % 60
    }
    
    private var minutes: Int {
        return (Int(Double(self).rounded()) / 60 ) % 60
    }
    
    private var hours: Int {
        return Int(Double(self).rounded()) / 3600
    }
    
    var stringTime: String {
        if hours != 0 {
            return String(format: "%d:%.2d:%.2d", hours, minutes, seconds)
        } else if minutes != 0 {
            return String(format: "%d:%.2d", minutes, seconds)
        } else if seconds != 0 {
            return String(format: "0:%.2d", seconds)
        } else {
            return "0:00"
        }
    }
}
extension UIDevice {
    var hasNotch: Bool {
        let bottom = UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0
        return bottom > 0
    }
    
}
extension UIView {
    func convertOriginToWindow() -> CGPoint {
        return self.convert(CGPoint.zero, to: self.window)
    }
    var is3DTouchAvailable: Bool {
           return self.traitCollection.forceTouchCapability == .available
     }
}
