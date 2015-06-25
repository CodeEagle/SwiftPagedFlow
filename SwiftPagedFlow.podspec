Pod::Spec.new do |s|
  s.name             = "SwiftPagedFlow"
  s.version          = "0.1.1"
  s.summary          = "PagedFlowView Swift Version "
  s.description      = <<-DESC
                       A Paging Enabled Flow View, like screenshots view in iPhone App Store.
                       DESC
  s.homepage         = "https://github.com/CodeEagle/SwiftPagedFlow"
  s.screenshots      = "https://raw.githubusercontent.com/CodeEagle/SwiftPagedFlow/master/screenshot.png"
  s.license          = 'MIT'
  s.author           = { "CodeEagle" => "stasura@hotmail.com" }
  s.source           = { :git => "https://github.com/CodeEagle/SwiftPagedFlow.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/_SelfStudio'

  s.platform     = :ios, '8.0'
  s.requires_arc = true
  s.source_files = 'Source/*'
 s.frameworks = 'UIKit'
end
