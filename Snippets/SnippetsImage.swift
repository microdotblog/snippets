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

public enum SnippetsImageFileType {
	case jpeg
	case png
}

open class SnippetsImage : NSObject{

	public init(_ image : SnippetsSystemImage, type : SnippetsImageFileType = .jpeg) {
		self.systemImage = image
		self.type = type
	}

	let systemImage : SnippetsSystemImage
	let type : SnippetsImageFileType
}
