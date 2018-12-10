//
//  Microblog.swift
//  MicroblogFramework
//
//  Created by Jonathan Hays on 10/22/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

import Foundation
import UUSwift

public class MicroblogFramework {

	public static let shared = MicroblogFramework()
	
	public func configure(permanentToken : String, blogUid : String?)
	{
		self.uid = blogUid
		self.token = permanentToken
	}
	
	public func setServerPath(_ path : String)
	{
		self.serverPath = path
	}
	
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// MARK: - Signin
	// Sign-in is generally a 2-step process. First, request an email with a temporary token. Then exchange the temporary token for a permanent token
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	public func requestUserLoginEmail(email: String, appName : String, redirect: String, completion: @escaping (Error?) -> ())
	{
		let arguments : [String : String] = [ 	"email" : email,
												"app_name" : appName,
												"redirect_url" : redirect ]
	
		_ = UUHttpSession.post(self.pathForRoute("account/signin"), arguments, nil, nil) { (parsedServerResponse) in
			completion(parsedServerResponse.httpError)
		}
	}
	
	public func requestPermanentTokenFromTemporaryToken(token : String, completion: @escaping(Error?, String?) -> ())
	{
		let arguments : [String : String] = [ "token" : token ]
		
		_ = UUHttpSession.post(self.pathForRoute("account/verify"), arguments, nil, nil) { (parsedServerResponse) in
			if let dictionary = parsedServerResponse.parsedResponse as? [ String : Any ]
			{
				if let permanentToken = dictionary["token"] as? String
				{
					self.token = permanentToken
				}
				
				completion(parsedServerResponse.httpError, self.token)
			}
			else
			{
				completion(parsedServerResponse.httpError, nil)
			}
		}
	}
	
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// MARK: - User Info
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	// Returns a MicroblogUser for the currently signed-in user
	public func fetchUserInfo(completion: @escaping(Error?, MicroblogUser?)-> ())
	{
		let arguments : [String : String] = [ "token" : token ]
		let request = self.securePost(path: self.pathForRoute("account/verify"), arguments: arguments)
		
		_ = UUHttpSession.executeRequest(request) { (parsedServerResponse) in
			if let dictionary = parsedServerResponse.parsedResponse as? [String : Any]
			{
				let user = MicroblogUser(dictionary)
				completion(parsedServerResponse.httpError, user)
			}
			else
			{
				completion(parsedServerResponse.httpError, nil)
			}
		}
	}

	// User configuration pertains to the configuration of the Micro.blog account. For example, if a user has multiple micro.blogs,
	// fetching the configuration will return the list of configured micro.blogs for the signed-in user.
	public func fetchUserConfiguration(completion: @escaping(Error?, [String : Any])-> ())
	{
		let request = self.secureGet(path: self.pathForRoute("micropub?q=config"), arguments: [:])
		
		_ = UUHttpSession.executeRequest(request) { (parsedServerResponse) in
			
			if let dictionary = parsedServerResponse.parsedResponse as? [String : Any]
			{
				completion(parsedServerResponse.httpError, dictionary)
			}
			else
			{
				completion(parsedServerResponse.httpError, [:])
			}
		}

	}
	

	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// MARK: - Timeline interface for the signed-in user
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	private func fetchTimeline(_ path : String, completion: @escaping(Error?, [MicroblogPost]) -> ())
	{
		let request = self.secureGet(path: path, arguments: [:])
		
		_ = UUHttpSession.executeRequest(request) { (parsedServerResponse) in
			if let feedDictionary = parsedServerResponse.parsedResponse as? [String : Any]
			{
				if let items = feedDictionary["items"] as? [[String : Any]]
				{
					var posts : [ MicroblogPost ] = []
					
					for dictionary : [String : Any] in items
					{
						let post = MicroblogPost(dictionary)
						posts.append(post)
					}
					
					completion(parsedServerResponse.httpError, posts)
				}
			}
			else
			{
				completion(parsedServerResponse.httpError, [])
			}
		}
	}
	
	public func fetchUserTimeline(completion: @escaping(Error?, [MicroblogPost]) -> ())
	{
		self.fetchTimeline(self.pathForRoute("posts/all"), completion: completion)
	}
	
	public func fetchUserPhotoTimeline(completion: @escaping(Error?, [MicroblogPost]) -> ())
	{
		self.fetchTimeline(self.pathForRoute("posts/photos"), completion: completion)
	}

	public func fetchUserMentions(completion: @escaping(Error?, [MicroblogPost]) -> ())
	{
		self.fetchTimeline(self.pathForRoute("posts/mentions"), completion: completion)
	}

	public func fetchUserFavorites(completion: @escaping(Error?, [MicroblogPost]) -> ())
	{
		self.fetchTimeline(self.pathForRoute("posts/favorites"), completion: completion)
	}

	public func fetchDiscoverTimeline(collection : String? = nil, completion: @escaping(Error?, [MicroblogPost]) -> ())
	{
		if let validCollection = collection
		{
			let route = "posts/discover/\(validCollection)"
			self.fetchTimeline(self.pathForRoute(route), completion: completion)
		}
		else
		{
			self.fetchTimeline(self.pathForRoute("posts/discover"), completion: completion)
		}
	}

	public func fetchUserPosts(user : MicroblogUser, completion: @escaping(Error?, [MicroblogPost]) -> ())
	{
		let route = "posts/\(user.userHandle)"
		self.fetchTimeline(self.pathForRoute(route), completion: completion)
	}
	
	public func fetchConversation(post : MicroblogPost, completion: @escaping(Error?, [MicroblogPost]) -> ())
	{
		let route = "posts/conversation?id=\(post.identifier)"
		self.fetchTimeline(self.pathForRoute(route), completion: completion)
	}

	public func checkForPostsSince(post : MicroblogPost, completion: @escaping(Error?, Int?, TimeInterval?) -> ())
	{
		let route = "posts/check?since_id=\(post.identifier)"
		let request = self.secureGet(path: self.pathForRoute(route), arguments: [:])
		
		_ = UUHttpSession.executeRequest(request, { (parsedServerResponse) in
			
			if let dictionary = parsedServerResponse.parsedResponse as? [String : Any]
			{
				if let count = dictionary["count"] as? NSNumber,
					let timeInterval = dictionary["check_seconds"] as? NSNumber
				{
					completion(parsedServerResponse.httpError, count.intValue, TimeInterval(timeInterval.floatValue))
					return
				}
			}

			completion(parsedServerResponse.httpError, nil, nil)
		})
	}

	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// MARK: - Follow Interface
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	public func follow(user : MicroblogUser, completion: @escaping(Error?) -> ())
	{
		let arguments : [ String : String ] = [ "username" : user.userHandle ]
		
		let request = self.securePost(path: self.pathForRoute("users/follow"), arguments: arguments)
		
		_ = UUHttpSession.executeRequest(request, { (parsedServerResponse) in
			completion(parsedServerResponse.httpError)
		})
	}

	public func unfollow(user : MicroblogUser, completion: @escaping(Error?) -> ())
	{
		let arguments : [ String : String ] = [ "username" : user.userHandle ]
		
		let request = self.securePost(path: self.pathForRoute("users/unfollow"), arguments: arguments)
		
		_ = UUHttpSession.executeRequest(request, { (parsedServerResponse) in
			completion(parsedServerResponse.httpError)
		})
	}
	
	public func checkFollowingStatus(user : MicroblogUser, completion: @escaping(Error?, Bool?) -> ())
	{
		let route = "users/is_following?username=\(user.userHandle)"
		let request = self.secureGet(path: self.pathForRoute(route), arguments: [:])
		
		_ = UUHttpSession.executeRequest(request, { (parsedServerResponse) in
			
			if let dictionary = parsedServerResponse.parsedResponse as? [String : Any]
			{
				if let following = dictionary["is_following"] as? NSNumber
				{
					completion(parsedServerResponse.httpError, following.boolValue)
					return
				}
			}

			completion(parsedServerResponse.httpError, false)
		})
	}
	
	public func listFollowers(user : MicroblogUser, completeList : Bool, completion: @escaping(Error?, [MicroblogUser]) -> ())
	{
		var route = "users/following/\(user.userHandle)"
		if (!completeList)
		{
			route = "users/discover/\(user.userHandle)"
		}
		
		let request = self.secureGet(path: self.pathForRoute(route), arguments: [:])
		_ = UUHttpSession.executeRequest(request, { (parsedServerResponse) in
			
			if let userDictionaryList = parsedServerResponse.parsedResponse as? [[String : Any]]
			{
				var userList : [MicroblogUser] = []
					
				for userDictionary : [String : Any] in userDictionaryList
				{
					let user = MicroblogUser(userDictionary)
					userList.append(user)
				}
					
				completion(parsedServerResponse.httpError, userList)
			}
			else
			{
				completion(parsedServerResponse.httpError, [])
			}
		})
	}


	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// MARK: - Favorite Interface
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	public func favorite(post : MicroblogPost, completion: @escaping(Error?) -> ())
	{
		let arguments : [ String : String ] = [ "id" : post.identifier ]

		let request = self.securePost(path: self.pathForRoute("favorites"), arguments: arguments)
		
		_ = UUHttpSession.executeRequest(request, { (parsedServerResponse) in
			completion(parsedServerResponse.httpError)
		})
	}

	public func unfavorite(post : MicroblogPost, completion: @escaping(Error?) -> ())
	{
		let arguments : [ String : String ] = [ "id" : post.identifier ]
		let route = "favorites/\(post.identifier)"
		let request = self.secureDelete(path: self.pathForRoute(route), arguments: arguments)
		
		_ = UUHttpSession.executeRequest(request, { (parsedServerResponse) in
			completion(parsedServerResponse.httpError)
		})
	}


	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// MARK: - Post/Reply Interface
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	public func post(title : String, content : String, completion: @escaping(Error?, String?) -> ())
	{
		var arguments : [ String : String ] = [ "name" : title,
											    "content" : content ]
		
		if let blogUid = self.uid
		{
			arguments["mp-destination"] = blogUid
		}
		
		let request = self.securePost(path: self.pathForRoute("micropub"), arguments: arguments)
		
		_ = UUHttpSession.executeRequest(request, { (parsedServerResponse) in
			let publishedPath = parsedServerResponse.httpResponse?.allHeaderFields["Location"] as? String
			completion(parsedServerResponse.httpError, publishedPath)
		})
	}
	
	public func deletePost(post : MicroblogPost, completion: @escaping(Error?) -> ())
	{
		let arguments : [ String : String ] = [ "id" : post.identifier ]
		let route = "posts/\(post.identifier)"

		let request = self.secureDelete(path: self.pathForRoute(route), arguments: arguments)
		
		_ = UUHttpSession.executeRequest(request, { (parsedServerResponse) in
			completion(parsedServerResponse.httpError)
		})
	}
	
	public func reply(originalPost : MicroblogPost, content : String, completion: @escaping(Error?) -> ())
	{
		var arguments : [ String : String ] = [ "id" : originalPost.identifier,
											    "text" : content ]
		
		if let blogUid = self.uid
		{
			arguments["mp-destination"] = blogUid
		}
		
		let request = self.securePost(path: self.pathForRoute("posts/reply"), arguments: arguments)
		
		_ = UUHttpSession.executeRequest(request, { (parsedServerResponse) in
			completion(parsedServerResponse.httpError)
		})
	}
	
	
	public func uploadImage(image : UIImage, completion: @escaping(Error?, String?)->())
	{
		var resizedImage = image
		if image.size.width > 1800
		{
			resizedImage = MicroblogFramework.resizeImage(image: image, targetWidth: 1800.0)
		}
		
		let imageData = resizedImage.pngData()!
		var formData : Data = Data()
		let imageName = "file"
		let boundary = ProcessInfo.processInfo.globallyUniqueString
		
		var arguments : [ String : String ] = [:]

		if let blogUid = self.uid
		{
			arguments["mp-destination"] = blogUid
			
			formData.append(String("--\(boundary)\r\n").data(using: String.Encoding.utf8)!)
			formData.append(String("Content-Disposition: form-data; name=\"mp-destination\"\r\n\r\n").data(using: String.Encoding.utf8)!)
			formData.append(String("\(blogUid)\r\n").data(using:String.Encoding.utf8)!)
		}
		
		formData.append(String("--\(boundary)\r\n").data(using: String.Encoding.utf8)!)
		formData.append(String("Content-Disposition: form-data; name=\"\(imageName)\"; filename=\"image.jpg\"\r\n").data(using: String.Encoding.utf8)!)
		formData.append(String("Content-Type: image/jpeg\r\n\r\n").data(using: String.Encoding.utf8)!)
		formData.append(imageData)
		formData.append(String("\r\n").data(using: String.Encoding.utf8)!)
		formData.append(String("--\(boundary)--\r\n").data(using: String.Encoding.utf8)!)
		
		let request = self.securePost(path: self.pathForRoute("micropub/media"), arguments: arguments, body: formData)
		request.headerFields["Content-Type"] = "multipart/form-data; boundary=\(boundary)"

		_ = UUHttpSession.executeRequest(request, { (parsedServerResponse) in
			
			let publishedPath = parsedServerResponse.httpResponse?.allHeaderFields["Location"] as? String
			completion(parsedServerResponse.httpError, publishedPath)
		})
		
	}

	func pathForRoute(_ route : String) -> String
	{
		let fullPath : NSString = self.serverPath as NSString
		return fullPath.appendingPathComponent(route) as String
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// MARK: - Http setup helper functions
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	private var uid : String?
	private var token : String = ""
	private var serverPath = "http://micro.blog/"

	private func secureGet(path : String, arguments : [String : String]) -> UUHttpRequest
	{
		let request = UUHttpRequest.getRequest(path, arguments)
		request.headerFields["Authorization"] = "Bearer \(self.token)"
		
		return request
	}

	private func securePut(path : String, arguments : [String : String], body : Data? = nil) -> UUHttpRequest
	{
		let request = UUHttpRequest.putRequest(path, arguments, body, nil)
		request.headerFields["Authorization"] = "Bearer \(self.token)"
		
		return request
	}

	private func securePost(path : String, arguments : [String : String], body : Data? = nil) -> UUHttpRequest
	{
		let request = UUHttpRequest.postRequest(path, arguments, body, nil)
		request.headerFields["Authorization"] = "Bearer \(self.token)"
		
		return request
	}
	
	private func secureDelete(path : String, arguments : [String : String]) -> UUHttpRequest
	{
		let request = UUHttpRequest.deleteRequest(path, arguments)
		request.headerFields["Authorization"] = "Bearer \(self.token)"
		
		return request
	}



	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// MARK: - Image setup helper functions
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	private static func resizeImage(image: UIImage, targetWidth: CGFloat) -> UIImage {
	
		let targetSize = CGSize(width: targetWidth, height: image.size.height * (image.size.width / targetWidth))
    	let widthRatio  = targetSize.width  / image.size.width
    	let heightRatio = targetSize.height / image.size.height

    	var newSize: CGSize = CGSize(width: image.size.width * widthRatio,  height: image.size.height * widthRatio)
    	if (widthRatio > heightRatio) {
        	newSize = CGSize(width: image.size.width * heightRatio, height: image.size.height * heightRatio)
    	}

    	UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
    	image.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
    	let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
    	UIGraphicsEndImageContext()

    	return resizedImage!
	}

}



