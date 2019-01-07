Pod::Spec.new do |s|
  	s.name             = "Microblog"
  	s.version          = "0.0.1"

  	s.description      = <<-DESC
                       The Microblog framework enabled drop-in functionality to interact with the Micro.blog platform.
                       DESC
  	s.summary          = "A Swift library for interacting with the Micro.blog platform"

  	s.homepage         = "https://github.com/riverfold/snippets-example"
  	s.author           = "Micro.blog"
  	s.license          = { :type => 'Apache 2.0' }
  	s.source           = { :git => "https://github.com/riverfold/snippets-example.git", :tag => s.version.to_s }

#s.platform = :ios
	s.ios.deployment_target = "8.0"
	s.osx.deployment_target = "10.10"

	s.swift_version = "4.0"

	s.dependency 'UUSwift'

	s.subspec 'Core' do |ss|
    	ss.source_files = 'MicroblogFramework/**/*.{h,m,swift}'
    	ss.ios.frameworks = 'UIKit', 'Foundation', 'UUSwift'
		ss.osx.frameworks = 'CoreFoundation', 'UUSwift'
  	end

end

