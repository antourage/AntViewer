//
//  AVPlayerView.swift
//  
//
//  Created by Maryan Luchko on 3/13/19.
//

import UIKit
import AVFoundation

class AVPlayerView: CacheImageView {
  
  var player: AVPlayer? {
      get {
          return playerLayer.player
      }
      set {
          playerLayer.player = newValue
      }
  }
  
  var playerLayer: AVPlayerLayer {
      return layer as! AVPlayerLayer
  }
  
  override public class var layerClass: AnyClass {
    return AVPlayerLayer.self
  }
}
