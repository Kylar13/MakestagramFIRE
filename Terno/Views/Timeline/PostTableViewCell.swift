//
//  PostTableViewCell.swift
//  Terno
//
//  Created by Ramon Pans on 01/07/16.
//  Copyright © 2016 Flatmates. All rights reserved.
//

import UIKit
import Bond
import DateTools

class PostTableViewCell: UITableViewCell {

	@IBOutlet weak var postImageView: UIImageView!
	@IBOutlet weak var likesIconImageView: UIImageView!
	@IBOutlet weak var likesLabel: UILabel!
	@IBOutlet weak var likeButton: UIButton!
	@IBOutlet weak var moreButton: UIButton!
	
	@IBOutlet weak var postTimeLabel: UILabel!
	@IBOutlet weak var usernameLabelButton: UIButton!
	
	var postDisposable: DisposableType?
	var likeDisposable: DisposableType?
	
	var post: Post? {
		didSet {

			postDisposable?.dispose()
			likeDisposable?.dispose()
			
			if let oldValue = oldValue where oldValue != post {
				// 2
				oldValue.imageData.value = nil
			}
			
			if let post = post {
				
				usernameLabelButton.setTitle(post.authorUsername, forState: .Normal)
				usernameLabelButton.setTitle(post.authorKey, forState: .Disabled)
				
				let date = NSDate(timeIntervalSince1970: 0-post.timestamp)
				postTimeLabel.text = date.shortTimeAgoSinceDate(NSDate())
				
				postDisposable = post.imageData.bindTo(postImageView.bnd_image)
				likeDisposable = post.likes.observe { (value: [String]?) -> () in
					// 3
					if let value = value {
						// 4
						self.likesLabel.text = value.joinWithSeparator(", ")
						// 5
						self.likeButton.selected = value.contains(Global.username)
						// 6
						self.likesIconImageView.hidden = (value.count == 0)
					} else {
						// 7
						self.likesLabel.text = ""
						self.likeButton.selected = false
						self.likesIconImageView.hidden = true
					}
				}
			}
		}
	}
	
	@IBAction func moreButtonTapped(sender: AnyObject) {
		
	}
	
	@IBAction func likeButtonTapped(sender: AnyObject) {
		
		post?.toggleLikePost(Global.username)
	}
	
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
	
}
