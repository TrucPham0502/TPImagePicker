//  AssetGroupCell.swift
//
//  ImagePickerController.swift
//
//  Created by Truc Pham on 9/15/20.
//  Copyright © 2021 Truc Pham (VN). All rights reserved.
//



import UIKit

class TPImagePickerCollectionViewLayout: UICollectionViewFlowLayout {
    let numberOfColumns: CGFloat
    let padding: CGFloat = 3
    
    init(numberOfColumns: CGFloat) {
        self.numberOfColumns = numberOfColumns
        super.init()
        self.minimumInteritemSpacing = self.padding
        self.minimumLineSpacing = self.padding
        let itemSizeW = (UIScreen.main.bounds.size.width - ((self.numberOfColumns - 1) * self.padding)) / numberOfColumns
        self.itemSize = CGSize(width: itemSizeW, height: itemSizeW)
        
    }
    
    required init?(coder: NSCoder) {
        self.numberOfColumns = 3
        super.init(coder: coder)
    }
}
