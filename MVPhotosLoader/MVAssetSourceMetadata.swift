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
    let fileURL: NSURL
    let albums: [String]
    
    
    init?(json: [String : AnyObject]) {
        guard let name = json["name"] as? String,
            let fileURL = MVAssetSourceMetadata.fileURL(name) else {
                return nil
        }
        
        self.name = name
        self.fileURL = fileURL
        self.albums = json["albums"] as? [String] ?? []
    }
    
    private static func fileURL(name: String) -> NSURL? {
        
        if let url = NSURL(string: name) {
            let ext = url.pathExtension
            let fileName = url.URLByDeletingPathExtension?.lastPathComponent
            
            if let filePath = NSBundle.mainBundle().pathForResource(fileName, ofType: ext) {
                return NSURL(fileURLWithPath: filePath)
            }
        }
        return nil
    }
}