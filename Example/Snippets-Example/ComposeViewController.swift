//
//  ComposeViewController.swift
//  Snippets-Example
//
//  Created by Jonathan Hays on 3/19/19.
//  Copyright © 2019 Micro.blog. All rights reserved.
//

import UIKit
import Snippets
import UUSwift

class ComposeViewController: UIViewController, UITextViewDelegate {

	var originalPost : SnippetsPost?
	
	@IBOutlet var busyView : UIView!
	@IBOutlet var textView : UITextView!
	
    override func viewDidLoad() {
        super.viewDidLoad()

		self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCancel))
		self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Post", style: .plain, target: self, action: #selector(onPost))
		
		if let post = self.originalPost {
			self.textView.text = "@" + post.owner.userHandle + " "
		}
		
		self.textView.becomeFirstResponder()
		self.busyView.isHidden = true
    }
    
	@objc func onCancel() {
		self.navigationController?.dismiss(animated: true, completion: nil)
	}
	
	@objc func onPost() {
		self.busyView.isHidden = false

		if originalPost == nil {
			Snippets.shared.postText(title: "", content: self.textView.text, photos: [], altTags: []) { (error, path) in
				self.navigationController?.dismiss(animated: true, completion: nil)
			}
		}
		else {
			Snippets.shared.reply(originalPost: self.originalPost!, content: self.textView.text) { (error) in
				self.navigationController?.dismiss(animated: true, completion: nil)
			}
		}
	}

}
