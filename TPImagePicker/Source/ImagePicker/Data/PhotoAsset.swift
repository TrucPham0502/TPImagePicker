//
//  ImagePickerController.swift
//
//  Created by Truc Pham on 9/15/20.
//  Copyright © 2021 Truc Pham (VN). All rights reserved.
//


import Foundation
import UIKit
import Photos
enum MediaType {
    case image
    case video
    
    case unsupported
    
    public func value() -> Int {
        switch self {
        case .image:
            return PHAssetMediaType.image.rawValue
        case .video:
            return PHAssetMediaType.video.rawValue
        case .unsupported:
            return PHAssetMediaType.unknown.rawValue
        }
    }
    
    init(withPHAssetMediaType type: PHAssetMediaType) {
        switch type {
        case .image:
            self = .image
        case .video:
            self = .video
        default:
            self = .unsupported
        }
    }
}

enum MediaSubtype {
    // Photo subtypes
    case photoLive
    case photoPanorama
    case photoHDR
    case photoScreenshot
    case photoDepthEffect
    // Video subtypes
    case videoStreamed
    case videoHighFrameRate
    case videoTimelapse
    case normal
    
    
    public func value() -> UInt {
        switch self {
        case .photoLive:
            return PHAssetMediaSubtype.photoLive.rawValue
        case .photoPanorama:
            return PHAssetMediaSubtype.photoPanorama.rawValue
        case .photoHDR:
            return PHAssetMediaSubtype.photoHDR.rawValue
        case .photoScreenshot:
            return PHAssetMediaSubtype.photoScreenshot.rawValue
        case .photoDepthEffect:
            return PHAssetMediaSubtype.photoDepthEffect.rawValue
        case .videoStreamed:
            return PHAssetMediaSubtype.videoStreamed.rawValue
        case .videoHighFrameRate:
            return PHAssetMediaSubtype.videoHighFrameRate.rawValue
        case .videoTimelapse:
            return PHAssetMediaSubtype.videoTimelapse.rawValue
        case .normal:
            return .init(0)
        }
    }
    init(withPHAssetMediaSubtype type: PHAssetMediaSubtype) {
        switch type {
        case .photoLive:
            self = .photoLive
        case .photoPanorama:
            self = .photoPanorama
        case .photoHDR:
            self = .photoHDR
        case .photoScreenshot:
            self = .photoScreenshot
        case .photoDepthEffect:
            self = .photoDepthEffect
        case .videoStreamed:
            self = .videoStreamed
        case .videoTimelapse:
            self = .videoTimelapse
        case .videoHighFrameRate:
            self = .videoHighFrameRate
        default:
            self = .normal
        }
    }
}
class PhotoAsset {
    let asset: PHAsset?
   
    let sourceImage: UIImage?
    
    let mediaType: MediaType
    
    let mediaSubType : MediaSubtype
    
    // a fully edited thumbnail version of the image
    var editedThumb: UIImage?
    
    // a filterd-only thumbnail version of the image
    var filterdThumb: UIImage?
    
    var thumbRequestId: PHImageRequestID?
    
    var videoFrames: [CGImage]?
    
    var thumbChanged: (UIImage) -> Void = { _ in }
    
    var avasset : AVAsset?
    
    var url : URL?
    
    var livePhoto : PHLivePhoto?
    
    private var fullSizePhotoRequestId: PHImageRequestID?

    private var canceledFullSizeRequest = false
    
    init(asset: PHAsset) {
        self.asset = asset
        self.mediaType = MediaType(withPHAssetMediaType: asset.mediaType)
        self.mediaSubType = MediaSubtype(withPHAssetMediaSubtype: asset.mediaSubtypes)
        self.sourceImage = nil
    }
    
    init(sourceImage: UIImage) {
        self.sourceImage = sourceImage
        self.mediaType = .image
        self.mediaSubType = .normal
        self.asset = nil
    }
    
    func requestAVAsset(_ complete: @escaping (AVAsset?) -> Void) {
        if let avasset = avasset {
            complete(avasset)
        }
        else {
            if let asset = asset {
                Helper.requestAVAsset(asset: asset) { progress, stop, err in
                    print(progress)
                } complete: {[weak self] (asset) in
                    guard let _self = self else { return }
                    _self.avasset = asset
                    complete(asset)
                }
            }
        }
        
    }
   
    
    func requestVideoURL(_ complete: @escaping (URL?) -> Void) {
        if let url = url {
            complete(url)
        }
        else {
            if let asset = asset {
                Helper.requestVideoURL(forAsset: asset) {[weak self] (url) in
                    self?.url = url
                    complete(url)
                }
            }
        }
        
    }
    
    func requestVideoFrames(progress: @escaping (Double?, Bool?, Error?) -> Void, complete: @escaping ([CGImage]) -> Void) {
        if let videoFrames = self.videoFrames {
            complete(videoFrames)
        } else {
            if let asset = asset {
                Helper.generateVideoFrames(from: asset, progress: progress, completion: {[weak self] cgImages in
                    guard let _self = self else { return }
                    _self.videoFrames = cgImages
                    complete(cgImages)
                })
            } else {
                complete([])
            }
        }
    }
    
    func requestThumb(refresh: Bool=false,size : CGSize, progress: @escaping (Double?, Bool?, Error?) -> Void, _ complete: @escaping (UIImage?) -> Void) {
        if let editedThumb = self.editedThumb, !refresh {
            complete(editedThumb)
        } else {
            if let asset = asset {
                self.thumbRequestId = Helper.getPhoto(by: asset, in: size, progress: progress, complete: {[weak self] image in
                    guard let _self = self else { return }
                    _self.editedThumb = image
                    complete(image)
                })
            }
        }
    }
    func requestLivePhoto(complete: @escaping (PHLivePhoto?) -> Void) {
        if let live = self.livePhoto {
            complete(live)
        }
        else {
            if let asset = asset {
                Helper.requestLivePhoto(forAsset: asset, targetSize: CGSize(width: 2000, height: 2000)) {[weak self] (live) in
                    self?.livePhoto = live
                    complete(live)
                }
            }
        }
        
    }
    func requestFullSizePhoto(progress: @escaping (Double?, Bool?, Error?) -> Void, complete: @escaping (UIImage?) -> Void) {
        if let asset = asset {
            self.fullSizePhotoRequestId = Helper.getPhoto(by: asset, in: CGSize(width: 2000, height: 2000), progress: progress, complete: {[weak self] image in
                guard let _self = self else {return}
                _self.fullSizePhotoRequestId = nil
                if _self.canceledFullSizeRequest {
                    _self.canceledFullSizeRequest = false
                    complete(nil)
                } else {
                    guard let image = image else { return complete(nil) }
                    complete(image)
                }
            })
        }
    }
    
    public func cancelAllRequest() {
        self.cancelThumbRequest()
        self.cancelFullSizePhotoRequest()
    }
    
    public func cancelThumbRequest() {
        if let thumbRequestId = self.thumbRequestId {
            PHImageManager.default().cancelImageRequest(thumbRequestId)
        }
    }
    
    public func cancelFullSizePhotoRequest() {
        if let fullSizePhotoRequestId = self.fullSizePhotoRequestId {
            PHImageManager.default().cancelImageRequest(fullSizePhotoRequestId)
            self.canceledFullSizeRequest = true
        }
    }
  
}
