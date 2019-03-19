//
//  ImageViewerViewController.swift
//  Snippets-Example
//
//  Created by Jonathan Hays on 3/18/19.
//  Copyright © 2019 Micro.blog. All rights reserved.
//

import UIKit

class ImageViewerViewController: UIViewController {

	var image : UIImage!
	
	@IBOutlet var imageView : UIImageView!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		self.imageView.image = self.image;
		self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(onClose))
    }
    
	@IBAction func onClose() {
		self.dismiss(animated: true, completion: nil)
	}
}
