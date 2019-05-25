//
//  MVPhotosLoader.swift
//  MVPhotosLoader
//
//  Created by Andrea Bizzotto on 06/03/2016.
//  Copyright © 2016 musevisions. All rights reserved.
//

import UIKit
import Photos

open class MVPhotosLoader: NSObject {
    
    open class func addPhotos(_ sourceData: [String: AnyObject], completion: @escaping (_ error: Error?) -> ()) {
        
        let sourcesMetadata = buildMetadata(sourceData)
        
        updateAlbums(sourcesMetadata, completion: completion)
    }
    
    fileprivate class func buildMetadata(_ sourceData: [String: AnyObject]) -> [ MVAssetSourceMetadata ] {
        
        guard let assets = sourceData["assets"] as? [ [String : AnyObject] ] else {
            return []
        }
        
        return assets.compactMap{ MVAssetSourceMetadata(json: $0) }
    }
    
    fileprivate class func updateAlbums(_ sourcesMetadata: [MVAssetSourceMetadata], completion: @escaping (_ error: Error?) -> ()) {
        
        let userAssetCollections = fetchTopLevelUserCollections()
        
        addMissingAlbums(sourcesMetadata, existingAlbums: userAssetCollections) { assetCollections, error in
            
            if let error = error {
                print("Error adding missing albums: \(error)")
            }
            
            insertAssets(sourcesMetadata, assetCollections: assetCollections, completion:completion)
        }
    }

    fileprivate class func addMissingAlbums(_ assetSources: [MVAssetSourceMetadata], existingAlbums: [PHAssetCollection], completion: @escaping (_ assetCollections: [PHAssetCollection], _ error: Error?) -> ()) {
        
        let missingNames = missingAlbumNames(assetSources, assetCollections: existingAlbums)
        
        if missingNames.count > 0 {
        
            PHPhotoLibrary.shared().performChanges({
            
                let _ = createAlbums(names: missingNames)

            }) { success, error  in
                    
                let userAssetCollections = fetchTopLevelUserCollections()

                completion(userAssetCollections, error)
            }
        }
        else {
            completion(existingAlbums, nil)
        }
    }
    
    fileprivate class func insertAssets(_ assetSources: [MVAssetSourceMetadata], assetCollections: [PHAssetCollection], completion: @escaping (_ error: Error?) -> ()) {
        
        PHPhotoLibrary.shared().performChanges({
            
            for assetSource in assetSources {
                
                insertAsset(assetSource, inAssetCollections: assetCollections)
            }
            
        }) { success, error  in
                
            completion(error)
        }
    }
    
    
    fileprivate class func missingAlbumNames(_ sourcesMetadata: [MVAssetSourceMetadata], assetCollections: [PHAssetCollection]) -> [String] {

        let targetAlbumNames = Set(sourcesMetadata.flatMap { $0.albums })
        
        let existingAlbumNames = assetCollections.compactMap{ $0.localizedTitle }

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
    
    fileprivate class func insertAsset(_ metadata: MVAssetSourceMetadata, inAssetCollections assetCollections: [PHAssetCollection]) {
     
        guard let changeRequest = PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: metadata.fileURL as URL) else {
            return
        }
        changeRequest.isFavorite = metadata.favorite
        
        let filteredAssetCollections = filterAssetCollections(assetCollections, forAlbumsInMetadata: metadata)
        
        if let placeholder = changeRequest.placeholderForCreatedAsset {
            
            for assetCollection in filteredAssetCollections {
                
                if let assetCollectionChangeRequest = PHAssetCollectionChangeRequest(for: assetCollection) {
                    
                    assetCollectionChangeRequest.addAssets(NSArray(array: [ placeholder ]))
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
    
    fileprivate class func fetchSmartAlbum(_ subtype: PHAssetCollectionSubtype) -> PHAssetCollection? {
        
        let fetchResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: subtype, options: nil)
        
        return fetchResult.firstObject
    }

    fileprivate class func fetchTopLevelUserCollections() -> [PHAssetCollection] {
        
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

