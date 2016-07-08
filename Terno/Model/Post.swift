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
import Bond
import Darwin

class Post: NSObject {
	
	var authorUsername: String = ""
	var authorKey: String = ""
	var imagePath: String = ""
	var timestamp: NSTimeInterval = 0
	var postKey: String = ""
	var imageData: Observable<UIImage?> = Observable(nil)
	var likes: Observable<[String]?> = Observable(nil)
	
	
	static func uploadPhoto(imageData: NSData) {
	
		let key = Global.databaseRef!.child("posts").childByAutoId().key
		
		let storageRef = Global.storage!.referenceForURL("gs://project-9055015523885650113.appspot.com")
		
		let imageRef = storageRef.child("/images/\(Global.uid)/\(key).jpg")
		
		imageRef.putData(imageData, metadata: nil) { (metadata, error) in
			
			if let error = error {
				print(error.localizedDescription)
			}
			
			let time = 0 - NSDate().timeIntervalSince1970
		
			let post = ["uid": Global.uid,
						"author": Global.username,
						"imagePath": imageRef.fullPath,
						"timestamp": time
						]
			var childUpdates = ["/posts/\(key)": post,
			"/users/\(Global.uid)/posts/\(key)": time,
			"/timeline/\(Global.uid)/\(key)": time]
			
			//print("Hi here")
			
			FirebaseHelper.getUsersWhoFollow(Global.uid) { (users: [User]) in
				
				//print("before for loop")
				for user in users {
					childUpdates["/timeline/\(user.key)/\(key)"] = time
					//print("round")
				}
				
				//print("Hi there!! ")
				Global.databaseRef!.updateChildValues(childUpdates) // Atomic
			}
		}
	}
	
	func downloadImage(path: String) {
		if imageData.value == nil {
			
			Global.storage!.referenceWithPath(path).dataWithMaxSize(INT64_MAX) { (data, error) in
				if let data = data{
					print("Image Downloaded")
					self.imageData.value = UIImage(data: data, scale: 1.0)
				}
			}
		}
	}
	
	func fetchLikes(){
		
		if (likes.value != nil) {
			return
		}
		FirebaseHelper.getAllLikesForPost(self) { (usernames) in
			
			self.likes.value = usernames
		}
	}
	
	func doesUserLikePost(username: String) -> Bool {
		
		if let likes = likes.value {
			
			return likes.contains(username)
		} else {
			
			return false
		}
	}
	
	func toggleLikePost(user: String) {
		//print("Toggle Like")
		
		if (doesUserLikePost(user)) {
			// if post is liked, unlike it now
			// 1
			likes.value = likes.value?.filter { $0 != user }
			FirebaseHelper.unlikePost(self)
		} else {
			// if this post is not liked yet, like it now
			// 2
			likes.value?.append(user)
			FirebaseHelper.likePost(self)
		}
	}
	
}