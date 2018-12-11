//
//  MicroblogPost.swift
//  MicroblogFramework
//
//  Created by Jonathan Hays on 10/24/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

import Foundation
import UUSwift

public class MicroblogPost : NSObject
{
	public convenience init(_ dictionary : [String : Any])
	{
		self.init()
		self.loadFromDictionary(dictionary)
	}
	
	public var identifier = ""
	public var owner = MicroblogUser()
	public var htmlText = ""
	public var path = ""
	public var publishedDate : Date?
	public var replies : [MicroblogPost] = []
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
