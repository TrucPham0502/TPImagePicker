//
//  ImagePickerController.swift
//
//  Created by Truc Pham on 9/15/20.
//  Copyright © 2021 Truc Pham (VN). All rights reserved.
//


import Foundation
import Photos
class GroupDataSource {
    public private(set) var collectionAssets: [GroupAsset]
    init(collectionAssets: [GroupAsset]) {
        self.collectionAssets = collectionAssets
    }
    public var numberOfGroup: Int {
        return self.collectionAssets.count
    }
    
     public func group(atIndex index: Int) -> GroupAsset? {
           guard index < self.collectionAssets.count, index >= 0 else { return nil }
           return self.collectionAssets[index]
    }
    
    public func group(id : String) -> GroupAsset?
    {
        for group in collectionAssets{
            if group.groupId == id{
                return group
            }
        }
        return nil
    }
}
