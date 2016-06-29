//
//  FirstViewController.swift
//  Terno
//
//  Created by Ramon Pans on 29/06/16.
//  Copyright © 2016 Flatmates. All rights reserved.
//

import UIKit
import FirebaseStorage
import FirebaseDatabase

class TimelineViewController: UIViewController {
	
	var photoTakingHelper: PhotoTakingHelper?

	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.tabBarController?.delegate = self
	}
	
	func takePhoto() {
		// instantiate photo taking class, provide callback for when photo is selected
		photoTakingHelper = PhotoTakingHelper(viewController: self.tabBarController!) { (image: UIImage?) in
			if let image = image {
				
				let imageData = UIImageJPEGRepresentation(image, 0.01)!

				Post.uploadPhoto(imageData)
			}
		}
	}
}

// MARK: Tab Bar Delegate

extension TimelineViewController: UITabBarControllerDelegate {
	
	func tabBarController(tabBarController: UITabBarController, shouldSelectViewController viewController: UIViewController) -> Bool {
		if (viewController is PhotoViewController) {
			takePhoto()
			return false
		} else {
			return true
		}
	}
}

