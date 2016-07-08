//
//  PostTableViewCell.swift
//  Terno
//
//  Created by Ramon Pans on 01/07/16.
//  Copyright © 2016 Flatmates. All rights reserved.
//

import UIKit
import Bond

class PostTableViewCell: UITableViewCell {

	@IBOutlet weak var postImageView: UIImageView!
	@IBOutlet weak var likesIconImageView: UIImageView!
	@IBOutlet weak var likesLabel: UILabel!
	@IBOutlet weak var likeButton: UIButton!
	@IBOutlet weak var moreButton: UIButton!
	
	var postDisposable: DisposableType?
	var likeDisposable: DisposableType?
	
	var post: Post? {
		didSet {

			postDisposable?.dispose()
			likeDisposable?.dispose()
			
			if let post = post {
				
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
