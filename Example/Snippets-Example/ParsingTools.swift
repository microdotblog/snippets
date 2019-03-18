//
//  ParsingTools.swift
//  Snippets-Example
//
//  Created by Jonathan Hays on 3/14/19.
//  Copyright © 2019 Micro.blog. All rights reserved.
//

import UIKit
import Snippets
import UUSwift

class SnippetsParsingTools {
	
	public static func convertPostsToTimelineDictionaries(_ items : [SnippetsPost]) -> [[String : Any]] {
		
		var parsedItems : [[String : Any]] = []
		
		for item in items {
			var dictionary = SnippetsParsingTools.extractImages(html: item.htmlText)
			dictionary["post"] = item
			
			parsedItems.append(dictionary)
		}
		
		return parsedItems
	}

	
	private static func extractImages(html : String) -> [String : Any]
	{
		var content : NSString = html as NSString
		var images : [String] = []
		var dictionary : [String : Any] = [:]
		
		if content.contains("<img")
		{
			var aspectRatio : CGFloat = 0.0
			
			while (content.contains("<img"))
			{
				var width : CGFloat = 0.0
				var height : CGFloat = 0.0
				
				// Extract the entire image tag...
				var image : NSString = content.substring(from: content.range(of: "<img").location) as NSString
				
				if (image.contains("width=") && image.contains("height=")) {
					var widthString : NSString = image.substring(from: image.range(of: "width=").location + 7) as NSString
					var heightString: NSString = image.substring(from: image.range(of: "height=").location + 8) as NSString
					
					widthString = widthString.substring(to: widthString.range(of: "\"").location) as NSString
					heightString = heightString.substring(to: heightString.range(of: "\"").location) as NSString
					
					width = CGFloat(widthString.floatValue);
					height = CGFloat(heightString.floatValue);
					
					if (width > 0.0 && height > 0.0)
					{
						let currentAspectRatio = height / width
						if (currentAspectRatio > aspectRatio) {
							aspectRatio = currentAspectRatio
						}
					}
				}
				
				image = image.substring(to: image.range(of: ">").location + 1) as NSString
				
				let shouldIgnore = image.contains("1em;")
				
				var replacement : NSString = ""
				
				if (shouldIgnore)
				{
					if image.contains("alt=") {
						var altTag : NSString = image.substring(from: image.range(of: "alt=").location + 4) as NSString
						altTag = altTag.substring(from: altTag.range(of: "\"").location + 1) as NSString
						altTag = altTag.substring(to: altTag.range(of: "\"").location) as NSString
						replacement = altTag
					}
				}
				
				// Remove the image tag from the content...
				content = content.replacingOccurrences(of: image as String, with: replacement as String) as NSString
				
				// Pull just the actual URL from the image tag...
				if (!shouldIgnore && image.contains("src=")) {
					image = image.substring(from: image.range(of: "src=").location + 5) as NSString
					image = image.substring(to: image.range(of: "\"").location) as NSString
					
					//Because we are coming from HTML land, we need to be careful with & symbols
					image = image.replacingOccurrences(of: "&amp;", with: "&") as NSString
					
					images.append(image as String)
				}
			}
		}
		
		/*
		// Remove trailing new lines and carriage returns
		var hasTrailingWhitespace = content.hasSuffix("\n") ||
		content.hasSuffix("\r") ||
		content.hasSuffix("<p></p>")
		
		while hasTrailingWhitespace {
		
		if content.hasSuffix("\n") || content.hasSuffix("\r") {
		content = content.substring(to: content.length - 1) as NSString
		}
		else if content.hasSuffix("<p></p>") {
		content = content.substring(to: content.length - 7) as NSString
		}
		
		hasTrailingWhitespace = content.hasSuffix("\n") ||
		content.hasSuffix("\r") ||
		content.hasSuffix("<p></p>")
		}
		*/
		
		let htmlString = content as String;
		let htmlData = htmlString.data(using: .utf16, allowLossyConversion: false)!
		
		let options : [NSAttributedString.DocumentReadingOptionKey : Any] = [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue]
		var attributedString = try? NSAttributedString(data: htmlData, options: options, documentAttributes: nil)
		
		// After conversion from html, there are occassionally trailing carriage returns
		if var attribString = attributedString {
			while attribString.string.hasSuffix("\n") || attribString.string.hasSuffix("\r") {
				attribString = attribString.attributedSubstring(from: NSRange(location: 0, length: attribString.length - 1))
			}
			
			while attribString.string.hasPrefix("\n") || attribString.string.hasPrefix("\r") {
				attribString = attribString.attributedSubstring(from: NSRange(location: 1, length: attribString.length - 1))
			}
			
			attributedString = attribString
		}
		else {
			attributedString = NSAttributedString(string:"")
		}
		
		let mutableAttributedString = NSMutableAttributedString(attributedString: attributedString!)
		mutableAttributedString.addAttributes([.font : UIFont(name: "AvenirNext-Regular", size: 14.0) as Any], range: NSRange(location: 0, length: attributedString!.length))
		attributedString = mutableAttributedString
		
		
		dictionary["attributedString"] = attributedString
		dictionary["images"] = images
		dictionary["content"] = content
		
		return dictionary
	}
}
