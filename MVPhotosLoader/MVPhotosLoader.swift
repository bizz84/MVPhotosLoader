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
    
    private class func addMissingAlbums(assetSources: [MVAssetSourceMetadata], existingAlbums: [PHAssetCollection], completion: (error: NSError?) -> ()) {

        let allAlbumNames = Set(assetSources.flatMap { $0.albums })
        
        let missingNames = missingAlbumNames(fromNames: allAlbumNames, assetCollections: existingAlbums)
        
        if missingNames.count > 0 {
        
            PHPhotoLibrary.sharedPhotoLibrary().performChanges({
            
                let _ = createAlbums(names: missingNames)

                }) { success, error  in
                    
                    completion(error: error)
            }
        }
        else {
            completion(error: nil)
        }
    }
    
    private class func addPhotos(assetSources: [MVAssetSourceMetadata], toAssetCollection assetCollection: PHAssetCollection?, completion: (error: NSError?) -> ()) {
        
        let userAssetCollections = fetchTopLevelUserCollections()
        
        addMissingAlbums(assetSources, existingAlbums: userAssetCollections) { error in
            
            let userAssetCollections = fetchTopLevelUserCollections()
            
            PHPhotoLibrary.sharedPhotoLibrary().performChanges({
                
                for assetSource in assetSources {
                    
                    insertAsset(assetSource, inAssetCollections: userAssetCollections)
                }
                
                }) { success, error  in
                    
                    completion(error: error)
            }
        }
    }
    
    
    class func missingAlbumNames(fromNames names: Set<String>, assetCollections: [PHAssetCollection]) -> [String] {

        let existingAlbumNames = assetCollections.flatMap{ $0.localizedTitle }

        var namesToAdd: [String] = []
        for name in names {
            
            if !existingAlbumNames.contains(name) {
                
                namesToAdd.append(name)
            }
        }
        return namesToAdd
    }
    
    class func createAlbums(names names: [String]) -> [PHAssetCollectionChangeRequest] {
        
        return names.map { PHAssetCollectionChangeRequest.creationRequestForAssetCollectionWithTitle($0) }
    }
    
    class func insertAsset(metadata: MVAssetSourceMetadata, inAssetCollections assetCollections: [PHAssetCollection]) {
     
        guard let changeRequest = PHAssetChangeRequest.creationRequestForAssetFromImageAtFileURL(metadata.fileURL) else {
            return
        }
        
        let filteredAssetCollections = filterAssetCollections(assetCollections, forAlbumsInMetadata: metadata)
        
        if let placeholder = changeRequest.placeholderForCreatedAsset {
            
            for assetCollection in filteredAssetCollections {
                
                if let assetCollectionChangeRequest = PHAssetCollectionChangeRequest(forAssetCollection: assetCollection) {
                    
                    assetCollectionChangeRequest.addAssets([ placeholder ])
                }
            }
        }
    }
    
    class func filterAssetCollections(userCollections: [PHAssetCollection], forAlbumsInMetadata metadata: MVAssetSourceMetadata) -> [PHAssetCollection] {
        
        return userCollections.filter {
            
            return $0.localizedTitle != nil ? metadata.albums.contains($0.localizedTitle!) : false
            
        }
    }
    
    class func fetchTopLevelUserCollections() -> [PHAssetCollection] {
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "localizedTitle", ascending: true)]
        
        let fetchResult = PHCollectionList.fetchTopLevelUserCollectionsWithOptions(fetchOptions)
        
        var collections: [PHAssetCollection] = []
        fetchResult.enumerateObjectsUsingBlock { object, index, pointer in

            if let collection = object as? PHAssetCollection {
                collections.append(collection)
            }
        }
        return collections
    }
}

