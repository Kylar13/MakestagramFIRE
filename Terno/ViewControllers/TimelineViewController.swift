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
	var posts: [Post] = []
	var followUserKeys: [String] = []
	var postsFromThisUser: [String] = []
	
	let defaultRange = 0...4
	let additionalRangeSize = 5
	
	@IBOutlet weak var tableView: UITableView!
	
	var refreshControl: UIRefreshControl!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.tabBarController?.delegate = self
		
		refreshControl = UIRefreshControl()
		refreshControl.addTarget(self, action: #selector(TimelineViewController.refresh(_:)), forControlEvents: UIControlEvents.ValueChanged)
		tableView.addSubview(refreshControl)
	}
	
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		
		//Timeline Query goes here
		Global.startQuery = -DBL_MAX
		
		FirebaseHelper.timelineQuery() { (timelinePosts: [Post]) in
			
			self.posts = timelinePosts
			self.tableView.reloadData()
		}
	
	}
	
	func refresh(sender: AnyObject) {
		// Code to refresh table view
		Global.startQuery = -DBL_MAX
		
		FirebaseHelper.timelineQuery() { (timelinePosts: [Post]) in
			
			self.posts = timelinePosts
			self.tableView.reloadData()
			self.refreshControl.endRefreshing()
		}
	}
	
	func takePhoto() {
		// instantiate photo taking class, provide callback for when photo is selected
		photoTakingHelper = PhotoTakingHelper(viewController: self.tabBarController!) { (image: UIImage?) in
			if let image = image.value {
				
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

extension TimelineViewController: UITableViewDataSource {
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		// 1
		return posts.count
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		// 2
		let cell = tableView.dequeueReusableCellWithIdentifier("PostCell") as! PostTableViewCell
		
		self.posts[indexPath.row].downloadImage(self.posts[indexPath.row].imagePath)
		self.posts[indexPath.row].fetchLikes()
		
		if indexPath.row < posts.count - 1 {
			
			self.posts[indexPath.row + 1].downloadImage(self.posts[indexPath.row + 1].imagePath)
			self.posts[indexPath.row + 1].fetchLikes()
		}
		
		cell.post = self.posts[indexPath.row]
		
		if indexPath.row == posts.count - 1 {
			
			
			FirebaseHelper.timelineQuery() { (timelinePosts: [Post]) in
				
				let aux = self.posts.count
				self.posts.appendContentsOf(timelinePosts)
				
				if aux != self.posts.count {
					self.tableView.reloadData()
				}
			}
		}
		
		return cell
	}
}


