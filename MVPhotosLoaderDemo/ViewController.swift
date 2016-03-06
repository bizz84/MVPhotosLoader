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

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        importPhotos()
    }


    func importPhotos() {
        
        guard let jsonFilePath = NSBundle.mainBundle().pathForResource("source", ofType: "json"),
            let jsonData = NSData(contentsOfFile: jsonFilePath) else {
                
            print("Missing input json file")
            return
        }
        
        do {
            if let json = try NSJSONSerialization.JSONObjectWithData(jsonData, options: .AllowFragments) as? [String : AnyObject] {
                MVPhotosLoader.addPhotos(json) { error in
                    
                }
            }
        }
        catch {
            print("\(error)")
        }
    }

}

