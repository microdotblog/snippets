//
//  SnippetsImage.swift
//  Snippets
//
//  Created by Jonathan Hays on 9/13/21.
//  Copyright © 2021 Micro.blog, LLC. All rights reserved.
//

#if os(macOS)
import AppKit
public typealias SnippetsSystemImage = NSImage
#else
import UIKit
public typealias SnippetsSystemImage = UIImage
#endif


open class SnippetsImage : NSObject{

	init(_ image : SnippetsSystemImage, type : fileType = .jpeg) {
		self.systemImage = image
		self.type = type
	}

	enum fileType {
		case jpeg
		case png
	}

	let systemImage : SnippetsSystemImage
	let type : fileType
}
