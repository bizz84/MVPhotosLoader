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
    
    public class func addPhotos(_ sourceData: [String: AnyObject], completion: (error: NSError?) -> ()) {
        
        let sourcesMetadata = buildMetadata(sourceData)
        
        updateAlbums(sourcesMetadata, completion: completion)
    }
    
    private class func buildMetadata(_ sourceData: [String: AnyObject]) -> [ MVAssetSourceMetadata ] {
        
        guard let assets = sourceData["assets"] as? [ [String : AnyObject] ] else {
            return []
        }
        
        return assets.flatMap{ MVAssetSourceMetadata(json: $0) }
    }
    
    private class func updateAlbums(_ sourcesMetadata: [MVAssetSourceMetadata], completion: (error: NSError?) -> ()) {
        
        let userAssetCollections = fetchTopLevelUserCollections()
        
        addMissingAlbums(sourcesMetadata, existingAlbums: userAssetCollections) { assetCollections, error in
            
            if let error = error {
                print("Error adding missing albums: \(error)")
            }
            
            insertAssets(sourcesMetadata, assetCollections: assetCollections, completion:completion)
        }
    }

    private class func addMissingAlbums(_ assetSources: [MVAssetSourceMetadata], existingAlbums: [PHAssetCollection], completion: (assetCollections: [PHAssetCollection], error: NSError?) -> ()) {
        
        let missingNames = missingAlbumNames(assetSources, assetCollections: existingAlbums)
        
        if missingNames.count > 0 {
        
            PHPhotoLibrary.shared().performChanges({
            
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
    
    private class func insertAssets(_ assetSources: [MVAssetSourceMetadata], assetCollections: [PHAssetCollection], completion: (error: NSError?) -> ()) {
        
        PHPhotoLibrary.shared().performChanges({
            
            for assetSource in assetSources {
                
                insertAsset(assetSource, inAssetCollections: assetCollections)
            }
            
        }) { success, error  in
                
            completion(error: error)
        }
    }
    
    
    private class func missingAlbumNames(_ sourcesMetadata: [MVAssetSourceMetadata], assetCollections: [PHAssetCollection]) -> [String] {

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
    
    class func createAlbums(names: [String]) -> [PHAssetCollectionChangeRequest] {
        
        return names.map { PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: $0) }
    }
    
    private class func insertAsset(_ metadata: MVAssetSourceMetadata, inAssetCollections assetCollections: [PHAssetCollection]) {
     
        guard let changeRequest = PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: metadata.fileURL as URL) else {
            return
        }
        changeRequest.isFavorite = metadata.favorite
        
        let filteredAssetCollections = filterAssetCollections(assetCollections, forAlbumsInMetadata: metadata)
        
        if let placeholder = changeRequest.placeholderForCreatedAsset {
            
            for assetCollection in filteredAssetCollections {
                
                if let assetCollectionChangeRequest = PHAssetCollectionChangeRequest(for: assetCollection) {
                    
                    assetCollectionChangeRequest.addAssets([ placeholder ])
                }
            }
        }
    }
    
    class func filterAssetCollections(_ userCollections: [PHAssetCollection], forAlbumsInMetadata metadata: MVAssetSourceMetadata) -> [PHAssetCollection] {
        
        return userCollections.filter {
            
            return $0.localizedTitle != nil ? metadata.albums.contains($0.localizedTitle!) : false
            
        }
    }
}

extension MVPhotosLoader {
    
    private class func fetchSmartAlbum(_ subtype: PHAssetCollectionSubtype) -> PHAssetCollection? {
        
        let fetchResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: subtype, options: nil)
        
        return fetchResult.firstObject
    }

    private class func fetchTopLevelUserCollections() -> [PHAssetCollection] {
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "localizedTitle", ascending: true)]
        
        let fetchResult = PHCollectionList.fetchTopLevelUserCollections(with: fetchOptions)
        
        var collections: [PHAssetCollection] = []
        fetchResult.enumerateObjects({ object, index, pointer in
            
            if let collection = object as? PHAssetCollection {
                collections.append(collection)
            }
        })
        return collections
    }
}

