//
//  Microblog+XMLRPC.swift
//  MicroblogFramework
//
//  Created by Jonathan Hays on 12/17/18.
//  Copyright © 2018 Micro.blog. All rights reserved.
//

import UIKit
import UUSwift

@objc public class MicroblogXMLRPCIdentity : NSObject {

	@objc static public func create(username : String, password : String, endpoint : String, blogId : String, wordPress : Bool) -> MicroblogXMLRPCIdentity {
		let identity = MicroblogXMLRPCIdentity()
		identity.blogUsername = username
		identity.blogPassword = password
		identity.endpoint = endpoint
		identity.wordPress = wordPress
		
		if blogId.count > 0 {
			identity.blogId = blogId
		}

		return identity
	}
	
	var blogId = "0"
	var blogUsername = ""
	var blogPassword = ""
	var endpoint = ""
	var wordPress = false
}


@objc public class MicroblogXMLRPCRequest : NSObject {

	@objc static public func publishPostRequest(identity : MicroblogXMLRPCIdentity, existingPost : Bool) -> MicroblogXMLRPCRequest {
	
		var method = ""
		if (identity.wordPress && existingPost) {
			method = "wp.editPost"
		}
		else if (identity.wordPress) {
			method = "wp.newPost"
		}
		else if (existingPost) {
			method = "metaWeblog.editPost"
		}
		else {
			method =  "metaWeblog.newPost"
		}

		return MicroblogXMLRPCRequest(identity : identity, method: method)
	}

	@objc static public func publishPhotoRequest(identity : MicroblogXMLRPCIdentity) -> MicroblogXMLRPCRequest {
		let method = "metaWeblog.newMediaObject"
		return MicroblogXMLRPCRequest(identity: identity, method: method)
	}

	@objc static public func unpublishRequest(identity : MicroblogXMLRPCIdentity) -> MicroblogXMLRPCRequest {
		let method = "metaWeblog.deletePost"
		return MicroblogXMLRPCRequest(identity : identity, method: method)
	}
	
	@objc static public func fetchPostInfoRequest(identity : MicroblogXMLRPCIdentity) -> MicroblogXMLRPCRequest {

		var method = "metaWeblog.getPost"
		if identity.wordPress {
			method = "wp.getPost"
		}

		return MicroblogXMLRPCRequest(identity : identity, method: method)
	}

	@objc public convenience init(identity : MicroblogXMLRPCIdentity, method : String) {
		self.init()

		self.identity = identity
		self.method = method
	}

	var identity : MicroblogXMLRPCIdentity = MicroblogXMLRPCIdentity()
	var method = ""
	
}


extension MicroblogFramework {


	@objc public func editPost(postIdentifier : String,
							   title : String,
							   content : String,
							   postFormat : String,
							   postCategory : String,
							   request : MicroblogXMLRPCRequest, completion: @escaping(Error?, String?) -> ()) {
		
		let params : [Any] = self.buildPostParameters(identity : request.identity,
													  postIdentifier: postIdentifier,
													  title: title,
													  htmlContent: content,
													  postFormat: postFormat,
													  postCategory: postCategory)

		let xmlRPCRequest = MBXMLRPCRequest(url: request.identity.endpoint)
		_ = xmlRPCRequest.sendMethod(method: request.method, params: params) { (response) in
			
			if let data : Data = response.rawResponse {
				let xmlrpc = MBXMLRPCParser.parsedResponseFromData(data)
				if xmlrpc.responseFault == nil {
					let postId : String? = xmlrpc.responseParams.first as? String
					completion(response.httpError, postId)
					return
				}
			}
			
			completion(response.httpError, nil)
		}
	}


	@objc public func post(title : String,
						   content : String,
						   postFormat : String,
						   postCategory : String,
						   request : MicroblogXMLRPCRequest, completion: @escaping(Error?, String?) -> ()) {

		let params : [Any] = self.buildPostParameters(identity:request.identity,
													  postIdentifier: nil,
													  title: title,
													  htmlContent: content,
													  postFormat: postFormat,
													  postCategory: postCategory)
		
		let xmlRPCRequest = MBXMLRPCRequest(url: request.identity.endpoint)
		_ = xmlRPCRequest.sendMethod(method: request.method, params: params) { (response) in
			
			if let data : Data = response.rawResponse {
				let xmlrpc = MBXMLRPCParser.parsedResponseFromData(data)
				if xmlrpc.responseFault == nil {
					let postId : String? = xmlrpc.responseParams.first as? String
					completion(response.httpError, postId)
					return
				}
			}
			
			completion(response.httpError, nil)
		}
	}
	

	@objc public func uploadImage(image : UIImage, 	request : MicroblogXMLRPCRequest,
													completion: @escaping(Error?, String?, String?) -> ())
	{
		var resizedImage = image
		if image.size.width > 1800.0
		{
			resizedImage = resizedImage.uuScaleToWidth(targetWidth: 1800.0)
		}

		let d = resizedImage.jpegData(compressionQuality: 0.8)
		
		let filename = UUID().uuidString.replacingOccurrences(of: "-", with: "") + ".jpg"
		let params : [Any] = [ request.identity.blogId,
							   request.identity.blogUsername,
							   request.identity.blogPassword, [ "name" : filename,
													   "type" : "image/jpeg",
													   "bits": d! ]]
		
		let xmlRPCRequest = MBXMLRPCRequest(url: request.identity.endpoint)
		_ = xmlRPCRequest.sendMethod(method: request.method, params: params) { (response) in
			
			if let data : Data = response.rawResponse {
				let xmlrpc = MBXMLRPCParser.parsedResponseFromData(data)
				if xmlrpc.responseFault == nil {
					var imageUrl : String? = nil
					var imageIdentifier : String? = nil
						
					if let imageDictionary = xmlrpc.responseParams.first as? NSDictionary {
						imageUrl = imageDictionary.object(forKey: "url") as? String
						if (imageUrl == nil) {
							imageUrl = imageDictionary.object(forKey: "link") as? String
						}
							
						imageIdentifier = imageDictionary.object(forKey: "id") as? String
							
						if imageUrl != nil && imageIdentifier == nil {
							imageIdentifier = ""
						}
					}
						
					completion(response.httpError, imageUrl, imageIdentifier)
					return
				}
			}
			
			completion(response.httpError, nil, nil)
		}
	}
	
	@objc public func unpublish(postIdentifier : String, request : MicroblogXMLRPCRequest, completion: @escaping(Error?) -> ()) {

		let params : [Any] = [ "", postIdentifier, request.identity.blogUsername, request.identity.blogPassword ]
		
		let xmlRPCRequest = MBXMLRPCRequest(url: request.identity.endpoint)
		_ = xmlRPCRequest.sendMethod(method: request.method, params: params) { (response) in
			
			if let data : Data = response.rawResponse {
				let xmlrpc = MBXMLRPCParser.parsedResponseFromData(data)
				if let fault = xmlrpc.responseFault {
				
					//Check for a 404 in which case, this post is unpublished so there's no error...
			 		if let faultCode = fault["faultCode"] as? NSString
			 		{
						if faultCode.integerValue == 404 {
							completion(nil)
							return
						}
					}
				}
			}
		
			completion(response.httpError)
		}
	}

	@objc public func fetchPostURL(postIdentifier : String, request : MicroblogXMLRPCRequest, completion: @escaping(Error?, String?) -> ()) {
		
		var params : [Any] = [ postIdentifier, request.identity.blogUsername, request.identity.blogPassword ]
		if request.identity.wordPress == true {
			params.append(postIdentifier)
			params.append(["link"])
		}

		let xmlRPCRequest = MBXMLRPCRequest(url: request.identity.endpoint)
		_ = xmlRPCRequest.sendMethod(method: request.method, params: params) { (response) in
			
			if let data : Data = response.rawResponse {
				let xmlrpc = MBXMLRPCParser.parsedResponseFromData(data)
				if let responseDictionary = xmlrpc.responseParams.first as? NSDictionary {
					var url : String? = responseDictionary.object(forKey: "url") as? String
					if (url == nil) {
						url = responseDictionary.object(forKey: "link") as? String
					}
					
					completion(response.httpError, url)
					return
				}
			}
		
			completion(response.httpError, nil)
		}
	}
	
	
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// MARK: - Private
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	private func buildPostParameters(identity : MicroblogXMLRPCIdentity,
									 postIdentifier : String?,
									 title : String,
									 htmlContent : String,
									 postFormat : String,
									 postCategory : String) -> [Any] {
	
		let content = NSMutableDictionary()
		
		if identity.wordPress {
			content["post_status"] = "publish"
			content["post_content"] = htmlContent
			if postFormat.count > 0 {
				content["post_format"] = postFormat
			}
			if postCategory.count > 0 {
				content["terms"] = ["category" : [postCategory] ]
			}
			if title.count > 0 {
				content["post_title"] = title
			}
		}
		else {
			content["description"] = htmlContent
			if title.count > 0 {
				content["title"] = title
			}
		}

		var params : [Any] = [ ]
		let publish = MBBoolean(true)

		if let publishedGUID = postIdentifier {
			if identity.wordPress == true {
				params = [ identity.blogId, identity.blogUsername, identity.blogPassword, publishedGUID, content ]
			}
			else {
				params = [ publishedGUID, identity.blogUsername, identity.blogPassword, content, publish ]
			}
		}
		else {
			if identity.wordPress == true {
				params = [ identity.blogId, identity.blogUsername, identity.blogPassword, content ]
			}
			else {
				params = [ identity.blogId, identity.blogUsername, identity.blogPassword, content, publish ]
			}
		}
		return params
	}
}
