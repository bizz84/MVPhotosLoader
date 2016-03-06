//
//  MVPhotosLoader.swift
//  MVPhotosLoader
//
//  Created by Andrea Bizzotto on 06/03/2016.
//  Copyright © 2016 musevisions. All rights reserved.
//

import UIKit
import Photos

public class MVPhotosLoader: NSObject {
    
    public class func addPhotos(sourceData: [String: AnyObject], completion: (error: NSError?) -> ()) {
        
        let sources = parseJSONSource(sourceData)
        
        addPhotos(sources, toAssetCollection: nil, completion: completion)
        
        print("sources: \(sources)")
    }
    
    private class func parseJSONSource(sourceData: [String: AnyObject]) -> [ MVAssetSourceMetadata ] {
        
        guard let assets = sourceData["assets"] as? [ [String : AnyObject] ] else {
            return []
        }
        
        return assets.flatMap{ MVAssetSourceMetadata(json: $0) }
    }
    
    
    private class func fetchSmartAlbum(subtype: PHAssetCollectionSubtype) -> PHAssetCollection? {
        
        let fetchResult = PHAssetCollection.fetchAssetCollectionsWithType(.SmartAlbum, subtype: subtype, options: nil)
        
        return fetchResult.firstObject as? PHAssetCollection
    }
    
    private class func addPhotos(assetSources: [MVAssetSourceMetadata], toAssetCollection assetCollection: PHAssetCollection?, completion: (error: NSError?) -> ()) {
        
        //        let data = NSData(contentsOfFile: "a.jpg")
        //        if
        
        //        let createAssetRequest = PHAssetChangeRequest.creationRequestForAssetFromImage(image)
        //        let assetPlaceholder = createAssetRequest.placeholderForCreatedAsset
        //        let albumChangeRequest = PHAssetCollectionChangeRequest(forAssetCollection: album)
        //        albumChangeRequest.addAssets([assetPlaceholder])
        
        PHPhotoLibrary.sharedPhotoLibrary().performChanges({
            
            //let nonInsertedFilesURLs = filesURLs.filter { /* on json */ }
            //            let images = filesURLs.flatMap{ $0.path }.flatMap{ UIImage(contentsOfFile: $0 ) }
            //            let assetChangeRequests = images.flatMap{ PHAssetChangeRequest.creationRequestForAssetFromImage( $0 ) }
            let assetChangeRequests = assetSources.flatMap { PHAssetChangeRequest.creationRequestForAssetFromImageAtFileURL($0.fileURL) }
            
            if let assetCollection = assetCollection {
                let placeholders = assetChangeRequests.flatMap{ $0.placeholderForCreatedAsset }
                
                if let assetCollectionChangeRequest = PHAssetCollectionChangeRequest(forAssetCollection: assetCollection) {
                    
                    assetCollectionChangeRequest.addAssets(placeholders)
                }
            }
            
            }) { success, error  in
                
                completion(error: error)
        }
    }
}

