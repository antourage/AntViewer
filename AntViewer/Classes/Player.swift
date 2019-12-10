//
//  Player.swift
//  abseil
//
//  Created by Mykola Vaniurskyi on 24.11.2019.
//

import Foundation
import AVKit

class Player: NSObject {
  
  private let keys: [String] = ["playable", "duration", "tracks"]
  
  private var playerTimeObserver: Any?
  private var isPlayerReadyToPlay = false
  private var seekTo: Double?
  private var observerHandler: ((CMTime, Bool) -> Void)?
  
  var isPlayerPaused = false
  var playerReadyToPlay: (() -> Void)?
  var onVideoEnd: (() -> Void)? {
    didSet {
        NotificationCenter.default.addObserver(self, selector: #selector(onVideoEndHandler), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player.currentItem)
    }
  }
  var currentTime: Double {
    player.currentTime().seconds
  }
  
  private(set) var player: AVPlayer = {
    let newPlayer = AVPlayer()
    newPlayer.automaticallyWaitsToMinimizeStalling = false
    return newPlayer
  }()
  
  private var asset: AVURLAsset
  
  private var playerItem: AVPlayerItem? {
    didSet {
      playerItem?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.new, .initial], context: nil)
      
      if #available(iOS 13.0, *) {
        if let howFarNow = playerItem?.configuredTimeOffsetFromLive, let recommended = playerItem?.recommendedTimeOffsetFromLive {
          if howFarNow < recommended {
            playerItem?.configuredTimeOffsetFromLive = recommended
          }
        }
        playerItem?.automaticallyPreservesTimeOffsetFromLive = true
      }
      playerItem?.preferredForwardBufferDuration = 5
      
      if let seekTo = seekTo, seekTo > 0 {
        playerItem?.seek(to: CMTime(seconds: seekTo, preferredTimescale: 1), completionHandler: nil)
      }
      
      player.replaceCurrentItem(with: playerItem)
    }
  }
  
  init(url: URL, seekTo: Double? = nil) {
    self.seekTo = seekTo
    self.asset = AVURLAsset(url: url)
    super.init()
    setupPeriodicTimeObserver()
    asset.loadValuesAsynchronously(forKeys: keys) { [weak self] in
          if let asset = self?.asset, asset.isPlayable {
            self?.playerItem = AVPlayerItem(asset: asset)
          }
        }
  }
  
  override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    
    if keyPath == #keyPath(AVPlayerItem.status) {
      if player.currentItem?.status == .readyToPlay {
        playerItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
        playerReadyToPlay?()
        player.playImmediately(atRate: 1.0)
      }
      return
    }
    super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
  }
  
  func play() {
    player.playImmediately(atRate: 1.0)
    isPlayerPaused = false
  }
  
  func pause() {
    player.pause()
    isPlayerPaused = true
  }
  func stop() {
    pause()
    if let playerTimeObserver = playerTimeObserver {
      player.removeTimeObserver(playerTimeObserver)
    }
    NotificationCenter.default.removeObserver(self)
  }
  
  func seek(to: CMTime, completionHandler: @escaping (Bool) -> Void) {
      player.seek(to: to, completionHandler: completionHandler)
  }
  
  func seek(to: CMTime) {
      player.seek(to: to)
  }
  
  func addPeriodicTimeObserver(handler: @escaping (CMTime, Bool) -> Void) {
    observerHandler = handler
  }
  
  private func setupPeriodicTimeObserver() {
    playerTimeObserver = player.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 5), queue: .main, using: { [weak self] (time) in
      guard let `self` = self else { return }
      
      guard self.player.currentItem?.status == .readyToPlay,
        let isPlaybackBufferFull = self.player.currentItem?.isPlaybackBufferFull,
        let isPlaybackLikelyToKeepUp = self.player.currentItem?.isPlaybackLikelyToKeepUp else { return }
      
      //      if let track = self.player.currentItem?.tracks.first {
      //        print("Size = \(track.assetTrack?.naturalSize)")
      //      }
      self.observerHandler?(time, (isPlaybackBufferFull || isPlaybackLikelyToKeepUp))
    })
  }
  
  @objc
  private func onVideoEndHandler() {
    onVideoEnd?()
  }
  
}
