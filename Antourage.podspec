Pod::Spec.new do |s|

  isDebug = false

  s.name             = 'Antourage'
  s.version          = '2.1.1'
  s.summary          = 'Antourage provides to users possibility to watch streams and use chat and polls'
  s.description      = <<-DESC
                        Antourage provides to users possibility to watch streams and use chat and polls.
                       DESC

  s.homepage         = 'https://github.com/antourage'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Mykola Vaniurskyi' => 'mv@leobit.com' }
  s.source           = { :git => 'https://github.com/antourage/AntViewer.git', :tag => s.version.to_s }

  s.platform     = :ios, "11.3"
  s.source_files = 'AntViewer/Classes/**/*.{swift}'

  if isDebug
    s.dependency 'ViewerExtension'
  else
    s.vendored_frameworks = 'AntViewer/MyFrameworks/ViewerExtension.xcframework'
  end

  s.resources = 'AntViewer/Classes/**/*.{plist}'
  s.xcconfig = {
    'SWIFT_INCLUDE_PATHS' => '$(PODS_ROOT)/Firebase/CoreOnly/Sources',
    'HEADER_SEARCH_PATHS' => '$(PODS_ROOT)/Firebase/CoreOnly/Sources'
  }
  s.pod_target_xcconfig = {
      'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'
  }
  s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
    
  s.frameworks = 'UIKit', 'AVKit', 'MediaPlayer', 'Foundation'
  s.dependency 'Firebase/Auth'
  s.dependency 'Firebase/Firestore'
  
end
