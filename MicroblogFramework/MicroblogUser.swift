//
//  MicroblogUser.swift
//  MicroblogFramework
//
//  Created by Jonathan Hays on 10/24/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

import Foundation
import UUSwift

public class MicroblogUser
{
	public init(){}
	public convenience init(_ dictionary : [String : Any])
	{
		self.init()
		self.loadFromDictionary(dictionary)
	}
	
	public var fullName = ""
	public var userHandle = ""
	public var pathToUserImage = ""
	public var pathToWebSite = ""
	public var userImage : UIImage? = nil
}


extension MicroblogUser {

	public func loadUserImage(completion: @escaping()-> ())
	{
		if let imageData = UUDataCache.shared.data(for: self.pathToUserImage)
		{
			if let image = UIImage(data: imageData)
			{
				self.userImage = image
				completion()
				return
			}
		}

		// If we have gotten here, then there is no image available to display so we need to fetch it...
		UUHttpSession.get(self.pathToUserImage, [:]) { (parsedServerResponse) in
			if let image = parsedServerResponse.parsedResponse as? UIImage
			{
				if let imageData = image.pngData()
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
