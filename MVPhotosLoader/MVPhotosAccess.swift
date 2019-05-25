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

    class func requestAuthorization(_ completion: @escaping (PHAuthorizationStatus) -> ()) -> UIAlertController {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)

        let settingsAction = UIAlertAction(title: settings, style: UIAlertAction.Style.default, handler: { action in
        
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.openURL(url)
            }
        })
        let cancelAction = UIAlertAction(title: cancel, style: UIAlertAction.Style.default, handler: { action in
            
            print("Images will not show")
            completion(PHPhotoLibrary.authorizationStatus())

        })
        alert.addAction(cancelAction)
        alert.addAction(settingsAction)
        return alert
    }
}

open class MVPhotosAccess {
 
    open class func checkAuthorization(_ presenter: UIViewController, completion: @escaping (PHAuthorizationStatus) -> ()) {
        
        switch PHPhotoLibrary.authorizationStatus() {
        case .notDetermined: // Should never get here
            PHPhotoLibrary.requestAuthorization() { authorizationStatus in
                DispatchQueue.main.async {
                    completion(authorizationStatus)
                }
            }
        case .restricted: fallthrough
        case .denied:
            DispatchQueue.main.async {
                let alert = PhotosAccessAlert.requestAuthorization(completion)
                presenter.present(alert, animated: true, completion: nil)
            }
        case .authorized: fallthrough
        @unknown default:
            completion(PHPhotoLibrary.authorizationStatus())
      }
    }
}
