//
//  ProfileHeaderTableViewCell.swift
//  Snippets-Example
//
//  Created by Jonathan Hays on 3/14/19.
//  Copyright © 2019 Micro.blog. All rights reserved.
//

import UIKit
import Snippets

class ProfileHeaderTableViewCell: UITableViewCell {

	@IBOutlet var userImage : UIImageView!
	@IBOutlet var fullNameLabel : UILabel!
	@IBOutlet var userNameLabel : UILabel!
	@IBOutlet var blogAddressLabel : UILabel!
	@IBOutlet var userDetailsLabel : UILabel!
	@IBOutlet var userFollowingLabel : UILabel!
	@IBOutlet var busyIndicator : UIActivityIndicatorView!
	
    override func awakeFromNib() {
        super.awakeFromNib()
    }
	
	func updateFromUser(_ user : SnippetsUser) {
		self.userFollowingLabel.text = ""
		self.fullNameLabel.text = user.fullName
		self.userNameLabel.text = user.userHandle
		
		self.blogAddressLabel.text = user.pathToWebSite
		self.userDetailsLabel.text = user.bio
		if user.followingCount > 0 {
			self.userFollowingLabel.text = "Following \(user.followingCount) micro-bloggers"
		}
		
		user.loadUserImage {
			DispatchQueue.main.async {
				self.userImage.image = user.userImage
			}
		}
	}

}
