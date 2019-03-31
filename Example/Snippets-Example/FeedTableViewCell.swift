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
	@IBOutlet var imageStackView : UIStackView!
	@IBOutlet var draftStatusLabel : UILabel!
	@IBOutlet var stackViewHeightConstraint : NSLayoutConstraint!
	
	var snippetsPost : SnippetsPost? = nil
	
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
		self.userImage.layer.cornerRadius = 8.0
		
		self.userImage.isUserInteractionEnabled = true
		self.userImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleAvatarTapped)))
    }

	func configure(_ dictionary : [String : Any])
	{
		self.fullName.text = nil
		self.userName.text = nil
		self.userImage.image = nil
		self.textView.text = nil
		self.stackViewHeightConstraint.constant = 0.0
		self.imageStackView.isHidden = true
		for view in self.imageStackView.arrangedSubviews {
			self.imageStackView.removeArrangedSubview(view)
		}

		let post : SnippetsPost = dictionary["post"] as! SnippetsPost
		
		self.snippetsPost = post
		
		self.draftStatusLabel.isHidden = !post.isDraft
		
		let images : [String] = dictionary["images"] as? [String] ?? []
		let attributedString : NSAttributedString = dictionary["attributedString"] as? NSAttributedString ?? NSAttributedString(string: "")
		
		self.textView.attributedText = attributedString
		
		self.userName.text = "@\(post.owner.userHandle)"
		self.fullName.text = post.owner.fullName


		for imagePath in images {
			self.loadImage(imagePath)
		}

		if let avatar = post.owner.userImage
		{
			self.userImage.image = avatar
		}
		else
		{
			post.owner.loadUserImage {
				DispatchQueue.main.async {
					if post.owner.userImage != nil {
						NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ImageLoadedNotification"), object: nil, userInfo: nil)
					}
				}
			}
		}
	}
	
	func loadImage(_ path : String) {
		
		self.stackViewHeightConstraint.constant = 44.0
		self.imageStackView.isHidden = false

		if let imageData = UUDataCache.shared.data(for: path) {
			if let image = UIImage(data: imageData) {
				let view = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
				let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
				imageView.image = image
				imageView.contentMode = .scaleAspectFill
				imageView.clipsToBounds = true
				view.clipsToBounds = true
				view.layer.cornerRadius = 2
				view.addSubview(imageView)
				self.imageStackView.addArrangedSubview(view)
				
				imageView.isUserInteractionEnabled = true
				imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openImageNotification(_:))))
				return
			}
		}

		UUHttpSession.get(url: path) { (parsedServerResponse) in
			if let image = parsedServerResponse.parsedResponse as? UIImage
			{
				if let imageData = image.pngData()
				{
					UUDataCache.shared.set(data: imageData, for: path)

					DispatchQueue.main.async {
						NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ImageLoadedNotification"), object: nil, userInfo: nil)
					}
				}
			}
		}

	}
	
	@objc func openImageNotification(_ gesture : UITapGestureRecognizer) {
		if let imageView = gesture.view as? UIImageView {
			DispatchQueue.main.async {
				NotificationCenter.default.post(name: NSNotification.Name(rawValue: "DisplayImageNotification"), object: imageView.image, userInfo: nil)
			}
		}
	}
	
	@IBAction func handleAvatarTapped() {
		DispatchQueue.main.async {
			NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ShowUserProfileNotification"), object: self.snippetsPost?.owner, userInfo: nil)
		}
	}
	
}
