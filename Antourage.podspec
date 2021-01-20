Pod::Spec.new do |s|

  isDebug = false

  s.name             = 'Antourage'
  s.version          = '2.1.0'
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
    s.preserve_paths      = 'ViewerExtension.xcframework', 'ViewerExtension.dSYMs/ViewerExtension.framework.ios-arm64.dSYM',  'ViewerExtension.dSYMs/ViewerExtension.framework.ios-arm64_x86_64-simulator.dSYM'
    s.vendored_frameworks = 'AntViewer/MyFrameworks/ViewerExtension.xcframework'
  end

  s.resources = 'AntViewer/Classes/**/*.{plist}'
  s.pod_target_xcconfig = {'DEFINES_MODULE' => 'YES'}
  s.static_framework = true
  s.xcconfig = {
    'FRAMEWORK_SEARCH_PATHS' => '\'$(PODS_ROOT)/Antourage/AntViewer/MyFrameworks/**\'',
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
