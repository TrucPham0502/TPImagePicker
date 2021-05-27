//
//  GradientView.swift
//  TPImagePicker
//
//  Created by Truc Pham on 25/05/2021.
//

import Foundation
import UIKit
enum GradientDirection {
    case topToBottom
    case bottomToTop
    case leftToRight
    case rightToLeft
    case topLeftToBottomRight
    case topRightToBottomLeft
    case bottomLeftToTopRight
    case bottomRightToTopLeft
    case custom(Int)
}
class GradientLayer: CAGradientLayer {

    private var direction: GradientDirection = .bottomLeftToTopRight

    public init(direction: GradientDirection, colors: [UIColor], cornerRadius: CGFloat = 0, locations: [Double]? = nil) {
        super.init()
        self.direction = direction
        self.needsDisplayOnBoundsChange = true
        self.colors = colors.map { $0.cgColor as Any }
        let (startPoint, endPoint) = getStartAndEndPointsOf(direction)
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.cornerRadius = cornerRadius
        self.locations = locations?.map { NSNumber(value: $0) }
    }
    
    public override init(layer: Any) {
        super.init(layer: layer)
    }
    
    required public init(coder aDecoder: NSCoder) {
        super.init()
    }
    
    public final func clone() -> GradientLayer {
        if let colors = self.colors {
            return GradientLayer(direction: self.direction, colors: colors.map { UIColor(cgColor: ($0 as! CGColor)) }, cornerRadius: self.cornerRadius, locations: self.locations?.map { $0.doubleValue } )
        }
        return GradientLayer(direction: self.direction, colors: [], cornerRadius: self.cornerRadius, locations: self.locations?.map { $0.doubleValue })
    }
    
    private func getStartAndEndPointsOf(_ gradientDirection: GradientDirection) -> (startPoint: CGPoint, endPoint: CGPoint) {
            switch gradientDirection {
            case .topToBottom:
                return (CGPoint(x: 0.5, y: 0.0), CGPoint(x: 0.5, y: 1.0))
            case .bottomToTop:
                return (CGPoint(x: 0.5, y: 1.0), CGPoint(x: 0.5, y: 0.0))
            case .leftToRight:
                return (CGPoint(x: 0.0, y: 0.5), CGPoint(x: 1.0, y: 0.5))
            case .rightToLeft:
                return (CGPoint(x: 1.0, y: 0.5), CGPoint(x: 0.0, y: 0.5))
            case .topLeftToBottomRight:
                return (CGPoint.zero, CGPoint(x: 1.0, y: 1.0))
            case .topRightToBottomLeft:
                return (CGPoint(x: 1.0, y: 0.0), CGPoint(x: 0.0, y: 1.0))
            case .bottomLeftToTopRight:
                return (CGPoint(x: 0.0, y: 1.0), CGPoint(x: 1.0, y: 0.0))
            case .bottomRightToTopLeft:
                return (CGPoint(x: 1.0, y: 1.0), CGPoint(x: 0.0, y: 0.0))
            case .custom(let angle):
                return startAndEndPoints(from: angle)
            }
        }
    private func startAndEndPoints(from angle: Int) -> (startPoint:CGPoint, endPoint:CGPoint) {
            // Set default points for angle of 0°
            var startPointX: CGFloat = 0.5
            var startPointY: CGFloat = 1.0

            // Define point objects
            var startPoint: CGPoint
            var endPoint: CGPoint

            // Define points
            switch true {
            // Define known points
            case angle == 0:
                startPointX = 0.5
                startPointY = 1.0
            case angle == 45:
                startPointX = 0.0
                startPointY = 1.0
            case angle == 90:
                startPointX = 0.0
                startPointY = 0.5
            case angle == 135:
                startPointX = 0.0
                startPointY = 0.0
            case angle == 180:
                startPointX = 0.5
                startPointY = 0.0
            case angle == 225:
                startPointX = 1.0
                startPointY = 0.0
            case angle == 270:
                startPointX = 1.0
                startPointY = 0.5
            case angle == 315:
                startPointX = 1.0
                startPointY = 1.0
            // Define calculated points
            case angle > 315 || angle < 45:
                startPointX = 0.5 - CGFloat(tan(angle.degreesToRads()) * 0.5)
                startPointY = 1.0
            case angle > 45 && angle < 135:
                startPointX = 0.0
                startPointY = 0.5 + CGFloat(tan(90.degreesToRads() - angle.degreesToRads()) * 0.5)
            case angle > 135 && angle < 225:
                startPointX = 0.5 - CGFloat(tan(180.degreesToRads() - angle.degreesToRads()) * 0.5)
                startPointY = 0.0
            case angle > 225 && angle < 359:
                startPointX = 1.0
                startPointY = 0.5 - CGFloat(tan(270.degreesToRads() - angle.degreesToRads()) * 0.5)
            default: break
            }
            // Build return CGPoints
            startPoint = CGPoint(x: startPointX, y: startPointY)
            endPoint = startPoint.opposite()
            // Return CGPoints
            return (startPoint, endPoint)
        }

}
fileprivate extension Int {

    func degreesToRads() -> Double {
        return (Double(self) * .pi / 180)
    }
}

fileprivate extension CGPoint {

    func opposite() -> CGPoint {
        // Create New Point
        var oppositePoint = CGPoint()
        // Get Origin Data
        let originXValue = self.x
        let originYValue = self.y
        // Convert Points and Update New Point
        oppositePoint.x = 1.0 - originXValue
        oppositePoint.y = 1.0 - originYValue
        return oppositePoint
    }
}
extension UIView {
    
    func addGradientWithDirection(_ direction: GradientDirection, colors: [UIColor], cornerRadius: CGFloat = 0, locations: [Double]? = nil) {
        let gradientLayer = GradientLayer(direction: direction, colors: colors, cornerRadius: cornerRadius, locations: locations)
        self.addGradient(gradientLayer)
    }
    
    func addGradient(_ gradientLayer: GradientLayer, cornerRadius: CGFloat = 0) {
        let cloneGradient = gradientLayer.clone()
        cloneGradient.frame = self.bounds
        cloneGradient.cornerRadius = cornerRadius
        self.layer.addSublayer(cloneGradient)
    }
}

extension UIColor {
    
    static func fromGradient(_ gradient: GradientLayer, frame: CGRect, cornerRadius: CGFloat = 0) -> UIColor? {
        guard let image = UIImage.fromGradient(gradient, frame: frame, cornerRadius: cornerRadius) else { return nil }
        return UIColor(patternImage: image)
    }
    
    static func fromGradientWithDirection(_ direction: GradientDirection, frame: CGRect, colors: [UIColor], cornerRadius: CGFloat = 0, locations: [Double]? = nil) -> UIColor? {
        let gradient = GradientLayer(direction: direction, colors: colors, cornerRadius: cornerRadius, locations: locations)
        return UIColor.fromGradient(gradient, frame: frame)
    }
}

extension UIImage {
    
    static func fromGradient(_ gradient: GradientLayer, frame: CGRect, cornerRadius: CGFloat = 0) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(frame.size, false, UIScreen.main.scale)
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }
        let cloneGradient = gradient.clone()
        cloneGradient.frame = frame
        cloneGradient.cornerRadius = cornerRadius
        cloneGradient.render(in: ctx)
        guard let image = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        UIGraphicsEndImageContext()
        return image
    }
    
    static func fromGradientWithDirection(_ direction: GradientDirection, frame: CGRect, colors: [UIColor], cornerRadius: CGFloat = 0, locations: [Double]? = nil) -> UIImage? {
        let gradient = GradientLayer(direction: direction, colors: colors, cornerRadius: cornerRadius, locations: locations)
        return UIImage.fromGradient(gradient, frame: frame)
    }

}
