//
//  Post.swift
//  Terno
//
//  Created by Ramon Pans on 29/06/16.
//  Copyright © 2016 Flatmates. All rights reserved.
//

import Foundation
import FirebaseStorage
import FirebaseDatabase

class Post {
	

	static func uploadPhoto(imageData: NSData) {
	
		let key = Global.databaseRef!.child("posts").childByAutoId().key
		
		let storageRef = Global.storage!.referenceForURL("gs://project-9055015523885650113.appspot.com")
		
		let imageRef = storageRef.child("/images/\(Global.uid)/\(key).jpg")
		
		_ = imageRef.putData(imageData, metadata: nil) { (metadata, error) in
			
			if let error = error {
				print(error.localizedDescription)
			}
			
			let time = NSDate().timeIntervalSince1970
		
			let post = ["uid": Global.uid,
						"author": Global.username,
						"imagePath": imageRef.fullPath,
						"timestamp": time
						]
			let userPost = ["timestamp": time]
			let childUpdates = ["/posts/\(key)": post,
			"/users/\(Global.uid)/posts/\(key)": userPost]
			
			Global.databaseRef!.updateChildValues(childUpdates)
		}
	}
	
}