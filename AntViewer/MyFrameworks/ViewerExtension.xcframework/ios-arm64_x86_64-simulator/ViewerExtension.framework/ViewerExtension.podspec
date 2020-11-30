
Pod::Spec.new do |s|
    s.platform = :ios
    s.ios.deployment_target = '11'
    s.name = "ViewerExtension"
    s.summary = "ViewerExtension"
    s.requires_arc = true
    s.version = "1.0.0"
    s.license = "MIT"
    s.author = { "Mykola Vaniurskyi" => "mv@leobit.co" }
    s.homepage = "https://github.com/blabla"
    
    s.source       = { :path => '.' }
    s.framework = "UIKit"
    s.source_files = "ViewerExtension/**/*.{swift,xcdatamodeld}", "Third_party/SignalR/Sources/SignalRClient/**/*.{swift}"
    s.resources = ["ViewerExtension/**/*.{xcdatamodeld}"]

    # "ViewerExtension/Third_party/ModernAVPlayer/Sources/Core"
    # s.resources = "AntViewerExt/Resources/*.{png,jpeg,jpg,json,xcassets,plist}"
    
    # 10
    s.swift_version = "5"
    
    end
    
