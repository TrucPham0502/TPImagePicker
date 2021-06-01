//  AssetGroupCell.swift
//
//  Created by Truc Pham on 9/15/20.
//  Copyright © 2020 Quan Pham (VN). All rights reserved.
//

import Foundation
import UIKit
class PhotoPickerImageCameraCell: UICollectionViewCell {
    var onTapSelect = {}
    override init(frame: CGRect) {
        super.init(frame: frame)
        prepareUI()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        prepareUI()
    }
    fileprivate func prepareUI(){
        let cameraImageView = UIImageView(frame: self.bounds)
        cameraImageView.contentMode = .center
        cameraImageView.image = Config.image.ic_camera_gallery
        cameraImageView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(cameraImageView)
        
        let text = UILabel()
        text.textColor = Config.color.onBackgroundTertiaryLevel
        text.text = Config.language.shotcut
        text.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(text)
        
        NSLayoutConstraint.activate([
            cameraImageView.centerXAnchor.constraint(equalTo: self.contentView.centerXAnchor),
            cameraImageView.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor, constant: -10),
            
            text.topAnchor.constraint(equalTo: cameraImageView.bottomAnchor),
            text.centerXAnchor.constraint(equalTo: self.contentView.centerXAnchor)
        ])
        
        self.contentView.backgroundColor = Config.color.backgroundTertiary
        self.contentView.isAccessibilityElement = true
        
        self.contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap(_:))))
    }
    
    @objc private func onTap(_ sender : Any?)
    {
        self.onTapSelect()
    }
    
   
}
