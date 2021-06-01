//
//  ImagePickerController.swift
//
//  Created by Truc Pham on 9/15/20.
//  Copyright © 2021 Truc Pham (VN). All rights reserved.
//


import Foundation
import Photos

class PhotosDataSource {
    public private(set) var photoAssets: [PhotoAsset]
    private var selectedPhotoIndexes: [Int]
    
    init(photoAssets: [PhotoAsset]) {
        self.photoAssets = photoAssets
        self.selectedPhotoIndexes = []
    }
    
    public func setSeletedForPhoto(atIndex index: Int) {
        if self.selectedPhotoIndexes.firstIndex(where: { $0 == index }) == nil {
            self.selectedPhotoIndexes.append(index)
        }
    }
    
    public func unsetSeclectedForPhoto(atIndex index: Int) {
        if let indexInSelectedIndex = self.selectedPhotoIndexes.firstIndex(where: { $0 == index }) {
            self.selectedPhotoIndexes.remove(at: indexInSelectedIndex)
        }
    }
    
    public func selectedIndexOfPhoto(atIndex index: Int) -> Int? {
        return self.selectedPhotoIndexes.firstIndex(where: { $0 == index })
    }
    
    public func numberOfSelectedPhoto() -> Int {
        return self.selectedPhotoIndexes.count
    }
    
    public func mediaTypeForPhoto(atIndex index: Int) -> MediaType? {
        return self.photo(atIndex: index)?.mediaType
    }
    
    public func countSelectedPhoto(byType: MediaType) -> Int {
        return self.getSelectedPhotos().filter { $0.mediaType == byType }.count
    }
    
    public func affectedSelectedIndexs(changedIndex: Int) -> [Int] {
        return Array(self.selectedPhotoIndexes[changedIndex...])
    }

    public func getSelectedPhotos() -> [PhotoAsset] {
        var result = [PhotoAsset]()
        self.selectedPhotoIndexes.forEach {
            if let photo = self.photo(atIndex: $0) {
                result.append(photo)
            }
        }
        return result
    }
    
    public var numberOfPhotos: Int {
        return self.photoAssets.count
    }
    
    public func photo(atIndex index: Int) -> PhotoAsset? {
        guard index < self.photoAssets.count, index >= 0 else { return nil }
        return self.photoAssets[index]
    }
    
    public func index(ofPhoto photo: PhotoAsset) -> Int? {
        return self.photoAssets.firstIndex(where: { $0 === photo })
    }
    
    public func contains(photo: PhotoAsset) -> Bool {
        return self.index(ofPhoto: photo) != nil
    }
    
    public func delete(photo: PhotoAsset) {
        if let index = self.index(ofPhoto: photo) {
            self.photoAssets.remove(at: index)
        }
    }
    
}
