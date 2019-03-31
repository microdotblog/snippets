Pod::Spec.new do |s|
  	s.name             = "SnippetsFramework"
	s.module_name	   = "Snippets"
  	s.version          = "0.0.7"

  	s.description      = <<-DESC
                       The Snippets framework enables drop-in functionality to interact with the Micro.blog platform.
                       DESC
  	s.summary          = "A Swift library for interacting with the Micro.blog platform"

  	s.homepage         = "https://github.com/microdotblog/snippets"
  	s.author           = "Micro.blog"
  	s.license          = { :type => 'MIT' }
  	s.source           = { :git => "https://github.com/microdotblog/snippets.git", :tag => s.version.to_s }

	s.platform = :ios
	s.ios.deployment_target = "8.0"
	s.osx.deployment_target = "10.10"

	s.swift_version = "4.0"

	s.dependency 'UUSwift'

	s.subspec 'Core' do |ss|
    	ss.source_files = 'Snippets/**/*.{h,m,swift}'
    	ss.ios.frameworks = 'UIKit', 'Foundation', 'UUSwift'
		ss.osx.frameworks = 'CoreFoundation', 'UUSwift'
  	end

end

