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
import ConvenienceKit


class Post: NSObject {

	var authorUsername: String = ""
	var authorKey: String = ""
	var imagePath: String = ""
	var timestamp: NSTimeInterval = 0
	var postKey: String = ""

	//The image data and the likes are stored as observable so we can "lazily download" them
	var imageData: Observable<UIImage?> = Observable(nil)
	var likes: Observable<[String]?> = Observable(nil)

	//This makes the app faster while still optimizing the memory usage
	static var imageCache: NSCacheSwift<String, UIImage>!
	
	override class func initialize() {
		var onceToken : dispatch_once_t = 0;
		dispatch_once(&onceToken) {
			//Initialize the image cache  for the Post class (It's static so we only have to do it once)
			Post.imageCache = NSCacheSwift<String, UIImage>()
		}
	}
	
	//This method creates a post in the database and stores the image in Firebase's "storage bucket"
	static func uploadPhoto(imageData: NSData) {

		//Save the key for the post
		let key = Global.databaseRef!.child("posts").childByAutoId().key

		//Create a reference to our storage reference
		//TODO: Store the reference in the database so it's not public...
		let storageRef = Global.storage!.referenceForURL("gs://project-9055015523885650113.appspot.com")

		//We store the images inside a folder structure -> images/<ownerKey>/<postKey>
		let imageRef = storageRef.child("/images/\(Global.uid)/\(key).jpg")

		//Store the image in the reference we just created
		imageRef.putData(imageData, metadata: nil) { (metadata, error) in
			
			if let error = error {
				//If error, print for debugging
				//print(error.localizedDescription)
			}

			//Inversed timestamp for reasons mentioned earlier
			let time = 0 - NSDate().timeIntervalSince1970

			//Create the dictionary with all of our post's data
			let post = ["uid": Global.uid,
						"author": Global.username,
						"imagePath": imageRef.fullPath,
						"timestamp": time
						]

			//Create an "update dictionary" so all the updates are done atomically
			var childUpdates = ["/posts/\(key)": post,
			"/users/\(Global.uid)/posts/\(key)": time,
			"/timeline/\(Global.uid)/\(key)": time]

			//We download all users who follow our user and add the post to their timelines
			FirebaseHelper.getUsersWhoFollow(Global.uid) { (users: [User]) in
				
				for user in users {
					//Again, using the update dictionary so it's atomic
					childUpdates["/timeline/\(user.key)/\(key)"] = time
				}

				//Update everything in our dictionary. This method allows the updates to be atomic, which means either all of them succeed or no updates happen
				Global.databaseRef!.updateChildValues(childUpdates)
			}
		}
	}

	//Download the image data
	func downloadImage(path: String) {

		//First check if the image is in our cache so we don't re-download it
		imageData.value = Post.imageCache[self.postKey]

		//If the image is not in our cache, download it
		if imageData.value == nil {
			
			//print("Redownload")
			//Get the data stored inside the post's "path"
			Global.storage!.referenceWithPath(path).dataWithMaxSize(INT64_MAX) { (data, error) in
				if let data = data{
					//We succeeded in downloading, store the image
					self.imageData.value = UIImage(data: data, scale: 1.0)

					//Add the image to the cache so we don't re-download it later on
					Post.imageCache[self.postKey] = self.imageData.value
				}
			}
		}
	}
	
	func fetchLikes(){

		//If we already have the likes stored, don't download them again
		if (likes.value != nil) {
			return
		}

		//Download the likes and store them
		FirebaseHelper.getAllLikesForPost(self) { (usernames) in
			
			self.likes.value = usernames
		}
	}

	//Checks if a user likes a post to update the UI acordingly
	func doesUserLikePost(username: String) -> Bool {

		//If likes has a value, return wheather the username is in the like's array or not
		if let likes = likes.value {
			
			return likes.contains(username)
		} else {
			
			return false
		}
	}

	//Likes or unlikes a post depending on if the user had previously liked it or not
	func toggleLikePost(user: String) {

		//Notice how we update both the local array and the database so we dont have to redownload all the array at every toggle


		if (doesUserLikePost(user)) {
			//If post is liked, unlike it
			likes.value = likes.value?.filter { $0 != user }
			FirebaseHelper.unlikePost(self)
		} else {
			//If this post is not liked yet, like it
			likes.value?.append(user)
			FirebaseHelper.likePost(self)
		}
	}
	
}