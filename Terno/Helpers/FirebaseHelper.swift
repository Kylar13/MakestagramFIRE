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


	// Calls a callback with the array of posts from a user's timeline
	static func timelineQuery(completionBlock: ([Post]) -> Void) {
		
		//This queries the database for the posts ordered by their timestamp
		Global.databaseRef?.child("timeline").child(Global.uid).queryOrderedByValue().queryStartingAtValue(Global.startQuery).queryLimitedToFirst(10).observeSingleEventOfType(.Value) { (snapshot: FIRDataSnapshot) in
			
			var posts: [Post] = []

			//We create a dispatch group in order to be able to wait for all posts to finish downloading
			let waitForAllPosts = dispatch_group_create()

			//For every key in the timestamp, download all the information associated to that post
			for entry in snapshot.children {
				let postKey = entry as! FIRDataSnapshot

				//Enter the dispatch group (Start of a new post's download)
				dispatch_group_enter(waitForAllPosts)

				// Access the post with the key we got from the tree "timeline" in the "posts" tree where all the info is
				Global.databaseRef?.child("posts").child(postKey.key).observeSingleEventOfType(.Value) { (snapshot: FIRDataSnapshot) in

					//Create a Post object and store all the values from our query
					let post = Post()

					post.postKey = postKey.key
					post.authorKey = snapshot.value!["uid"] as! String
					post.authorUsername = snapshot.value!["author"] as! String
					post.imagePath = snapshot.value!["imagePath"] as! String
					post.timestamp = snapshot.value!["timestamp"] as! NSTimeInterval

					//Debug print
					//print("We have retrieved a post with: \n\t author: \(post.authorUsername) \n\t author key: \(post.authorKey) \n\t image path: \(post.imagePath) \n\t timestamp: \(post.timestamp)")
					
					// Add post to the callback array
					posts.append(post)

					//Leave the dispatch group (The post finished downloading)
					dispatch_group_leave(waitForAllPosts)
				}
			}

			//This blocks the thread untill everything that entered the dispatch group has left (All posts have been downloaded)
			dispatch_group_notify(waitForAllPosts, dispatch_get_main_queue()) {
				
				if posts.count > 0 {

					//Save the value where we started to download posts for later use
					let oldTimestamp = Global.startQuery

					//Debug print
					//print("Getting only \(posts.count) posts, starting from \(Global.startQuery) and until \(posts[posts.count - 1].timestamp)")

					//If posts isn't empty, recalculate the initial timestamp so we can load the next posts when the users scrolls
					Global.startQuery = posts[posts.count - 1].timestamp

					//If the first post has exactly the value of the old timestamp means we already downloaded that post in the last query
					if posts[0].timestamp == oldTimestamp {
						posts.removeAtIndex(0)
					}
					
				}

				//Once we're all done, call the callback passing posts as an argument
				completionBlock(posts)
			}
		}
	}

	//Function that, given a user's key, returns all posts from that user
	//Currently not in use in this version
	static func getPostsByUser(userKey: String, completionBlock: ([Post]) -> Void) {
		
		var posts: [Post] = []
		
		//Get all the post keys from the user's post list
		Global.databaseRef?.child("users").child(userKey).child("posts").observeSingleEventOfType(.Value) { (snapshot: FIRDataSnapshot) in

			//We create a dispatch group in order to be able to wait for all posts to finish downloading
			let waitForAllPosts = dispatch_group_create()

			//For every key in the user's posts list, download all the information associated to that post
			for post in snapshot.children {
				let data = post as! FIRDataSnapshot

				//Debug print
				//print("User with ID: \(userKey) had post with id: \(data.key)")

				//Enter the dispatch group (Start of a new post's download)
				dispatch_group_enter(waitForAllPosts)
				
				Global.databaseRef?.child("posts").child(data.key).observeSingleEventOfType(.Value) { (snapshot: FIRDataSnapshot) in

					//Create a Post object and store all the values from our query
					let post = Post()

					post.postKey = data.key
					post.authorKey = snapshot.value!["uid"] as! String
					post.authorUsername = snapshot.value!["author"] as! String
					post.imagePath = snapshot.value!["imagePath"] as! String
					post.timestamp = snapshot.value!["timestamp"] as! NSTimeInterval

					//Debug print
					//print("We have retrieved a post with: \n\t author: \(post.authorUsername) \n\t author key: \(post.authorKey) \n\t image path: \(post.imagePath) \n\t timestamp: \(post.timestamp)")

					// Add post to the callback array
					posts.append(post)

					//Leave the dispatch group (The post finished downloading)
					dispatch_group_leave(waitForAllPosts)
				}
			}

			//This blocks the thread untill everything that entered the dispatch group has left (All posts have been downloaded)
			dispatch_group_notify(waitForAllPosts, dispatch_get_main_queue()) {
				//Once we're all done, call the callback passing posts as an argument
				completionBlock(posts)
			}
			
		}
	}
	
	//MARK: Follows

	// Calls a callback with the array of users that the given user follows
	static func getFollowedUsers(userKey: String, completionBlock: ([User]) -> Void) {

		//Get the keys from the users the given user (userKey) follows
		Global.databaseRef?.child("follows").child(userKey).observeSingleEventOfType(.Value) { (snapshot: FIRDataSnapshot) in
			
			var followUserKeys: [User] = []

			//We create a dispatch group in order to be able to wait for all the usernames to download (We store only the keys in the "follows" tree)
			let waitForUsernames = dispatch_group_create()
			let waitForLoop = dispatch_group_create()

			//For every key in the user's "follows" list, download the username associated to that key
			for entry in snapshot.children {
				let userSnap = entry as!FIRDataSnapshot

				//Enter the dispatch group (A new download begins)
				dispatch_group_enter(waitForUsernames)
				dispatch_group_enter(waitForLoop)
				
				//Create the User object and populate it
				let user = User()
				user.key = userSnap.key
				
				//Acces the "allUsers" tree to get the username
				Global.databaseRef?.child("allUsers").child(userSnap.key).observeSingleEventOfType(.Value) { (snapshot: FIRDataSnapshot) in

					user.username = snapshot.value as! String

					//Leave the dispatch group (Download has ended)
					dispatch_group_leave(waitForUsernames)
				}

				//We block the thread here to make sure the username has finished downloading before we append the User object to the callback array
				dispatch_group_notify(waitForUsernames, dispatch_get_main_queue()) {
					//print("Add user \(user.key) to the follower array")
					followUserKeys.append(user)
					dispatch_group_leave(waitForLoop)
				}
			}

			dispatch_group_notify(waitForUsernames, dispatch_get_main_queue()) {
				//Once we are all done, call the given callback
				completionBlock(followUserKeys)
			}
		}
	}

	// Calls a callback with the array of users that follow the given user
	static func getUsersWhoFollow(userKey: String, completionBlock: ([User]) -> Void) {

		//Get the keys from the users who follow the given user (userKey)
		Global.databaseRef?.child("isFollowedBy").child(userKey).observeSingleEventOfType(.Value) { (snapshot: FIRDataSnapshot) in
			
			var usersWhoFollowKeys: [User] = []

			//We create a dispatch group in order to be able to wait for all the usernames to download (We store only the keys in the "isFollowedBy" tree)
			let waitForUsernames = dispatch_group_create()
			let waitForLoop = dispatch_group_create()

			//For every key in the user's "isFollowedBy" list, download the username associated to that key
			for entry in snapshot.children {

				let userSnap = entry as!FIRDataSnapshot

				//Enter the dispatch group (A new download begins)
				dispatch_group_enter(waitForUsernames)
				dispatch_group_enter(waitForLoop)

				let user = User()
				user.key = userSnap.key

				//Acces the "allUsers" tree to get the username
				Global.databaseRef?.child("allUsers").child(userSnap.key).observeSingleEventOfType(.Value) { (snapshot: FIRDataSnapshot) in

					//Create the User object and populate it
					user.username = snapshot.value as! String

					//Leave the dispatch group (Download has ended)
					dispatch_group_leave(waitForUsernames)
				}

				//We block the thread here to make sure the username has finished downloading before we append the User object to the callback array
				dispatch_group_notify(waitForUsernames, dispatch_get_main_queue()) {
					usersWhoFollowKeys.append(user)
					dispatch_group_leave(waitForLoop)
				}
			}

			dispatch_group_notify(waitForUsernames, dispatch_get_main_queue()) {
				//Once we are all done, call the given callback
				completionBlock(usersWhoFollowKeys)
			}
		}
	}

	// This function does a couple of things:
		//Adds userKey to the list of users the current user follows
		//Adds the current user to the list of users who follow userKey

		//For every post userKey has, add it to the current user's timeline
	static func followUser(userKey: String){

		//We save the timestamp inverted because that allows us to order the posts from newer to older
		let time = 0 - NSDate().timeIntervalSince1970

		//Update "follows" and "isFollowedBy" trees
		Global.databaseRef?.child("follows").child(Global.uid).child(userKey).setValue(time)
		Global.databaseRef?.child("isFollowedBy").child(userKey).child(Global.uid).setValue(time)

		//Download all of userKey's posts (Remember, we only store the keys in this tree)
		Global.databaseRef?.child("users").child(userKey).child("posts").observeSingleEventOfType(.Value) { (snapshot: FIRDataSnapshot) in
			
			for eachPost in snapshot.children {

				//For every post, create a new entry in the current user's timeline
				let post = eachPost as! FIRDataSnapshot
				Global.databaseRef?.child("timeline").child(Global.uid).child(post.key).setValue(post.value)
			}
		}

	}

	// This function undoes everything "followUser" does by setting the values to nil
	static func unfollowUser(userKey: String){

		//Update "follows" and "isFollowedBy" trees
		Global.databaseRef?.child("follows").child(Global.uid).child(userKey).setValue(nil)
		Global.databaseRef?.child("isFollowedBy").child(userKey).child(Global.uid).setValue(nil)

		//Download all of userKey's posts (Remember, we only store the keys in this tree)
		Global.databaseRef?.child("users").child(userKey).child("posts").observeSingleEventOfType(.Value) { (snapshot: FIRDataSnapshot) in
			
			for eachPost in snapshot.children {

				//For every post, create a new entry in the current user's timeline
				let post = eachPost as! FIRDataSnapshot
				Global.databaseRef?.child("timeline").child(Global.uid).child(post.key).setValue(nil)
			}
		}
		
	}
	
	// MARK: Likes

	// This function creates a like object and stores it in the database
	static func likePost(post: Post){

		//Create a like object (We store the username here so it's easier to display the likes later)
		let like = ["username": Global.username,
		            "timestamp": 0 - NSDate().timeIntervalSince1970]

		//Store the like in the apropiate subtree in the database
		Global.databaseRef?.child("likes").child(post.postKey).child(Global.uid).setValue(like)
	}

	// Remove the like object from the database
	static func unlikePost(post: Post){

		//Removes the like from the database
		Global.databaseRef!.child("likes").child(post.postKey).child(Global.uid).removeValue()
	}

	// This function gathers all likes for a given post and returns an array of the user's usernames
	static func getAllLikesForPost(post: Post, completionBlock: ([String]) -> Void){

		//Download all likes for the given post
		Global.databaseRef?.child("likes").child(post.postKey).observeSingleEventOfType(.Value) { (snapshot: FIRDataSnapshot) in
			
			var users: [String] = []

			//This dispatch group is to make sure the user who liked the post is still valid
			let isUserValid = dispatch_group_create()
			
			for like in snapshot.children {
				
				let user = like as! FIRDataSnapshot

				//Enter the dispath group and set isValid to false
				dispatch_group_enter(isUserValid)
				var isValid = false
				var username = ""

				//Download the user with that key
				Global.databaseRef?.child("allUsers").child(user.key).observeSingleEventOfType(.Value) { (snapshot: FIRDataSnapshot) in

					//If it has a value associated, means it exists, so we need to set isValid to true
					if snapshot.value != nil {
						isValid = true
						username = snapshot.value as! String
					}

					//Regardless if the user existed or not, leave the group (To avoid deadlock)
					dispatch_group_leave(isUserValid)
				}

				//This method holds the thread so we know we can trust the isValid value once we are inside of it
				dispatch_group_notify(isUserValid, dispatch_get_main_queue()) {
				
					if isValid {
						//If isValid is true, then username holds the user's username
						users.append(username)
					}
				}
			}

			//Call the given callback passing the array of usernames as an argument
			completionBlock(users)
		}
	}

	// Returns the key and the username for the first 20 usernames
	static func first20Users(completionBlock: ([User]) -> Void) {
		
		var usernames: [User] = []

		//Download the first 20 entries in the "allUsers" tree
		Global.databaseRef?.child("allUsers").queryLimitedToFirst(20).observeSingleEventOfType(.Value) { (snapshot: FIRDataSnapshot) in
			
			for entry in snapshot.children {
				let userSnap = entry as! FIRDataSnapshot

				//Create the User object, populate it and store it in the array
				let user = User()
				user.key = userSnap.key
				user.username = userSnap.value as! String

				usernames.append(user)
			}

			//Take out the current user from the array
			usernames = usernames.filter({ $0.username != Global.username })

			//Call the callback
			completionBlock(usernames)
		}
	}

	// Searches the database to find any users who match with the given string
	static func searchUsers(search: String, completionBlock: ([User]) -> Void){
		
		var matches: [User] = []

		//We perform the search in the "search" tree because it has all usernames stored in lowercase
		Global.databaseRef?.child("search").observeSingleEventOfType(.Value) { (snapshot: FIRDataSnapshot) in
			
			for entry in snapshot.children {
				let userSnap = entry as! FIRDataSnapshot

				//For every entry, if the username contains the search string, add it to the array
				if (userSnap.value as! String).containsString(search) {

					//Populate the User object and store it in the array
					let user = User()
					user.key = userSnap.key
					user.username = userSnap.value as! String

					matches.append(user)
				}
			}
				
			completionBlock(matches)
		}
		
		
	}
	
}