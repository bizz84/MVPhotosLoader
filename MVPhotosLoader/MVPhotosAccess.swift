//
//  PhotoLibraryAuthorization.swift
//  PhotosMap
//
//  Created by Andrea Bizzotto on 27/05/2015.
//  Copyright (c) 2015 Muse Visions. All rights reserved.
//

import UIKit
import Photos

class PhotosAccessAlert {
    
    static let title = "Access Required"
    static let message = "Please give this app permission to access your photo library in your settings app"
    static let settings = "Settings"
    static let cancel = "Cancel"

    class func requestAuthorization(completion: (PHAuthorizationStatus) -> ()) -> UIAlertController {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)

        let settingsAction = UIAlertAction(title: settings, style: UIAlertActionStyle.Default, handler: { action in
        
            if let url = NSURL(string: UIApplicationOpenSettingsURLString) {
                UIApplication.sharedApplication().openURL(url)
            }
        })
        let cancelAction = UIAlertAction(title: cancel, style: UIAlertActionStyle.Default, handler: { action in
            
            print("Images will not show")
            completion(PHPhotoLibrary.authorizationStatus())

        })
        alert.addAction(cancelAction)
        alert.addAction(settingsAction)
        return alert
    }
}

public class MVPhotosAccess {
 
    public class func checkAuthorization(presenter: UIViewController, completion: (PHAuthorizationStatus) -> ()) {
        
        switch PHPhotoLibrary.authorizationStatus() {
        case .NotDetermined: // Should never get here
            PHPhotoLibrary.requestAuthorization() { authorizationStatus in
                dispatch_async(dispatch_get_main_queue()) {
                    completion(authorizationStatus)
                }
            }
        case .Restricted: fallthrough
        case .Denied:
            dispatch_async(dispatch_get_main_queue()) {
                let alert = PhotosAccessAlert.requestAuthorization(completion)
                presenter.presentViewController(alert, animated: true, completion: nil)
            }
        case .Authorized:
            completion(PHPhotoLibrary.authorizationStatus())
        }
    }
}
