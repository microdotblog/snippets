//
//  UserProfileViewController.swift
//  Snippets-Example
//
//  Created by Jonathan Hays on 3/13/19.
//  Copyright © 2019 Micro.blog. All rights reserved.
//

import UIKit
import Snippets

class UserProfileViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
	
	@IBOutlet var tableView : UITableView!
	var user : SnippetsUser!
	var posts : [[String : Any]] = []
	
    override func viewDidLoad() {
		
		self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem:.done, target: self, action: #selector(onDone))
		
        super.viewDidLoad()
		
		Snippets.shared.fetchUserDetails(user: self.user) { (error, updatedUser, posts) in
			self.user = updatedUser
			self.posts = SnippetsParsingTools.convertPostsToTimelineDictionaries(posts)

			DispatchQueue.main.async {
				self.tableView.reloadData()
			}
		}
		
    }
	
	@objc func onDone() {
		self.navigationController?.dismiss(animated: true, completion: nil)
	}
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return 2
	}

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if (section == 0) {
			return 1
		}
		
		return self.posts.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if indexPath.section == 0 {
			let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileHeaderTableViewCell", for: indexPath) as! ProfileHeaderTableViewCell
			cell.updateFromUser(self.user)
			if self.posts.count > 0 {
				cell.busyIndicator.isHidden = true
			}
			else {
				cell.busyIndicator.isHidden = false
			}
			return cell
		}
		
		let cell = tableView.dequeueReusableCell(withIdentifier: "FeedTableViewCell", for: indexPath) as! FeedTableViewCell
		let dictionary = self.posts[indexPath.row]
		
		cell.configure(dictionary)
		return cell
	}
	
}
