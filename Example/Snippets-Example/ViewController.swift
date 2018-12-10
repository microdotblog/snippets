//
//  ViewController.swift
//  Snippets-Example
//
//  Created by Jonathan Hays on 10/21/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

import UIKit
import Microblog
import WebKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, WKNavigationDelegate {

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
	var feedItems : [MicroblogPost] = []
	
	var webViewHeights : [ CGFloat ] = []

	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		self.loginPopUpView.layer.cornerRadius = 8.0
		//self.tableView.register(UINib(nibName: "FeedTableViewCell", bundle: nil), forCellReuseIdentifier: "FeedTableViewCell")
		
		NotificationCenter.default.addObserver(self, selector: #selector(handleImageLoadedNotification(_:)), name: NSNotification.Name(rawValue: "UserAvatarImageLoaded"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleTemporaryTokenReceivedNotification(_:)), name: NSNotification.Name("TemporaryTokenReceivedNotification"), object: nil)
		
		// If we have a valid token, we don't need to show the login popup
		if self.permanentToken() != nil
		{
			MicroblogFramework.shared.configure(permanentToken: self.permanentToken()!, blogUid: nil)
			
			self.postView.isHidden = false
			self.loginPopUpView.isHidden = true
			self.updateUserTimeline()
			self.updateUserConfiguration()
		}
	}

	func updateUserTimeline()
	{
		//MicroBlogFramework.shared.fetchUserTimeline { (error, items) in
		//MicroBlogFramework.shared.fetchUserFavorites { (error, items) in


		//let user = MicroBlogUser()
		//user.userHandle = "manton"
		//MicroBlogFramework.shared.fetchUserPosts(user: user) { (error, items) in

		//let post = MicroBlogPost()
		//post.identifier = "984880"
		//MicroBlogFramework.shared.fetchConversation(post: post) { (error, items) in
		
		MicroblogFramework.shared.fetchDiscoverTimeline(collection: "books") { (error, items) in
			self.feedItems = items
					
			for _ in 0 ... items.count
			{
				self.webViewHeights.append(0.0)
			}
					
			DispatchQueue.main.async {
				self.tableView.reloadData()
			}
		}
	}

	func updateUserConfiguration()
	{
		MicroblogFramework.shared.fetchUserInfo { (error, user) in
			
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
			MicroblogFramework.shared.requestPermanentTokenFromTemporaryToken(token: temporaryToken) { (error, token) in
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
		cell.webView.tag = indexPath.row

		let post = self.feedItems[indexPath.row]
		cell.webView.navigationDelegate = nil

		let webViewHeight = self.webViewHeights[indexPath.row]
		if webViewHeight == 0.0
		{
			cell.webView.navigationDelegate = self
		}
		
		cell.configure(post, webViewHeight)
		
    	return cell
	}
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// MARK: - WKNavigationDelegate
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


	func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!)
	{
		let index = webView.tag

		if (self.webViewHeights[index] == 0.0)
		{
			webView.evaluateJavaScript("Math.max(document.body.scrollHeight, document.body.offsetHeight, document.documentElement.clientHeight, document.documentElement.scrollHeight, document.documentElement.offsetHeight)") { (result, error) in
			
				if let height = result as? NSNumber
				{
					self.webViewHeights[index] = CGFloat(height.floatValue)
	
					DispatchQueue.main.async {
						self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
					}
				}
			}
		}
	}


	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// MARK: - IBActions
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	@IBAction func onLogin()
	{
		self.loginErrorLabel.isHidden = true
		
		MicroblogFramework.shared.requestUserLoginEmail(email: self.emailAddressField.text!, appName: "SnipIt", redirect: "blog.micro.snipit://login/")
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


	@IBAction func onPostImage()
	{
		if let image = UIImage(named: "scissors")
		{
			MicroblogFramework.shared.uploadImage(image: image) { (error, path) in
			}
		}
	}


	@IBAction func onPost()
	{
		if let textToPost = self.postTextField.text
		{
			self.postTextField.text = nil
			
			MicroblogFramework.shared.post(title: "", content: textToPost) { (error, results) in
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

