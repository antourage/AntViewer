//
//  AntourageAVPlayerConfiguration.swift
//  Antourage
//
//  Created by Mykola Vaniurskyi on 14.11.2020.
//

import AVFoundation
import ViewerExtension

public struct AntourageAVPlayerConfiguration: PlayerConfiguration {

    // Buffering State
    public let rateObservingTimeout: TimeInterval = 6
    public let rateObservingTickTime: TimeInterval = 0.3

    // General Audio preferences
    public let preferredTimescale = CMTimeScale(NSEC_PER_SEC)
    public let periodicPlayingTime: CMTime
    public let audioSessionCategory = AVAudioSession.Category.playback

    // Reachability Service
    public let reachabilityURLSessionTimeout: TimeInterval = 3
    //swiftlint:disable:next force_unwrapping
    public let reachabilityNetworkTestingURL = URL(string: "https://www.google.com")!
    public let reachabilityNetworkTestingTickTime: TimeInterval = 4
    public let reachabilityNetworkTestingIteration: UInt = 4

    public var useDefaultRemoteCommand = false
    
    public let allowsExternalPlayback = false

    public let itemLoadedAssetKeys = ["playable", "duration"]

    public init() {
        periodicPlayingTime = CMTimeMake(value: 1, timescale: 5)
    }
}
