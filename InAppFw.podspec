Pod::Spec.new do |s|

  s.platform = :ios
  s.ios.deployment_target = '8.0'
  s.name = "InAppFw"
  s.summary = "In App Purchase Manager framework for iOS"
  s.requires_arc = true
  s.version = "0.9.1"
  s.license = { :type => "MIT", :file => "LICENSE" }
  s.author = { "Sandor Gyulai" => "sandor.gyulai@icloud.com" }
  s.homepage = "https://github.com/sandorgyulai/InAppFramework"
  s.source = { :git => "https://github.com/sandorgyulai/InAppFramework.git", :tag => "#{s.version}"}
  s.framework = "UIKit"
  s.source_files = "InAppFw/**/*.{swift}"

end
