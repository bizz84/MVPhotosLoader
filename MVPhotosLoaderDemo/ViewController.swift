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

    @IBAction func importPhotos(_ sender: AnyObject) {
        
        MVPhotosAccess.checkAuthorization(self) { [weak self] authorizationStatus in
        
            if authorizationStatus == .authorized {
                self?.importPhotos()
            }
        }
    }

    func importPhotos() {
        
        guard let jsonFilePath = Bundle.main.path(forResource: "contents", ofType: "json"),
            let jsonData = try? Data(contentsOf: URL(fileURLWithPath: jsonFilePath)) else {
                
            print("Missing input json file")
            return
        }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) as? [String : AnyObject] {
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

