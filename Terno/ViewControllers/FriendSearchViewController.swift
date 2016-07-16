//
//  FriendSearchViewController.swift
//  Terno
//
//  Created by Ramon Pans on 29/06/16.
//  Copyright © 2016 Flatmates. All rights reserved.
//

import UIKit

class FriendSearchViewController: UIViewController {
	
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var searchBar: UISearchBar!
	
	var users: [User] = []
	
	var followingUsers: [User]? {
		didSet {
			
			tableView.reloadData()
		}
	}
	
	enum State {
		case DefaultMode
		case SearchMode
	}
	
	var state: State = .DefaultMode {
		didSet {
			switch (state) {
			case .DefaultMode:
				FirebaseHelper.first20Users(updateList)
				
			case .SearchMode:
				let searchText = searchBar?.text ?? ""
				
				let queryText = searchText.lowercaseString
				
				FirebaseHelper.searchUsers(queryText, completionBlock: updateList)
			}
		}
	}
	
	func updateList(results: [User]) {
		self.users = results
		//print("This search returned \(results.count)")
		self.tableView.reloadData()
		
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		
		state = .DefaultMode
		
		//Fill the cache of a user's followees
		FirebaseHelper.getFollowedUsers(Global.uid) { (usernames: [User]) -> Void in
			
			self.followingUsers = usernames ?? []
		}
		
		searchBar.layer.cornerRadius = 6
		searchBar.clipsToBounds = true
	}

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension FriendSearchViewController: UITableViewDataSource {
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.users.count ?? 0
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("UserCell") as! FriendsSearchTableViewCell
		
		let user = users[indexPath.row]
		cell.user = user
		
		if let followingUsers = followingUsers {

			//Check if current user is already following displayed user in order to change the button appearance
			cell.canFollow = true
			
			//print("The follower array contains \(followingUsers.count) users")
			
			for item in followingUsers {
				if item.key == user.key {
					cell.canFollow = false
					break
				}
			}
		}
		
		cell.delegate = self
		return cell
	}
}

extension FriendSearchViewController: UISearchBarDelegate {
	
	func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
		searchBar.setShowsCancelButton(true, animated: true)
		state = .SearchMode
	}
	
	func searchBarCancelButtonClicked(searchBar: UISearchBar) {
		searchBar.resignFirstResponder()
		searchBar.text = ""
		searchBar.setShowsCancelButton(false, animated: true)
		state = .DefaultMode
	}
	
	func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
		FirebaseHelper.searchUsers(searchText, completionBlock: updateList)
	}
	
}

extension FriendSearchViewController: FriendsSearchTableViewCellDelegate {
	
	func cell(cell: FriendsSearchTableViewCell, didSelectFollowUser user: User) {
		FirebaseHelper.followUser(user.key)
		// update local cache
		followingUsers?.append(user)
	}
	
	func cell(cell: FriendsSearchTableViewCell, didSelectUnfollowUser user: User) {
		if let followingUsers = followingUsers {
			FirebaseHelper.unfollowUser(user.key)
			// update local cache
			self.followingUsers = followingUsers.filter({$0.key != user.key})
		}
	}
	
}
