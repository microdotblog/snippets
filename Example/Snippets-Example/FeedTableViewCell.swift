//
//  FeedTableViewCell.swift
//  SnipIt
//
//  Created by Jonathan Hays on 10/23/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

import UIKit
import UUSwift
import Snippets

class FeedTableViewCell: UITableViewCell {

	@IBOutlet var fullName : UILabel!
	@IBOutlet var userName : UILabel!
	@IBOutlet var userImage : UIImageView!
	@IBOutlet var textView : UITextView!
	
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
		self.userImage.layer.cornerRadius = 8.0
    }

	func configure(_ dictionary : [String : Any])
	{
		let post : SnippetsPost = dictionary["post"] as! SnippetsPost
		
		self.fullName.text = nil
		self.userName.text = nil
		self.userImage.image = nil
		self.textView.text = nil

		let attributedString : NSAttributedString = dictionary["attributedString"] as? NSAttributedString ?? NSAttributedString(string: "")
		
		self.textView.attributedText = attributedString
		
		self.userName.text = "@\(post.owner.userHandle)"
		self.fullName.text = post.owner.fullName

		if let avatar = post.owner.userImage
		{
			self.userImage.image = avatar
		}
		else
		{
			post.owner.loadUserImage {
				DispatchQueue.main.async {
					NotificationCenter.default.post(name: NSNotification.Name(rawValue: "UserAvatarImageLoaded"), object: nil, userInfo: nil)
				}
			}
		}
	}
	
	
	func loadUserImage(_ userImagePath : String)
	{
		if let imageData = UUDataCache.shared.data(for: userImagePath)
		{
			if let image = UIImage(data: imageData)
			{
				self.userImage.image = image
				return
			}
		}

		// If we have gotten here, then there is no image available to display so we need to fetch it...
		UUHttpSession.get(userImagePath, [:]) { (parsedServerResponse) in
			if let image = parsedServerResponse.parsedResponse as? UIImage
			{
				if let imageData = image.pngData()
				{
					UUDataCache.shared.set(data: imageData, for: userImagePath)
					
				}
			}
		}
	}
	
	
}
