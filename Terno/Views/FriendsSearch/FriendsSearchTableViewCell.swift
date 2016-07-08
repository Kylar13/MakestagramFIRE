//
//  FriendsSearchTableViewCell.swift
//  Terno
//
//  Created by Ramon Pans on 07/07/16.
//  Copyright © 2016 Flatmates. All rights reserved.
//

import UIKit

protocol FriendsSearchTableViewCellDelegate: class {
	func cell(cell: FriendsSearchTableViewCell, didSelectFollowUser user: User)
	func cell(cell: FriendsSearchTableViewCell, didSelectUnfollowUser user: User)
}

class FriendsSearchTableViewCell: UITableViewCell {

	@IBOutlet weak var usernameLabel: UILabel!
	@IBOutlet weak var followButton: UIButton!
	weak var delegate: FriendsSearchTableViewCellDelegate?

	var user: User? {
		didSet {
			usernameLabel.text = user?.username
		}
	}
	
	var canFollow: Bool? = true {
		didSet {
			/*
			Change the state of the follow button based on whether or not
			it is possible to follow a user.
			*/
			if let canFollow = canFollow {
				followButton.selected = !canFollow
			}
		}
	}
	
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

	@IBAction func followButtonTapped(sender: AnyObject) {
		
		if let canFollow = canFollow where canFollow == true {
			delegate?.cell(self, didSelectFollowUser: user!)
			self.canFollow = false
		} else {
			delegate?.cell(self, didSelectUnfollowUser: user!)
			self.canFollow = true
		}
	}
}
