Pod::Spec.new do |s|

  s.name         = "InAppFw"
  s.version      = "0.0.1"
  s.summary      = "In App Purchase Manager framework for iOS"

  s.ios.deployment_target = '8.0'
  s.requires_arc = true
  s.platform = :ios
  s.framework = "UIKit"

  s.description  = <<-DESC
                   A longer description of InAppFw in Markdown format.

                   * Think: Why did you write this? What is the focus? What does it do?
                   * CocoaPods will be using this to generate tags, and improve search results.
                   * Try to keep it short, snappy and to the point.
                   * Finally, don't worry about the indent, CocoaPods strips it!
                   DESC

  s.homepage     = "https://github.com/sandorgyulai/InAppFramework"

  s.license = { :type => "MIT", :file => "LICENSE" }

  s.author = { "Sándor Gyulai" => "sandor.gyulai@icloud.com" }

  s.source = { :git => "https://github.com/sandorgyulai/InAppFramework.git", :tag => "#{s.version}" }

  s.source_files = "InAppFw/**/*.{swift}"

  s.exclude_files = "Classes/Exclude"

end
