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

class ComposeViewController: UIViewController, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

	var originalPost : SnippetsPost?
	var attachedPhoto : UIImage?
	
	@IBOutlet var addPhotoButton : UIButton!
	@IBOutlet var busyView : UIView!
	@IBOutlet var textView : UITextView!
	
    override func viewDidLoad() {
        super.viewDidLoad()

		self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCancel))
		self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Post", style: .plain, target: self, action: #selector(onPost))
		
		if let post = self.originalPost {
			self.textView.text = "@" + post.owner.userHandle + " "
			
			//
			self.addPhotoButton.isHidden = true
		}
		
		self.textView.becomeFirstResponder()
		self.busyView.isHidden = true
    }
	
	@IBAction func onAddPhoto() {
		let imagePicker = UIImagePickerController()
		imagePicker.delegate = self
		self.present(imagePicker, animated: true, completion: nil)
	}
	
	@objc func onCancel() {
		self.navigationController?.dismiss(animated: true, completion: nil)
	}
	
	@objc func onPost() {
		self.busyView.isHidden = false

		if let photo = self.attachedPhoto {
		
			Snippets.shared.uploadImage(image: photo) { (error, url) in
				
				if let path = url {
					let photos = [path]

					Snippets.shared.postText(title: "", content: self.textView.text, photos: photos, altTags: []) { (error, path) in
						DispatchQueue.main.async {
							self.navigationController?.dismiss(animated: true, completion: nil)
						}
					}
				}
			}
		}
		else if originalPost == nil {
			Snippets.shared.postText(title: "", content: self.textView.text, photos: [], altTags: []) { (error, path) in
				DispatchQueue.main.async {
					self.navigationController?.dismiss(animated: true, completion: nil)
				}
			}
		}
		else {
			Snippets.shared.reply(originalPost: self.originalPost!, content: self.textView.text) { (error) in
				DispatchQueue.main.async {
					self.navigationController?.dismiss(animated: true, completion: nil)
				}
			}
		}
	}

	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
		var pickedImage = info[UIImagePickerController.InfoKey.editedImage]
		if (pickedImage == nil) {
			pickedImage = info[UIImagePickerController.InfoKey.originalImage]
		}
		
		if let image = pickedImage as? UIImage {
			self.attachedPhoto = image
			self.addPhotoButton.setTitle(nil, for: .normal)
			self.addPhotoButton.setBackgroundImage(image, for: .normal)
			
			picker.dismiss(animated: true, completion: nil)
		}
	}

}
