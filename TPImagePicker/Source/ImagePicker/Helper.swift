//
//  ImagePickerController.swift
//
//  Created by Truc Pham on 9/15/20.
//  Copyright © 2021 Truc Pham (VN). All rights reserved.
//


import Foundation
import UIKit
import Photos
import AVFoundation

class Helper: NSObject {
    private static var assetGroupTypes: [PHAssetCollectionSubtype] = [
        .smartAlbumUserLibrary,
        .smartAlbumVideos,
        .smartAlbumFavorites,
        .albumRegular
    ]
    static func generateVideoFrames(from phAsset: PHAsset, numberOfFrames: Int = 9, progress: @escaping (Double?, Bool?, Error?) -> Void, completion: @escaping ([CGImage]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let multiTask = DispatchGroup()
            var asset: AVAsset?
            
            multiTask.enter()
            Helper.requestAVAsset(asset: phAsset, progress: progress, complete: { avAsset in
                asset = avAsset
                multiTask.leave()
            })
            multiTask.wait()
            
            guard let avAsset = asset else { return completion([]) }
            
            let durationInSeconds = CMTimeGetSeconds(avAsset.duration)
            
            var times = [CMTime]()
            for i in 0..<numberOfFrames {
                times.append(CMTimeMakeWithSeconds(durationInSeconds / Double(numberOfFrames) * Double(i), preferredTimescale: 1000))
            }
            
            let generator = AVAssetImageGenerator(asset: avAsset)
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = CGSize(width: 100, height: 100)
            
            var cgImages = [CGImage]()
            times.forEach {
                guard let cgImage = try? generator.copyCGImage(at: $0, actualTime: nil) else { return }
                cgImages.append(cgImage)
            }
            
            DispatchQueue.main.async {
                completion(cgImages)
            }
        }
    }
    
    
    static func collectionType(for subtype: PHAssetCollectionSubtype) -> PHAssetCollectionType {
        return subtype.rawValue < PHAssetCollectionSubtype.smartAlbumGeneric.rawValue ? .album : .smartAlbum
    }
    static func fetchGroups(groupFetchPredicate: NSPredicate? = nil) -> [PHAssetCollection] {
        var result = [PHAssetCollection]()
        for (_, groupType) in self.assetGroupTypes.enumerated() {
            let fetchResult = PHAssetCollection.fetchAssetCollections(with: self.collectionType(for: groupType),
                                                                      subtype: groupType,
                                                                      options: nil)
            fetchResult.enumerateObjects({ (collection, index, stop) in
                if let groupFetchPredicate = groupFetchPredicate {
                    if groupFetchPredicate.evaluate(with: collection) {
                        result.append(collection)
                    }
                } else {
                    result.append(collection)
                }
            })
        }
        return result
    }
    
    static func createDefaultAssetFetchOptions(type : [MediaType]) -> PHFetchOptions {
        let fetchOptions = PHFetchOptions()
        fetchOptions.includeAssetSourceTypes = [.typeUserLibrary, .typeCloudShared, .typeiTunesSynced]
//         Default sort is modificationDate
         fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.predicate = NSPredicate(format: "mediaType IN %@", type.map( { $0.value() }))
        fetchOptions.predicate =  NSPredicate(format: "mediaType IN %@", type.map( { $0.value() }))
        
        return fetchOptions
    }
    
    static func requestAVAsset(asset: PHAsset, progress: @escaping (Double?, Bool?, Error?) -> Void, complete: @escaping (AVAsset?) -> Void) {
        guard asset.mediaType == .video else { return complete(nil) }
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.progressHandler = {pro, error, stop, info  in
            progress(pro, stop.pointee.boolValue, error)
        }
        PHImageManager().requestAVAsset(forVideo: asset, options: options) { (asset, _, _) in
            DispatchQueue.main.async {
                complete(asset)
            }
        }
    }
    
    static func requestLivePhoto(forAsset asset: PHAsset,targetSize : CGSize, complete: @escaping (PHLivePhoto?) -> Void) {
        guard asset.mediaSubtypes == .photoLive else {
            complete(nil)
            return
        }
        let options = PHLivePhotoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .opportunistic
        PHImageManager().requestLivePhoto(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: options) { (phlive, info) in
            complete(phlive)
        }
    }
    
    static func requestVideoURL(forAsset asset: PHAsset, complete: @escaping (URL?) -> Void) {
        guard asset.mediaType == .video else { return complete(nil) }
        
        PHImageManager().requestAVAsset(forVideo: asset, options: nil) { (asset, _, _) in
            // AVAsset has two sub classes: AVComposition and AVAssetURL
            // AVComposition for slow motion video
            // AVAssetURL for normal videos
            
            // For slow motion video checking for AVCompostion
            // Creating an exporter to write the video into local file path and using the same to play/upload
            
            if asset!.isKind(of: AVComposition.self){
                let avCompositionAsset = asset as! AVComposition
                if avCompositionAsset.tracks.count > 1{
                    let exporter = AVAssetExportSession(asset: avCompositionAsset, presetName: AVAssetExportPresetHighestQuality)
                    exporter!.outputURL = self.fetchOutputURL()
                    exporter!.outputFileType = .mp4
                    exporter!.shouldOptimizeForNetworkUse = true
                    exporter!.exportAsynchronously {
                        let url = exporter!.outputURL
                        DispatchQueue.main.async {
                            complete(url)
                        }
                    }
                }
            } else {
                // Normal video, are stored as AVAssetURL
                let url = (asset as! AVURLAsset).url
                DispatchQueue.main.async {
                    complete(url)
                }
            }
        }
    }
    
    static func fetchOutputURL() -> URL{
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let path = documentDirectory.appendingPathComponent("test.mp4")
        return path
    }
    
    static func getFullSizePhoto(by asset: PHAsset, progress: @escaping (Double?, Bool?, Error?) -> Void, complete: @escaping (UIImage?) -> Void) -> PHImageRequestID {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true
        options.progressHandler = {(pro, error, stop, info)  in
            progress(pro, stop.pointee.boolValue, error)
        }
        let pId = manager.requestImageData(for: asset, options: options) { data, _, _, info in
            guard let data = data,
                let image = UIImage(data: data)
                else {
                    return complete(nil)
            }
            complete(image)
        }
        //        manager.cancelImageRequest(pId)
        return pId
    }
    
    static func getPhoto(by photoAsset: PHAsset, in desireSize: CGSize, progress: @escaping (Double?, Bool?, Error?) -> Void, complete: @escaping (UIImage?) -> Void) -> PHImageRequestID {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .fast
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true
        options.progressHandler = {(pro, error, stop, info)  in
            progress(pro, stop.pointee.boolValue, error)
        }
        let manager = PHImageManager.default()
        let newSize = CGSize(width: desireSize.width,
                             height: desireSize.height)
        
        let pId = manager.requestImage(for: photoAsset, targetSize: newSize, contentMode: .aspectFit, options: options, resultHandler: { result, _ in
            complete(result)
        })
        //        manager.cancelImageRequest(pId)
        return pId
    }
    
    static func getAssets(allowMediaTypes: [MediaType], group: GroupAsset? = nil) -> [PHAsset] {
        var fetchResult: PHFetchResult<PHAsset>? = nil
        if let group = group {
            guard let fR = group.fetchResult else {
                return []
            }
            fetchResult = fR
        }
        else{
            let fetchOptions = createDefaultAssetFetchOptions(type: allowMediaTypes)
            fetchResult = PHAsset.fetchAssets(with: fetchOptions)
        }
        guard fetchResult!.count > 0 else { return [] }
        var photoAssets = [PHAsset]()
        fetchResult!.enumerateObjects() { asset, index, _ in
            photoAssets.append(asset)
        }
        return photoAssets
        
    }
    
    
    static func canAccessPhotoLib() -> Bool {
        return PHPhotoLibrary.authorizationStatus() == .authorized
    }
    
    static func openIphoneSetting() {
        UIApplication.shared.openURL(URL(string: UIApplication.openSettingsURLString)!)
    }
    
    static func requestAuthorizationForPhotoAccess(authorized: @escaping () -> Void, rejected: @escaping () -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                if status == .authorized {
                    authorized()
                } else {
                    rejected()
                }
            }
        }
    }
    
    static func showDialog(in viewController: UIViewController,
                           okAction: UIAlertAction = UIAlertAction(title: "OK", style: .default, handler: nil),
                           cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil),
                           title: String? = "FMPhotoPicker",
                           message: String? = "FMPhotoPicker want to access Photo Library") {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        
        viewController.present(alertController, animated: true)
    }
}
