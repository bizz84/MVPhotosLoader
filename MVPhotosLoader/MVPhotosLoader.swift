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
        
        let sourcesMetadata = buildMetadata(sourceData)
        
        updateAlbums(sourcesMetadata, completion: completion)
    }
    
    private class func buildMetadata(sourceData: [String: AnyObject]) -> [ MVAssetSourceMetadata ] {
        
        guard let assets = sourceData["assets"] as? [ [String : AnyObject] ] else {
            return []
        }
        
        return assets.flatMap{ MVAssetSourceMetadata(json: $0) }
    }
    
    private class func updateAlbums(sourcesMetadata: [MVAssetSourceMetadata], completion: (error: NSError?) -> ()) {
        
        let userAssetCollections = fetchTopLevelUserCollections()
        
        addMissingAlbums(sourcesMetadata, existingAlbums: userAssetCollections) { assetCollections, error in
            
            if let error = error {
                print("Error adding missing albums: \(error)")
            }
            
            insertAssets(sourcesMetadata, assetCollections: assetCollections, completion:completion)
        }
    }

    private class func addMissingAlbums(assetSources: [MVAssetSourceMetadata], existingAlbums: [PHAssetCollection], completion: (assetCollections: [PHAssetCollection], error: NSError?) -> ()) {
        
        let missingNames = missingAlbumNames(assetSources, assetCollections: existingAlbums)
        
        if missingNames.count > 0 {
        
            PHPhotoLibrary.sharedPhotoLibrary().performChanges({
            
                let _ = createAlbums(names: missingNames)

            }) { success, error  in
                    
                let userAssetCollections = fetchTopLevelUserCollections()

                completion(assetCollections: userAssetCollections, error: error)
            }
        }
        else {
            completion(assetCollections: existingAlbums, error: nil)
        }
    }
    
    private class func insertAssets(assetSources: [MVAssetSourceMetadata], assetCollections: [PHAssetCollection], completion: (error: NSError?) -> ()) {
        
        PHPhotoLibrary.sharedPhotoLibrary().performChanges({
            
            for assetSource in assetSources {
                
                insertAsset(assetSource, inAssetCollections: assetCollections)
            }
            
        }) { success, error  in
                
            completion(error: error)
        }
    }
    
    
    private class func missingAlbumNames(sourcesMetadata: [MVAssetSourceMetadata], assetCollections: [PHAssetCollection]) -> [String] {

        let targetAlbumNames = Set(sourcesMetadata.flatMap { $0.albums })
        
        let existingAlbumNames = assetCollections.flatMap{ $0.localizedTitle }

        var missingAlbumNames: [String] = []
        for name in targetAlbumNames {
            
            if !existingAlbumNames.contains(name) {
                
                missingAlbumNames.append(name)
            }
        }
        return missingAlbumNames
    }
    
    class func createAlbums(names names: [String]) -> [PHAssetCollectionChangeRequest] {
        
        return names.map { PHAssetCollectionChangeRequest.creationRequestForAssetCollectionWithTitle($0) }
    }
    
    private class func insertAsset(metadata: MVAssetSourceMetadata, inAssetCollections assetCollections: [PHAssetCollection]) {
     
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
}

extension MVPhotosLoader {
    
    private class func fetchSmartAlbum(subtype: PHAssetCollectionSubtype) -> PHAssetCollection? {
        
        let fetchResult = PHAssetCollection.fetchAssetCollectionsWithType(.SmartAlbum, subtype: subtype, options: nil)
        
        return fetchResult.firstObject as? PHAssetCollection
    }

    private class func fetchTopLevelUserCollections() -> [PHAssetCollection] {
        
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

