//
//  Microblog.swift
//  MicroblogFramework
//
//  Created by Jonathan Hays on 10/22/18.
//  Copyright © 2018 Jonathan Hays. All rights reserved.
//

#if os(macOS)
import AppKit
import UUSwift
#else
import UIKit
import UUSwift
#endif


public class MicroblogFramework : NSObject {

	@objc public static let shared = MicroblogFramework()
	
	@objc public func configure(permanentToken : String, blogUid : String?)
	{
		self.uid = blogUid
		self.token = permanentToken
	}
	
	@objc public func setServerPath(_ path : String)
	{
		self.serverPath = path
	}
	
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// MARK: - Signin
	// Sign-in is generally a 2-step process. First, request an email with a temporary token. Then exchange the temporary token for a permanent token
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	@objc public func requestUserLoginEmail(email: String, appName : String, redirect: String, completion: @escaping (Error?) -> ())
	{
		let arguments : [String : String] = [ 	"email" : email,
												"app_name" : appName,
												"redirect_url" : redirect ]
	
		_ = UUHttpSession.post(self.pathForRoute("account/signin"), arguments, nil, nil) { (parsedServerResponse) in
			completion(parsedServerResponse.httpError)
		}
	}
	
	@objc public func requestPermanentTokenFromTemporaryToken(token : String, completion: @escaping(Error?, String?) -> ())
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
	@objc public func fetchUserInfo(completion: @escaping(Error?, MicroblogUser?)-> ())
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
	@objc public func fetchUserConfiguration(completion: @escaping(Error?, [String : Any])-> ())
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
	
	@objc public func fetchUserTimeline(completion: @escaping(Error?, [MicroblogPost]) -> ())
	{
		self.fetchTimeline(self.pathForRoute("posts/all"), completion: completion)
	}
	
	@objc public func fetchUserPhotoTimeline(completion: @escaping(Error?, [MicroblogPost]) -> ())
	{
		self.fetchTimeline(self.pathForRoute("posts/photos"), completion: completion)
	}

	@objc public func fetchUserMentions(completion: @escaping(Error?, [MicroblogPost]) -> ())
	{
		self.fetchTimeline(self.pathForRoute("posts/mentions"), completion: completion)
	}

	@objc public func fetchUserFavorites(completion: @escaping(Error?, [MicroblogPost]) -> ())
	{
		self.fetchTimeline(self.pathForRoute("posts/favorites"), completion: completion)
	}

	@objc public func fetchDiscoverTimeline(collection : String? = nil, completion: @escaping(Error?, [MicroblogPost]) -> ())
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

	@objc public func fetchUserPosts(user : MicroblogUser, completion: @escaping(Error?, [MicroblogPost]) -> ())
	{
		let route = "posts/\(user.userHandle)"
		self.fetchTimeline(self.pathForRoute(route), completion: completion)
	}
	
	@objc public func fetchConversation(post : MicroblogPost, completion: @escaping(Error?, [MicroblogPost]) -> ())
	{
		let route = "posts/conversation?id=\(post.identifier)"
		self.fetchTimeline(self.pathForRoute(route), completion: completion)
	}

	@objc public func checkForPostsSince(post : MicroblogPost, completion: @escaping(Error?, NSInteger, TimeInterval) -> ())
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

			completion(parsedServerResponse.httpError, 0, 0)
		})
	}

	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// MARK: - Follow Interface
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	@objc public func follow(user : MicroblogUser, completion: @escaping(Error?) -> ())
	{
		let arguments : [ String : String ] = [ "username" : user.userHandle ]
		
		let request = self.securePost(path: self.pathForRoute("users/follow"), arguments: arguments)
		
		_ = UUHttpSession.executeRequest(request, { (parsedServerResponse) in
			completion(parsedServerResponse.httpError)
		})
	}

	@objc public func unfollow(user : MicroblogUser, completion: @escaping(Error?) -> ())
	{
		let arguments : [ String : String ] = [ "username" : user.userHandle ]
		
		let request = self.securePost(path: self.pathForRoute("users/unfollow"), arguments: arguments)
		
		_ = UUHttpSession.executeRequest(request, { (parsedServerResponse) in
			completion(parsedServerResponse.httpError)
		})
	}
	
	@objc public func checkFollowingStatus(user : MicroblogUser, completion: @escaping(Error?, Bool) -> ())
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
	
	@objc public func listFollowers(user : MicroblogUser, completeList : Bool, completion: @escaping(Error?, [MicroblogUser]) -> ())
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

	@objc public func favorite(post : MicroblogPost, completion: @escaping(Error?) -> ())
	{
		let arguments : [ String : String ] = [ "id" : post.identifier ]

		let request = self.securePost(path: self.pathForRoute("favorites"), arguments: arguments)
		
		_ = UUHttpSession.executeRequest(request, { (parsedServerResponse) in
			completion(parsedServerResponse.httpError)
		})
	}

	@objc public func unfavorite(post : MicroblogPost, completion: @escaping(Error?) -> ())
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
	
	@objc public func postText(title : String, content : String, photos : [String], altTags : [String], completion: @escaping(Error?, String?) -> ())
	{
		var bodyText = ""
		bodyText = self.appendParameter(body: bodyText, name: "name", content: title)
		bodyText = self.appendParameter(body: bodyText, name: "content", content: content)
		bodyText = self.appendParameter(body: bodyText, name: "h", content: "entry")

		if let blogUid = self.uid
		{
			bodyText = self.appendParameter(body: bodyText, name: "mp-destination", content: blogUid)
		}

		for photoPath in photos
		{
			bodyText = self.appendParameter(body: bodyText, name: "photo[]", content: photoPath)
		}

		for altTag in altTags
		{
			bodyText = self.appendParameter(body: bodyText, name: "mp-photo-alt[]", content: altTag)
		}

		let body : Data = bodyText.data(using: .utf8)!
		let request = self.securePost(path: self.pathForRoute("micropub"), arguments: [:], body: body)
		_ = UUHttpSession.executeRequest(request, { (parsedServerResponse) in
			let publishedPath = parsedServerResponse.httpResponse?.allHeaderFields["Location"] as? String
			completion(parsedServerResponse.httpError, publishedPath)
		})
	}
	
	@objc public func postHtml(title : String, content : String, completion: @escaping(Error?, String?) -> ())
	{
		let properties : [ String : Any ] = [ "name" 	: [ title ],
											  "content" : [ [ "html" : content ] ],
											  "photo" 	: [ ]
											]
		
		var arguments : [ String : Any ] = 	[	"type" : ["h-entry"],
												"properties" : properties
											]
		
		if let blogUid = self.uid
		{
			arguments["mp-destination"] = blogUid
		}
		
		do {
			let body = try JSONSerialization.data(withJSONObject: arguments, options: .prettyPrinted)
			
			let request = self.securePost(path: self.pathForRoute("micropub"), arguments: [:], body: body)
			
			_ = UUHttpSession.executeRequest(request, { (parsedServerResponse) in
				let publishedPath = parsedServerResponse.httpResponse?.allHeaderFields["Location"] as? String
				completion(parsedServerResponse.httpError, publishedPath)
			})
			
		}
		catch {
		}
	}
	
	private func deletePostByUrl(path : String, completion: @escaping(Error?) -> ())
	{
		var bodyText = ""
		bodyText = self.appendParameter(body: bodyText, name: "action", content: "delete")
		bodyText = self.appendParameter(body: bodyText, name: "url", content: path)
		if let blogUid = self.uid
		{
			bodyText = self.appendParameter(body: bodyText, name: "mp-destination", content: blogUid)
		}

		let body : Data = bodyText.data(using: .utf8)!
		let request = self.securePost(path: self.pathForRoute("micropub"), arguments: [:], body: body)
		_ = UUHttpSession.executeRequest(request, { (parsedServerResponse) in
			completion(parsedServerResponse.httpError)
		})
	}
	
	private func deletePostByIdentifier(identifier : String, completion: @escaping(Error?) -> ())
	{
		let arguments : [ String : String ] = [ "id" : identifier ]
		let route = "posts/\(identifier)"

		let request = self.secureDelete(path: self.pathForRoute(route), arguments: arguments)
		
		_ = UUHttpSession.executeRequest(request, { (parsedServerResponse) in
			completion(parsedServerResponse.httpError)
		})
	}
	
	@objc public func deletePost(post : MicroblogPost, completion: @escaping(Error?) -> ())
	{
		// There are actually two ways to delete posts. The safer way is if you have the post identifier
		// The other way is more of the "micropub" way in which you just have the path to the post
		if (post.identifier.count > 0)
		{
			self.deletePostByIdentifier(identifier: post.identifier, completion: completion)
		}
		else
		{
			self.deletePostByUrl(path: post.path, completion: completion)
		}
	}
	
	@objc public func reply(originalPost : MicroblogPost, content : String, completion: @escaping(Error?) -> ())
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
	
	
	@objc public func uploadImage(image : MBImage, completion: @escaping(Error?, String?)->())
	{
		let resizedImage = image
		//var resizedImage = image
		//if image.size.width > 1800.0
		//{
		//	resizedImage = resizedImage.uuScaleToWidth(targetWidth: 1800.0 )
		//}

		let imageData = resizedImage.uuJpegData(0.8)!
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

	private func pathForRoute(_ route : String) -> String
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

	private func appendParameter(body : String, name : String, content : String) -> String
	{
		var newBody = body
		if (body.count > 0 && content.count > 0)
		{
			newBody += "&"
		}

		if (content.count > 0 && name.count > 0)
		{
			newBody += "\(name.uuUrlEncoded())=\(content.uuUrlEncoded())"
		}
		
		return newBody
	}

}



