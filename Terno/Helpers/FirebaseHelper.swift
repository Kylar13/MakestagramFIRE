//
//  FirebaseHelper.swift
//  Terno
//
//  Created by Ramon Pans on 01/07/16.
//  Copyright © 2016 Flatmates. All rights reserved.
//

import Foundation
import FirebaseStorage
import FirebaseDatabase
import Darwin

class FirebaseHelper {
	
	static func timelineQuery(completitionBlock: ([Post]) -> Void) {
		
		//This should return the posts ordered by their timestamp
		Global.databaseRef?.child("timeline").child(Global.uid).queryOrderedByValue().queryStartingAtValue(Global.startQuery).queryLimitedToFirst(10).observeSingleEventOfType(.Value) { (snapshot: FIRDataSnapshot) in
			
			var posts: [Post] = []
			
			let waitForAllPosts = dispatch_group_create()
			
			//print("Post count INSIDE is \(snapshot.childrenCount)")
			
			for entry in snapshot.children {
				let postKey = entry as! FIRDataSnapshot
				
				dispatch_group_enter(waitForAllPosts)
				
				Global.databaseRef?.child("posts").child(postKey.key).observeSingleEventOfType(.Value) { (snapshot: FIRDataSnapshot) in
					
					let post = Post()
					post.postKey = postKey.key
					
					post.authorKey = snapshot.value!["uid"] as! String
					post.authorUsername = snapshot.value!["author"] as! String
					post.imagePath = snapshot.value!["imagePath"] as! String
					post.timestamp = snapshot.value!["timestamp"] as! NSTimeInterval
					
					print("We have retrieved a post with: \n\t author: \(post.authorUsername) \n\t author key: \(post.authorKey) \n\t image path: \(post.imagePath) \n\t timestamp: \(post.timestamp)")
					
					
					posts.append(post)
					
					dispatch_group_leave(waitForAllPosts)
				}
			}
			
			dispatch_group_notify(waitForAllPosts, dispatch_get_main_queue()) {
				
				if posts.count > 0 {
					let oldTimestamp = Global.startQuery
					print("Getting only \(posts.count) posts, starting from \(Global.startQuery) and until \(posts[posts.count - 1].timestamp)")
					Global.startQuery = posts[posts.count - 1].timestamp
					
					if posts[0].timestamp == oldTimestamp {
						posts.removeAtIndex(0)
					}
					
				}
				
				completitionBlock(posts)
			}
		}
	}
	
	static func getPostsByUser(userKey: String, completitionBlock: ([Post]) -> Void) {
		
		var posts: [Post] = []
		
		//Get all the post keys from the user's post list
		Global.databaseRef?.child("users").child(userKey).child("posts").observeEventType(.Value) { (snapshot: FIRDataSnapshot) in
			
			let waitForAllPosts = dispatch_group_create()
			
			for post in snapshot.children {
				
				let data = post as! FIRDataSnapshot
				print("User with ID: \(userKey) had post with id: \(data.key)")
				dispatch_group_enter(waitForAllPosts)
				
				//For every post, download all post data and store it in posts array
				let post = Post()
				post.postKey = data.key
				
				Global.databaseRef?.child("posts").child(data.key).observeEventType(.Value) { (snapshot: FIRDataSnapshot) in
					
					post.authorKey = snapshot.value!["uid"] as! String
					post.authorUsername = snapshot.value!["author"] as! String
					post.imagePath = snapshot.value!["imagePath"] as! String
					post.timestamp = snapshot.value!["timestamp"] as! NSTimeInterval
					
					print("We have retrieved a post with: \n\t author: \(post.authorUsername) \n\t author key: \(post.authorKey) \n\t image path: \(post.imagePath) \n\t timestamp: \(post.timestamp)")
					
					
					posts.append(post)
					Global.databaseRef?.child("posts").child(snapshot.key).removeAllObservers()
					
					dispatch_group_leave(waitForAllPosts)
				}
			}
			
			dispatch_group_notify(waitForAllPosts, dispatch_get_main_queue()) {
				Global.databaseRef?.child("users").child(userKey).child("posts").removeAllObservers()
				completitionBlock(posts)
			}
			
		}
	}
	
	//MARK: Follows
	
	static func getFollowedUsers(userKey: String, completitionBlock: ([User]) -> Void) {
		
		Global.databaseRef?.child("follows").child(userKey).observeEventType(.Value) { (snapshot: FIRDataSnapshot) in
			
			var followUserKeys: [User] = []
			let waitForUsernames = dispatch_group_create()
			
			for entry in snapshot.children {
				let userSnap = entry as!FIRDataSnapshot
				let user = User()
				user.key = userSnap.key
				dispatch_group_enter(waitForUsernames)
				Global.databaseRef?.child("allUsers").child(user.key).observeSingleEventOfType(.Value) { (snapshot: FIRDataSnapshot) in
					user.username = snapshot.value as! String
					dispatch_group_leave(waitForUsernames)
				}
				
				dispatch_group_notify(waitForUsernames, dispatch_get_main_queue()) {
					followUserKeys.append(user)
				}
			}
			
			let myUser = User()
			myUser.key = Global.uid
			myUser.username = Global.username
			
			followUserKeys.append(myUser)
			
			Global.databaseRef?.child("follows").child(userKey).removeAllObservers()
			completitionBlock(followUserKeys)
		}
	}
	
	static func getUsersWhoFollow(userKey: String, completitionBlock: ([User]) -> Void) {
		
		Global.databaseRef?.child("isFollowedBy").child(userKey).observeEventType(.Value) { (snapshot: FIRDataSnapshot) in
			
			var usersWhoFollowKeys: [User] = []
			let waitForUsernames = dispatch_group_create()
			
			for entry in snapshot.children {
				let userSnap = entry as!FIRDataSnapshot
				let user = User()
				user.key = userSnap.key
				dispatch_group_enter(waitForUsernames)
				Global.databaseRef?.child("allUsers").child(user.key).observeSingleEventOfType(.Value) { (snapshot: FIRDataSnapshot) in
					user.username = snapshot.value as! String
					dispatch_group_leave(waitForUsernames)
				}
				
				dispatch_group_notify(waitForUsernames, dispatch_get_main_queue()) {
					usersWhoFollowKeys.append(user)
				}
			}
			
			Global.databaseRef?.child("follows").child(userKey).removeAllObservers()
			completitionBlock(usersWhoFollowKeys)
		}
	}
	
	static func followUser(userKey: String){
		
		let time = 0 - NSDate().timeIntervalSince1970
		
		Global.databaseRef?.child("follows").child(Global.uid).child(userKey).setValue(time)
		Global.databaseRef?.child("isFollowedBy").child(userKey).child(Global.uid).setValue(time)
		
		Global.databaseRef?.child("users").child(userKey).child("posts").observeSingleEventOfType(.Value) { (snapshot: FIRDataSnapshot) in
			
			for eachPost in snapshot.children {
				
				let post = eachPost as! FIRDataSnapshot
				Global.databaseRef?.child("timeline").child(Global.uid).child(post.key).setValue(post.value)
			}
		}

	}
	
	static func unfollowUser(userKey: String){
		
		Global.databaseRef?.child("follows").child(Global.uid).child(userKey).setValue(nil)
		Global.databaseRef?.child("isFollowedBy").child(userKey).child(Global.uid).setValue(nil)
		
		Global.databaseRef?.child("users").child(userKey).child("posts").observeSingleEventOfType(.Value) { (snapshot: FIRDataSnapshot) in
			
			for eachPost in snapshot.children {
				
				let post = eachPost as! FIRDataSnapshot
				Global.databaseRef?.child("timeline").child(Global.uid).child(post.key).setValue(nil)
			}
		}
		
	}
	
	// MARK: Likes
	
	static func likePost(post: Post){
		
		let like = ["username": Global.username,
		            "timestamp": 0 - NSDate().timeIntervalSince1970]
		
		let update = ["/likes/\(post.postKey)/\(Global.uid)": like]
		
		Global.databaseRef!.updateChildValues(update)
	}
	
	static func unlikePost(post: Post){
		
		Global.databaseRef!.child("likes").child(post.postKey).child(Global.uid).removeValue()
	}
	
	static func getAllLikesForPost(post: Post, completitionBlock: ([String]) -> Void){
		
		Global.databaseRef?.child("likes").child(post.postKey).observeEventType(.Value) { (snapshot: FIRDataSnapshot) in
			
			var users: [String] = []
			
			let waitForAllLikes = dispatch_group_create()
			let isUserValid = dispatch_group_create()
			
			for like in snapshot.children {
				
				let user = like as! FIRDataSnapshot
				dispatch_group_enter(waitForAllLikes)
				dispatch_group_enter(isUserValid)
				
				var isValid = false
				
				Global.databaseRef?.child("users").child(user.key).observeEventType(.Value) { (snapshot: FIRDataSnapshot) in
					if snapshot.value != nil {
						isValid = true
						dispatch_group_leave(isUserValid)
					}
				}
				
				dispatch_group_notify(isUserValid, dispatch_get_main_queue()) {
				
					if isValid {
					
						Global.databaseRef?.child("likes").child(post.postKey).child(user.key).observeEventType(.Value) { (snapshot: FIRDataSnapshot) in
							
							users.append(snapshot.value!["username"] as! String)
							
							Global.databaseRef?.child("likes").child(post.postKey).child(user.key).removeAllObservers()
							dispatch_group_leave(waitForAllLikes)
						}
					}
					else{
						dispatch_group_leave(waitForAllLikes)
					}
				}
			}
			
			dispatch_group_notify(waitForAllLikes, dispatch_get_main_queue()) {
				Global.databaseRef?.child("likes").child(post.postKey).removeAllObservers()
				completitionBlock(users)
			}
		}
	}
	
	static func allUsers(completitionBlock: ([User]) -> Void) {
		
		var usernames: [User] = []
		
		Global.databaseRef?.child("allUsers").queryLimitedToFirst(20).observeSingleEventOfType(.Value) { (snapshot: FIRDataSnapshot) in
			
			for entry in snapshot.children {
				let userSnap = entry as! FIRDataSnapshot
				let user = User()
				user.key = userSnap.key
				user.username = userSnap.value as! String
				usernames.append(user)
			}
			
			usernames = usernames.filter({ $0.username != Global.username })
			
			completitionBlock(usernames)
		}
	}
	
	static func searchUsers(search: String, matches: [User], completitionBlock: ([User]) -> Void){
		
		var newMatches = matches
		
		Global.databaseRef?.child("search").queryLimitedToFirst(50).observeSingleEventOfType(.Value) { (snapshot: FIRDataSnapshot) in
			
			
			for entry in snapshot.children {
				let userSnap = entry as! FIRDataSnapshot
				if (userSnap.value as! String).containsString(search) {
					let user = User()
					user.key = userSnap.key
					user.username = userSnap.value as! String
					newMatches.append(user)
				}
			}
			
			if snapshot.childrenCount < 50 {
				
				completitionBlock(newMatches)
			}
			else{
				//completitionBlock(newMatches)
				searchUsers(search, matches: newMatches, completitionBlock: completitionBlock)
			}
			
		}
		
		
	}
	
}