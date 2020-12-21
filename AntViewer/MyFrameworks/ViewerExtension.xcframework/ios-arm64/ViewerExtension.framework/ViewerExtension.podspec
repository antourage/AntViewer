
Pod::Spec.new do |s|
    s.platform = :ios
    s.ios.deployment_target = '11.3'
    s.name = "ViewerExtension"
    s.summary = "ViewerExtension"
    s.requires_arc = true
    s.version = "1.0.0"
    s.license = "MIT"
    s.author = { "Mykola Vaniurskyi" => "mv@leobit.co" }
    s.homepage = "https://github.com/blabla"
    
    s.source       = { :path => '.' }
    s.framework = "UIKit"
    s.source_files = "ViewerExtension/**/*.{swift,xcdatamodeld}", "Third_party/SignalR/Sources/SignalRClient/**/*.{swift}",
        "Third_party/ModernAVPlayer/Sources/Core/**/*.{swift}"
    s.resources = ["ViewerExtension/**/*.{xcdatamodeld,xib}"]
    s.resource_bundles = {
    'ViewerExtension' => ['ViewerExtension/Assets/**/*', "ViewerExtension/Localization/**/*.{strings,stringsdict}"]
  }
    s.swift_version = "5.2"
    
    end
    
