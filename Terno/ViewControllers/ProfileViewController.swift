//
//  ProfileViewController.swift
//  Terno
//
//  Created by Ramon Pans on 15/07/16.
//  Copyright © 2016 Flatmates. All rights reserved.
//

import UIKit

class ProfileViewController: UIViewController {
	
	var posts: [Post] = []

	@IBOutlet weak var tableView: UITableView!
	
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
	
	override func viewDidAppear(animated: Bool) {

		FirebaseHelper.getPostsByUser(Global.uid) { (userPosts: [Post]) in
			
			//print("Hey there!! We had \(userPosts.count) posts!!!")
			self.posts = userPosts
			self.tableView.reloadData()
		}
		
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

extension ProfileViewController: UITableViewDataSource {
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		
		return posts.count
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		
		let cell = tableView.dequeueReusableCellWithIdentifier("PostCell") as! PostTableViewCell
		
		if indexPath.row == 0 {
			
			self.posts[indexPath.row].downloadImage(self.posts[indexPath.row].imagePath)
			self.posts[indexPath.row].fetchLikes()
		}
		
		if indexPath.row < posts.count - 1 {
			
			self.posts[indexPath.row + 1].downloadImage(self.posts[indexPath.row + 1].imagePath)
			self.posts[indexPath.row + 1].fetchLikes()
		}
		
		cell.post = self.posts[indexPath.row]
		
		return cell
	}
}

