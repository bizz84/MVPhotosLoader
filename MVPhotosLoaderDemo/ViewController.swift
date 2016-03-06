//
//  ViewController.swift
//  MVPhotosLoaderDemo
//
//  Created by Andrea Bizzotto on 06/03/2016.
//  Copyright © 2016 musevisions. All rights reserved.
//

import UIKit
import MVPhotosLoader

class ViewController: UIViewController {

    @IBAction func importPhotos(sender: AnyObject) {
        
        MVPhotosAccess.checkAuthorization(self) { [weak self] authorizationStatus in
        
            if authorizationStatus == .Authorized {
                self?.importPhotos()
            }
        }
    }

    func importPhotos() {
        
        guard let jsonFilePath = NSBundle.mainBundle().pathForResource("contents", ofType: "json"),
            let jsonData = NSData(contentsOfFile: jsonFilePath) else {
                
            print("Missing input json file")
            return
        }
        
        do {
            if let json = try NSJSONSerialization.JSONObjectWithData(jsonData, options: .AllowFragments) as? [String : AnyObject] {
                MVPhotosLoader.addPhotos(json) { error in
                    
                    if error == nil {
                        
                        // TODO: Show confirmation
                    }
                    
                }
            }
        }
        catch {
            print("\(error)")
        }
    }

}

