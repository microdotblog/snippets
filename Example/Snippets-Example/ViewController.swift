//
//  ViewController.swift
//  Snippets-Example
//
//  Created by Jonathan Hays on 10/21/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

import UIKit
import UUSwift
import Snippets

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

	// User display elements
	@IBOutlet var userImage : UIImageView!
	@IBOutlet var userName : UILabel!

	// Login elements
	@IBOutlet var loginErrorLabel : UILabel!
	@IBOutlet var emailAddressField : UITextField!
	@IBOutlet var loginPopUpView : UIView!
	
	// Post elements
	@IBOutlet var postView : UIView!
	@IBOutlet var postTextField : UITextField!
	@IBOutlet var postButton : UIButton!
	
	// Feed display elements
	@IBOutlet var tableView : UITableView!
	var feedItems : [[String : Any]] = []

	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		self.loginPopUpView.layer.cornerRadius = 8.0
		self.userImage.layer.cornerRadius = 8.0
		
		NotificationCenter.default.addObserver(self, selector: #selector(handleImageLoadedNotification(_:)), name: NSNotification.Name(rawValue: "UserAvatarImageLoaded"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleTemporaryTokenReceivedNotification(_:)), name: NSNotification.Name("TemporaryTokenReceivedNotification"), object: nil)
		
		// If we have a valid token, we don't need to show the login popup
		if self.permanentToken() != nil
		{
			Snippets.shared.configure(permanentToken: self.permanentToken()!, blogUid: nil)
			
			self.postView.isHidden = false
			self.loginPopUpView.isHidden = true
			self.updateUserTimeline()
			self.updateUserConfiguration()
		}
	}

	func updateUserTimeline()
	{
		//Snippets.shared.fetchUserTimeline { (error, items) in
		//Snippets.shared.fetchUserFavorites { (error, items) in


		//let user = SnippetsUser()
		//user.userHandle = "manton"
		//Snippets.shared.fetchUserPosts(user: user) { (error, items) in

		//let post = SnippetsPost()
		//post.identifier = "984880"
		//Snippets.shared.fetchConversation(post: post) { (error, items) in
		
		Snippets.shared.fetchDiscoverTimeline(collection: "books") { (error, items) in
			
			var parsedItems : [[String : Any]] = []
			
			for item in items {
				var dictionary = self.extractImages(html: item.htmlText)
				dictionary["post"] = item
				
				parsedItems.append(dictionary)
			}
			
			self.feedItems = parsedItems
			
			DispatchQueue.main.async {
				self.tableView.reloadData()
			}
		}
	}

	func extractImages(html : String) -> [String : Any]
	{
		var content : NSString = html as NSString
		var images : [String] = []
		var dictionary : [String : Any] = [:]

		if content.contains("<img")
		{
			var aspectRatio : CGFloat = 0.0
			
			while (content.contains("<img"))
			{
				var width : CGFloat = 0.0
				var height : CGFloat = 0.0
				
				// Extract the entire image tag...
				var image : NSString = content.substring(from: content.range(of: "<img").location) as NSString

				if (image.contains("width=") && image.contains("height=")) {
					var widthString : NSString = image.substring(from: image.range(of: "width=").location + 7) as NSString
					var heightString: NSString = image.substring(from: image.range(of: "height=").location + 8) as NSString

					widthString = widthString.substring(to: widthString.range(of: "\"").location) as NSString
					heightString = heightString.substring(to: heightString.range(of: "\"").location) as NSString

					width = CGFloat(widthString.floatValue);
					height = CGFloat(heightString.floatValue);
					
					if (width > 0.0 && height > 0.0)
					{
						let currentAspectRatio = height / width
						if (currentAspectRatio > aspectRatio) {
							aspectRatio = currentAspectRatio
						}
					}
				}
				
				image = image.substring(to: image.range(of: ">").location + 1) as NSString

				let shouldIgnore = image.contains("1em;")

				var replacement : NSString = ""

				if (shouldIgnore)
				{
					if image.contains("alt=") {
						var altTag : NSString = image.substring(from: image.range(of: "alt=").location + 4) as NSString
						altTag = altTag.substring(from: altTag.range(of: "\"").location + 1) as NSString
						altTag = altTag.substring(to: altTag.range(of: "\"").location) as NSString
						replacement = altTag
					}
				}
				
				// Remove the image tag from the content...
				content = content.replacingOccurrences(of: image as String, with: replacement as String) as NSString

				// Pull just the actual URL from the image tag...
				if (!shouldIgnore && image.contains("src=")) {
					image = image.substring(from: image.range(of: "src=").location + 5) as NSString
					image = image.substring(to: image.range(of: "\"").location) as NSString

					//Because we are coming from HTML land, we need to be careful with & symbols
					image = image.replacingOccurrences(of: "&amp;", with: "&") as NSString
					
					images.append(image as String)
				}
			}
		}
		
		/*
		// Remove trailing new lines and carriage returns
		var hasTrailingWhitespace = content.hasSuffix("\n") ||
									content.hasSuffix("\r") ||
									content.hasSuffix("<p></p>")
		
		while hasTrailingWhitespace {

			if content.hasSuffix("\n") || content.hasSuffix("\r") {
				content = content.substring(to: content.length - 1) as NSString
			}
			else if content.hasSuffix("<p></p>") {
				content = content.substring(to: content.length - 7) as NSString
			}
			
			hasTrailingWhitespace = content.hasSuffix("\n") ||
									content.hasSuffix("\r") ||
									content.hasSuffix("<p></p>")
		}
		*/
		
		let htmlString = content as String;
		let htmlData = htmlString.data(using: .utf16, allowLossyConversion: false)!
		
		let options : [NSAttributedString.DocumentReadingOptionKey : Any] = [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue]
		var attributedString = try? NSAttributedString(data: htmlData, options: options, documentAttributes: nil)
		
		// After conversion from html, there are occassionally trailing carriage returns
		if var attribString = attributedString {
			while attribString.string.hasSuffix("\n") || attribString.string.hasSuffix("\r") {
				attribString = attribString.attributedSubstring(from: NSRange(location: 0, length: attribString.length - 1))
			}
			
			while attribString.string.hasPrefix("\n") || attribString.string.hasPrefix("\r") {
				attribString = attribString.attributedSubstring(from: NSRange(location: 1, length: attribString.length - 1))
			}
			
			attributedString = attribString
		}
		else {
			attributedString = NSAttributedString(string:"")
		}
		
		let mutableAttributedString = NSMutableAttributedString(attributedString: attributedString!)
		mutableAttributedString.addAttributes([.font : UIFont(name: "AvenirNext-Regular", size: 14.0) as Any], range: NSRange(location: 0, length: attributedString!.length))
		attributedString = mutableAttributedString
		

		dictionary["attributedString"] = attributedString
		dictionary["images"] = images
		dictionary["content"] = content
		
		return dictionary
	}
	
	func updateUserConfiguration()
	{
		Snippets.shared.fetchUserInfo { (error, user) in
			
			DispatchQueue.main.async {
				self.userName.text = user?.userHandle
				
				user?.loadUserImage {
					DispatchQueue.main.async {
						self.userImage.image = user?.userImage
					}
				}
			}
		}
	}


	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// MARK: - Notifications
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	@objc func handleTemporaryTokenReceivedNotification(_ notification : Notification)
	{
		if let temporaryToken = notification.object as? String
		{
			Snippets.shared.requestPermanentTokenFromTemporaryToken(token: temporaryToken) { (error, token) in
				if let permanentToken = token
				{
					self.savePermanentToken(permanentToken)
					
					DispatchQueue.main.async {
						self.loginPopUpView.isHidden = true
						self.postView.isHidden = false
						self.loginPopUpView.isHidden = true
						self.updateUserTimeline()
						self.updateUserConfiguration()
					}
				}
			}
		}
	}
	
	@objc func handleImageLoadedNotification(_ notification : Notification)
	{
		self.tableView.reloadData()
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// MARK: - UITableViewDataSource, UITableViewDelegate
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
    	return self.feedItems.count
	}

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
    	let cell = tableView.dequeueReusableCell(withIdentifier: "FeedTableViewCell", for: indexPath) as! FeedTableViewCell
		let post = self.feedItems[indexPath.row]
		cell.configure(post)
		
    	return cell
	}
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// MARK: - IBActions
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	@IBAction func onLogin()
	{
		self.loginErrorLabel.isHidden = true
		let loginString = self.emailAddressField.text
		
		if loginString!.contains(".") {
			Snippets.shared.requestUserLoginEmail(email: self.emailAddressField.text!, appName: "SnipIt", redirect: "blog.micro.snipit://login/")
			{ (err) in
		
				if let error = err
				{
					DispatchQueue.main.async {
						self.loginErrorLabel.isHidden = false
						self.loginErrorLabel.text = error.localizedDescription
					}
				}
			}
		}
		else
		{
			Snippets.shared.requestPermanentTokenFromTemporaryToken(token: loginString!) { (error, token) in
				if let permanentToken = token
				{
					self.savePermanentToken(permanentToken)
					
					DispatchQueue.main.async {
						self.loginPopUpView.isHidden = true
						self.postView.isHidden = false
						self.loginPopUpView.isHidden = true
						self.updateUserTimeline()
						self.updateUserConfiguration()
					}
				}
			}

		}
	}


	@IBAction func onPostImage()
	{
		if let image = UIImage(named: "scissors")
		{
			Snippets.shared.uploadImage(image: image) { (error, path) in
			}
		}
	}


	@IBAction func onPost()
	{
		if let textToPost = self.postTextField.text
		{
			self.postTextField.text = nil
			Snippets.shared.postText(title: "", content: textToPost, photos: [], altTags: []) { (error, pathToPost) in
			}
		}
	}
	
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// MARK: - Token management
	// Ideally this token would be saved to the keychain or some place more secure. For reference purposes, we will just save to UserDefaults
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	func savePermanentToken(_ token : String)
	{
		UserDefaults.standard.set(token, forKey: "SnipItToken")
	}

	func permanentToken() -> String?
	{
		let token = UserDefaults.standard.object(forKey: "SnipItToken") as? String
		return token
	}
}

