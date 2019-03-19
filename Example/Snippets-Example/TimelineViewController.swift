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

class TimelineViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

	// User display elements
	@IBOutlet var profileImage : UIImageView!
	
	@IBOutlet var loadingView : UIView!

	// Login elements
	@IBOutlet var loginErrorLabel : UILabel!
	@IBOutlet var emailAddressField : UITextField!
	@IBOutlet var loginPopUpView : UIView!
	
	@IBOutlet var timelineButton : UIButton!
	@IBOutlet var discoverButton : UIButton!
	@IBOutlet var photosButton : UIButton!
	@IBOutlet var bookmarksButton : UIButton!
	
	// Feed display elements
	@IBOutlet var tableView : UITableView!
	var feedItems : [[String : Any]] = []
	var loggedInUser : SnippetsUser?

	override func viewDidLoad()
	{
		super.viewDidLoad()

		self.setupNotifications()
		
		self.loadingView.isHidden = true
		self.loadingView.superview?.bringSubviewToFront(self.loadingView)
		self.loginPopUpView.superview?.bringSubviewToFront(self.loginPopUpView)
		
		// If we have a valid token, we don't need to show the login popup
		if self.permanentToken() != nil
		{
			Snippets.shared.configure(permanentToken: self.permanentToken()!, blogUid: nil)
			
			self.loginPopUpView.isHidden = true
			self.updateUserConfiguration()
			self.onTimeline()
		}
		else {
			self.emailAddressField.becomeFirstResponder()
		}
	}
	
	func setupNotifications() {
		NotificationCenter.default.addObserver(self, selector: #selector(handleImageLoadedNotification(_:)), name: NSNotification.Name(rawValue: "ImageLoadedNotification"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleTemporaryTokenReceivedNotification(_:)), name: NSNotification.Name("TemporaryTokenReceivedNotification"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleLoadUserProfile(_:)), name: NSNotification.Name(rawValue: "ShowUserProfileNotification"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleDisplayImageNotification(_:)), name: NSNotification.Name(rawValue: "DisplayImageNotification"), object: nil)
	}
	
	func selectButton(_ button : UIButton) {
		self.timelineButton.isSelected = false
		self.discoverButton.isSelected = false
		self.photosButton.isSelected = false
		self.bookmarksButton.isSelected = false
		
		button.isSelected = true
	}
	
	@IBAction func onTimeline() {
		
		self.selectButton(self.timelineButton)
		
		self.loadingView.isHidden = false
		Snippets.shared.fetchUserTimeline { (error, items) in
			self.processTimelineItems(items)
		}
	}

	@IBAction func onBookmarks() {
		
		self.selectButton(self.bookmarksButton)
		
		self.loadingView.isHidden = false
		Snippets.shared.fetchUserFavorites { (error, items) in
			self.processTimelineItems(items)
		}
	}

	@IBAction func onPhotos() {
		
		self.selectButton(self.photosButton)
		
		self.loadingView.isHidden = false
		Snippets.shared.fetchUserPhotoTimeline { (error, items) in
			self.processTimelineItems(items)
		}
	}

	@IBAction func onDiscover() {
		
		self.selectButton(self.discoverButton)
		
		self.loadingView.isHidden = false
		Snippets.shared.fetchDiscoverTimeline(collection: "books") { (error, items) in
			self.processTimelineItems(items)
		}
	}

	@IBAction func onProfile() {
		self.displayUserProfile(self.loggedInUser!)
	}
	
	@IBAction func onCompose() {
		self.compose(nil)
	}
	
	func processTimelineItems(_ items : [SnippetsPost]) {

		self.feedItems = SnippetsParsingTools.convertPostsToTimelineDictionaries(items)
		
		DispatchQueue.main.async {
			self.tableView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
			
			self.tableView.reloadData()
			self.loadingView.isHidden = true
		}
	}
	
	func displayUserProfile(_ user : SnippetsUser) {
		let storyboard = UIStoryboard(name: "Main", bundle: nil)
		let controller = storyboard.instantiateViewController(withIdentifier: "UserProfileViewController") as! UserProfileViewController
		controller.user = user
		let navController = UINavigationController(rootViewController: controller)
		self.present(navController, animated: true, completion: nil)
	}
	
	func compose(_ replyPost : SnippetsPost?) {
		let storyboard = UIStoryboard(name: "Main", bundle: nil)
		let controller = storyboard.instantiateViewController(withIdentifier: "ComposeViewController") as! ComposeViewController
		controller.originalPost = replyPost
		let navController = UINavigationController(rootViewController: controller)
		self.present(navController, animated: true, completion: nil)
	}
	
	func displayConversation(_ post : SnippetsPost) {
		let storyboard = UIStoryboard(name: "Main", bundle: nil)
		let controller = storyboard.instantiateViewController(withIdentifier: "ConversationViewController") as! ConversationViewController
		controller.originalPost = post
		
		let navController = UINavigationController(rootViewController: controller)
		self.present(navController, animated: true, completion: nil)
	}
	
	func updateUserConfiguration()
	{
		Snippets.shared.fetchUserInfo { (error, user) in
			self.loggedInUser = user
			
			DispatchQueue.main.async {
				user?.loadUserImage {
					DispatchQueue.main.async {
						self.profileImage.image = user?.userImage
					}
				}
			}
		}
	}


	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// MARK: - Notifications
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	@objc func handleLoadUserProfile(_ notification : Notification) {
		let user : SnippetsUser = notification.object as! SnippetsUser
		self.displayUserProfile(user)
	}
	
	@objc func handleDisplayImageNotification(_ notification : Notification) {
		let image = notification.object as! UIImage
		let storyboard = UIStoryboard(name: "Main", bundle: nil)
		let controller = storyboard.instantiateViewController(withIdentifier: "ImageViewerViewController") as! ImageViewerViewController
		controller.image = image
		let navController = UINavigationController(rootViewController: controller)
		self.present(navController, animated: true, completion: nil)
	}
	
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
						self.updateUserConfiguration()
						self.onTimeline()
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
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		let dictionary = self.feedItems[indexPath.row]
		let post = dictionary["post"] as! SnippetsPost
		
		let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
		alert.addAction(UIAlertAction(title: "Reply", style: .default, handler: { (action) in
			self.compose(post)
		}))
		
		alert.addAction(UIAlertAction(title: "View Conversation", style: .default, handler: { (action) in
			self.displayConversation(post)
		}))
		
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
		}))
		
		self.present(alert, animated: true, completion: nil)
	}
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// MARK: - IBActions
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	@IBAction func onLogin()
	{
		self.loginErrorLabel.isHidden = true
		let loginString = self.emailAddressField.text

		self.emailAddressField.resignFirstResponder()

		if loginString!.contains(".") {
			
			Snippets.shared.requestUserLoginEmail(email: self.emailAddressField.text!, appName: "SnipIt", redirect: "blog.micro.snipit://login/")
			{ (err) in
		
				DispatchQueue.main.async {
					if let error = err
					{
						self.loginErrorLabel.isHidden = false
						self.loginErrorLabel.text = error.localizedDescription
					}
					else {
						self.emailAddressField.text = ""
						let alert = UIAlertController(title: nil, message: "Check your email on this device and tap the \"Open with SnipIt\" button.", preferredStyle: .alert)
						alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
						self.present(alert, animated: true, completion: nil)
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
						self.updateUserConfiguration()
						self.onTimeline()
					}
				}
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

