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
				FirebaseHelper.allUsers(updateList)
				
			case .SearchMode:
				let searchText = searchBar?.text ?? ""
				FirebaseHelper.searchUsers(searchText, matches: [], completitionBlock: updateList)
			}
		}
	}
	
	func updateList(results: [User]) {
		self.users = results
		self.tableView.reloadData()
		
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		
		state = .DefaultMode
		
		// fill the cache of a user's followees
		FirebaseHelper.getFollowedUsers(Global.uid) { (usernames: [User]) -> Void in
			
			self.followingUsers = usernames ?? []
		}
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
			// check if current user is already following displayed user
			// change button appereance based on result
			cell.canFollow = true
			
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
		FirebaseHelper.searchUsers(searchText, matches: [], completitionBlock: updateList)
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
