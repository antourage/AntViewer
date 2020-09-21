#
# Be sure to run `pod lib lint Antourage.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|

  isDebug = false

  s.name             = 'Antourage'
  s.version          = '2.0.18'
  s.summary          = 'Antourage provides to users possibility to watch streams and use chat and polls'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
                        Antourage provides to users possibility to watch streams and use chat and polls.
                       DESC

  s.homepage         = 'https://github.com/antourage'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Mykola Vaniurskyi' => 'mv@leobit.com' }
  s.source           = { :git => 'https://github.com/antourage/AntViewer.git', :tag => s.version.to_s }

  s.platform     = :ios, "11.3"
  s.source_files = 'AntViewer/Classes/**/*.{swift}'

  if isDebug
    s.dependency 'AntViewerExt'
  else
    s.ios.vendored_frameworks = 'AntViewer/MyFrameworks/AntViewerExt.framework'
  end

  s.resources = 'AntViewer/Classes/**/*.{storyboard,xib,plist,xcdatamodeld}'
  s.resource_bundles = {
    'AntWidget' => ['AntViewer/Assets/**/*']
  }
  s.pod_target_xcconfig = {'DEFINES_MODULE' => 'YES'}
  s.static_framework = true
  s.xcconfig = { 'SWIFT_INCLUDE_PATHS' => '$(PODS_ROOT)/Firebase/CoreOnly/Sources',
    'HEADER_SEARCH_PATHS' => '$(PODS_ROOT)/Firebase/CoreOnly/Sources'
  }
  s.pod_target_xcconfig = {
      'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'
  }
  s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
    
  s.frameworks = 'UIKit', 'AVKit'
  s.dependency 'Firebase/Auth'
  s.dependency 'Firebase/Firestore'

  s.swift_version = "5.2"
end
