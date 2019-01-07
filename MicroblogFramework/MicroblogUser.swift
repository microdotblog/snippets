//
//  MicroblogUser.swift
//  MicroblogFramework
//
//  Created by Jonathan Hays on 10/24/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#if os(macOS)
import AppKit
import UUSwiftMac
public typealias MBImage = NSImage
#else
import UIKit
import UUSwift
public typealias MBImage = UIImage
#endif


public class MicroblogUser : NSObject
{
	public convenience init(_ dictionary : [String : Any])
	{
		self.init()
		self.loadFromDictionary(dictionary)
	}
	
	@objc public var fullName = ""
	@objc public var userHandle = ""
	@objc public var pathToUserImage = ""
	@objc public var pathToWebSite = ""
	@objc public var userImage : MBImage? = nil
}


extension MicroblogUser {

	@objc public func loadUserImage(completion: @escaping()-> ())
	{
		if let imageData = UUDataCache.shared.data(for: self.pathToUserImage)
		{
			if let image = MBImage(data: imageData)
			{
				self.userImage = image
				completion()
				return
			}
		}

		// If we have gotten here, then there is no image available to display so we need to fetch it...
		UUHttpSession.get(self.pathToUserImage, [:]) { (parsedServerResponse) in
			if let image = parsedServerResponse.parsedResponse as? MBImage
			{
				if let imageData = UIImagePNGRepresentation(image)
				{
					UUDataCache.shared.set(data: imageData, for: self.pathToUserImage)
					self.userImage = image
					completion()
				}
			}
		}
	}
	
	func loadFromDictionary(_ authorDictionary : [String : Any])
	{
		if let userName = authorDictionary["username"] as? String
		{
			self.userHandle = userName
		}
		else if let microblogDictionary = authorDictionary["_microblog"] as? [String : Any]
		{
			if let userName = microblogDictionary["username"] as? String
			{
				self.userHandle = userName
			}
		}
		
			
		if let fullName = authorDictionary["name"] as? String
		{
			self.fullName = fullName
		}
		
		if let userImagePath = authorDictionary["avatar"] as? String
		{
			self.pathToUserImage = userImagePath
		}
		else if let userImagePath = authorDictionary["gravatar_url"] as? String
		{
			self.pathToUserImage = userImagePath
		}
		
		if let site = authorDictionary["default_site"] as? String
		{
			self.pathToWebSite = site
		}
	}
}
