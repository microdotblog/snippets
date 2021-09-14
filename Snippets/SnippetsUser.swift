//
//  SnippetsUser.swift
//  SnippetsFramework
//
//  Created by Jonathan Hays on 10/24/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#if os(macOS)
import AppKit
#else
import UIKit
#endif

import UUSwiftCore
import UUSwiftNetworking
import UUSwiftImage


open class SnippetsUser : NSObject
{
	public convenience init(_ dictionary : [String : Any])
	{
		self.init()
		self.loadFromDictionary(dictionary)
	}
	
	@objc public var fullName = ""
	@objc public var username = ""
	@objc public var avatarURL = ""
	@objc public var siteURL = ""
	@objc public var bio = ""
	@objc public var followingCount : Int = 0
	@objc public var discoverCount : Int = 0
	@objc public var isFollowing = false
	@objc public var avatarImage : SnippetsSystemImage? = nil

	private var avatarDownloadHttpSession : UUHttpRequest?
}


extension SnippetsUser {
	

	@objc public func loadUserImage(completion: @escaping()-> ())
	{
		if let imageData = UUDataCache.shared.data(for: self.avatarURL)
		{
			if let image = SnippetsSystemImage(data: imageData)
			{
				self.avatarImage = image
				completion()
				return
			}
		}

		if self.avatarDownloadHttpSession == nil {
			// If we have gotten here, then there is no image available to display so we need to fetch it...
			let request = UUHttpRequest(url: self.avatarURL)
			self.avatarDownloadHttpSession = UUHttpSession.executeRequest(request, { (parsedServerResponse) in
				if let image = parsedServerResponse.parsedResponse as? SnippetsSystemImage
				{
					if let imageData = image.uuPngData()
					{
						UUDataCache.shared.set(data: imageData, for: self.avatarURL)
						self.avatarImage = image
						completion()
					}
				}
			})
		}
	}
	
	func loadFromMicroblogDictionary(_ snippetsDictionary : [String : Any])
	{
		if let username = snippetsDictionary["username"] as? String
		{
			self.username = username
		}
		if let bio = snippetsDictionary["bio"] as? String
		{
			self.bio = bio
		}
		if let followingCount = snippetsDictionary["following_count"] as? Int
		{
			self.followingCount = followingCount
		}
		if let discoverCount = snippetsDictionary["discover_count"] as? Int
		{
			self.discoverCount = discoverCount
		}
		if let isFollowing = snippetsDictionary["is_following"] as? Int
		{
			self.isFollowing = (isFollowing > 0)
		}
	}
	
	func loadFromDictionary(_ authorDictionary : [String : Any])
	{
		if let username = authorDictionary["username"] as? String
		{
			self.username = username
		}
		
		if let bio = authorDictionary["bio"] as? String
		{
			self.bio = bio
		}
		
		if let snippetsDictionary = authorDictionary["_microblog"] as? [String : Any]
		{
			self.loadFromMicroblogDictionary(snippetsDictionary)
		}
			
		if let fullName = authorDictionary["name"] as? String
		{
			self.fullName = fullName
		}
		
		if let fullName = authorDictionary["full_name"] as? String
		{
			self.fullName = fullName
		}
		
		if let userImagePath = authorDictionary["avatar"] as? String {
			self.avatarURL = userImagePath
		}
		else if let userImagePath = authorDictionary["gravatar_url"] as? String {
			self.avatarURL = userImagePath
		}
		if let site = authorDictionary["url"] as? String {
			self.siteURL = site
		}
	}
}
