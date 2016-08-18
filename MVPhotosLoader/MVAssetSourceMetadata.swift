//
//  MVAssetSourceMetadata.swift
//  MVPhotosLoader
//
//  Created by Andrea Bizzotto on 06/03/2016.
//  Copyright © 2016 musevisions. All rights reserved.
//

import UIKit

struct MVAssetSourceMetadata {
    
    let name: String
    let fileURL: URL
    let albums: [String]
    let favorite: Bool
    
    init?(json: [String : AnyObject]) {
        guard let name = json["name"] as? String,
            let fileURL = MVAssetSourceMetadata.fileURL(name) else {
                return nil
        }
        
        self.name = name
        self.fileURL = fileURL
        self.albums = json["albums"] as? [String] ?? []
        self.favorite = json["favorite"] as? Bool ?? false
    }
    
    fileprivate static func fileURL(_ name: String) -> URL? {
        
        if let url = URL(string: name) {
            let ext = url.pathExtension
            let fileName = url.deletingPathExtension().lastPathComponent
            
            if let filePath = Bundle.main.path(forResource: fileName, ofType: ext) {
                return URL(fileURLWithPath: filePath)
            }
        }
        return nil
    }
}
