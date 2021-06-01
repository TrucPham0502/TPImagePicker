//
//  ImagePickerController.swift
//
//  Created by Truc Pham on 9/15/20.
//  Copyright © 2021 Truc Pham (VN). All rights reserved.
//


import UIKit

enum ImageItem {
    case image(UIImage?)
    case asset(PhotoAsset?, placeholder: UIImage?)
    case url(URL, placeholder: UIImage?)
}
