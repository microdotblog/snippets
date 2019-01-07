//
//  MicroblogPost.swift
//  MicroblogFramework
//
//  Created by Jonathan Hays on 10/24/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#if os(macOS)
import AppKit
import UUSwift
#else
import UIKit
import UUSwift
#endif


public class MicroblogPost : NSObject
{
	public convenience init(_ dictionary : [String : Any])
	{
		self.init()
		self.loadFromDictionary(dictionary)
	}
	
	@objc public var identifier = ""
	@objc public var owner = MicroblogUser()
	@objc public var htmlText = ""
	@objc public var path = ""
	@objc public var publishedDate : Date?
	@objc public var replies : [MicroblogPost] = []
}


extension MicroblogPost {

	func loadFromDictionary(_ dictionary : [String : Any])
	{
		print(dictionary)
		
		if let identifier = dictionary["id"] as? String
		{
			self.identifier = identifier
		}
		
		if let postText = dictionary["content_html"] as? String
		{
			self.htmlText = postText
		}

		if let authorDictionary = dictionary["author"] as? [String : Any]
		{
			self.owner.loadFromDictionary(authorDictionary)
		}

		if let path = dictionary["url"] as? String
		{
			self.path = path
		}
		
		if let dateString = dictionary["date_published"] as? String
		{
			self.publishedDate = dateString.uuParseDate(format: "yyyy-MM-dd'T'HH:mm:ssZ")
		}
	}
}
