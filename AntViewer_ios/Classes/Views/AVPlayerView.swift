//
//  AVPlayerView.swift
//  
//
//  Created by Maryan Luchko on 3/13/19.
//

import UIKit
import AVFoundation

class AVPlayerView: CacheImageView {
  override public class var layerClass: AnyClass {
    return AVPlayerLayer.self
  }
}
