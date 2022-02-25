//
//  ImagePickerController.swift
//
//  Created by Truc Pham on 9/15/20.
//  Copyright © 2021 Truc Pham (VN). All rights reserved.
//


import Foundation
import Photos
import UIKit
public class GroupAsset {
    var collection : PHAssetCollection?
    var groupId: String?
    var mediaType : [MediaType]
    var groupName: String?
    var fetchResult: PHFetchResult<PHAsset>?
    
    var totalCount: Int {
        get {
            guard let fetchResult = fetchResult else { return 0 }
            
            if let displayCount = displayCount, displayCount > 0 {
                return min(displayCount, fetchResult.count)
            } else {
                return fetchResult.count
            }
        }
    }
    
    var displayCount: Int?
    
    init(collection: PHAssetCollection, mediaType : [MediaType]) {
        self.collection = collection
        self.mediaType = mediaType
        requestGroupInfo()
    }
    
    private func requestGroupInfo()
    {
        if let c = self.collection{
            self.groupName = self.collection?.localizedTitle
            let fetchResult = PHAsset.fetchAssets(in: c,
                                                  options: Helper.createDefaultAssetFetchOptions(type: mediaType))
            self.fetchResult = fetchResult
            self.displayCount = 0
        }
        
    }
    
    func updateGroup(collection: PHAssetCollection) {
        self.collection = collection
    }
    
    func updateGroup(fetchResult: PHFetchResult<PHAsset>) {
        self.fetchResult = fetchResult
        self.displayCount = 0
    }
    
    func fetchGroupThumbnail(size: CGSize,progress: @escaping (Double?, Bool?, Error?) -> Void,
                             completeBlock: @escaping (_ image: UIImage?) -> Void)
    {
        if self.totalCount == 0 {
            completeBlock(nil)
            return
        }
        guard let lastResult = self.fetchResult?.lastObject else {
            assertionFailure("Expect latestAsset")
            completeBlock(nil)
            return
        }
        _ = Helper.getPhoto(by: lastResult, in: size, progress: progress, complete:  { image in
            completeBlock(image)
            return
        })
    }
    
}
