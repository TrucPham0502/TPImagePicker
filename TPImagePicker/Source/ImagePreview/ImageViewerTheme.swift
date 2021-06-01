//
//  ImagePickerController.swift
//
//  Created by Truc Pham on 9/15/20.
//  Copyright © 2021 Truc Pham (VN). All rights reserved.
//


import UIKit

public enum ImageViewerTheme {
    case light
    case dark
    
    var color:UIColor {
        switch self {
            case .light:
                return .white
            case .dark:
                return .black
        }
    }
    
    var tintColor:UIColor {
        switch self {
            case .light:
                return .black
            case .dark:
                return .white
        }
    }
}
