//
//  ConversationViewController.swift
//  Snippets-Example
//
//  Created by Jonathan Hays on 3/19/19.
//  Copyright © 2019 Micro.blog. All rights reserved.
//

import UIKit
import UUSwift
import Snippets

class ConversationViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

	@IBOutlet var loadingView : UIView!
	@IBOutlet var tableView : UITableView!
	var feedItems : [[String : Any]] = []
	var originalPost : SnippetsPost!

    override func viewDidLoad() {
        super.viewDidLoad()

		self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(onDone))
		
		self.setupNotifications()
		
		self.loadingView.isHidden = false
		self.loadingView.superview?.bringSubviewToFront(self.loadingView)
		
		Snippets.shared.fetchConversation(post: self.originalPost) { (error, posts) in
			self.processTimelineItems(posts)
		}
    }
    
	func setupNotifications() {
		NotificationCenter.default.addObserver(self, selector: #selector(handleImageLoadedNotification(_:)), name: NSNotification.Name(rawValue: "ImageLoadedNotification"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleLoadUserProfile(_:)), name: NSNotification.Name(rawValue: "ShowUserProfileNotification"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleDisplayImageNotification(_:)), name: NSNotification.Name(rawValue: "DisplayImageNotification"), object: nil)
	}

	func processTimelineItems(_ items : [SnippetsPost]) {
		
		self.feedItems = SnippetsParsingTools.convertPostsToTimelineDictionaries(items)
		
		DispatchQueue.main.async {
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
		
	}
	
	func displayConversation(_ post : SnippetsPost) {
	}

	@objc func onDone() {
		self.navigationController?.dismiss(animated: true, completion: nil)
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
		
		// If we're already in a conversation thread, we don't need to view the conversation!
		//alert.addAction(UIAlertAction(title: "View Conversation", style: .default, handler: { (action) in
		//	self.displayConversation(post)
		//}))
		
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
		}))
		
		self.present(alert, animated: true, completion: nil)
	}

}
