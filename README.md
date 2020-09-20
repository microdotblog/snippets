# snippets
[![Platform](http://cocoapod-badges.herokuapp.com/p/SnippetsFramework/badge.png)](http://cocoadocs.org/docsets/SnippetsFramework)
[![Version](http://cocoapod-badges.herokuapp.com/v/SnippetsFramework/badge.png)](http://cocoadocs.org/docsets/SnippetsFramework)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

## Overview
Snippets is a framework for microblogging on iOS, OSX, and tvOS. 

Included in the framework:
- Micro.blog JSON API for querying the Micro.blog platform:  (See [here](http://help.micro.blog/2017/api-json/))
- Micropub compatible posting API (See [here](http://help.micro.blog/2017/api-posting/))
- XML-RPC compatible posting API
- A complete reference application implementing the available APIs


### Reference App Screenshot
![Screenshot](https://raw.githubusercontent.com/microdotblog/snippets/master/Screenshots/Snippets01.jpg)

## Requirements

This library requires a deployment target of iOS 10.0 or greater, OSX 10.10 or greater or tvOS 10.0 or greater.

### Swift and Objective-C

This library is written entirely in Swift but has been made compatible with Objective-C calling applications. 


## Installation

### - Swift Package Manager

Snippets supports native integration with the Swift Package Manager.

### - Cocoapods

The Snippets framework is available through [CocoaPods](http://cocoapods.org). To install it, simply add the following line to your `Podfile`:

```
pod 'SnippetsFramework'
```

### - Carthage

Snippets may be installed via [Carthage](https://github.com/Carthage/Carthage). To install it, simply add the following line to your `Cartfile`:

```
github "microdotblog/snippets"
```

## License

The Snippets framework is available under the MIT license. See [`LICENSE.md`](https://github.com/microdotblog/snippets/blob/develop/LICENSE.md) for more information.

