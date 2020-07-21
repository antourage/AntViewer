//
//  Player.swift
//  abseil
//
//  Created by Mykola Vaniurskyi on 24.11.2019.
//

import Foundation
import AVKit

struct NPlayerError: Error {
  enum ErrorKind {
    case noInternerConnection
    case invalidLink
    case faildStatus
  }
  
  let kind: ErrorKind
  let description: String
}

class Player: NSObject {
  
  private let keys: [String] = ["playable", "duration", "tracks"]
  
  private var playerTimeObserver: Any?
  private var isPlayerReadyToPlay = false
  private var seekTo: Double?
  private var observerHandler: ((CMTime, Bool) -> Void)?
  private var perfMeasurements: PerfMeasurements?
  private var errorsCount = 0
  
  var isPlayerPaused = false
  var isError = false
  var playerReadyToPlay: (() -> Void)?
  var onErrorApear: ((NPlayerError) -> Void)?
  
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
    newPlayer.actionAtItemEnd = .pause
    return newPlayer
  }()
  
  private var asset: AVURLAsset
  
  private var playerItem: AVPlayerItem? {
    didSet {
      playerItem?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.new], context: nil)
      
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
      perfMeasurements = PerfMeasurements(playerItem: playerItem!)
      let notificationCenter = NotificationCenter.default
      notificationCenter.addObserver(self,
                                     selector: #selector(handleTimebaseRateChanged(_:)),
                                     name: Notification.Name(rawValue: kCMTimebaseNotification_EffectiveRateChanged as String), object: playerItem?.timebase)
      notificationCenter.addObserver(self,
                                     selector: #selector(handlePlaybackStalled(_:)), name: .AVPlayerItemPlaybackStalled, object: playerItem)
      notificationCenter.addObserver(self, selector: #selector(newErrorLogEntry(_:)), name: .AVPlayerItemNewErrorLogEntry, object: player.currentItem)
      notificationCenter.addObserver(self, selector: #selector(failedToPlayToEndTime(_:)), name: .AVPlayerItemFailedToPlayToEndTime, object: player.currentItem)
    }
  }
  
  init(url: URL, seekTo: Double? = nil) {
    self.seekTo = seekTo
    self.asset = AVURLAsset(url: url)
    print(url)
    super.init()
    setupPeriodicTimeObserver()
    asset.loadValuesAsynchronously(forKeys: keys) { [weak self] in
      if let asset = self?.asset, asset.isPlayable {
        self?.playerItem = AVPlayerItem(asset: asset)
      } else {
        let error = NPlayerError(kind: .invalidLink, description: "Can't load content")
        self?.isError = true
        DispatchQueue.main.async { [weak self] in
          self?.onErrorApear?(error)
        }
      }
    }
  }
  
  override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    
    if keyPath == #keyPath(AVPlayerItem.status) {
      
      let newStatus: AVPlayerItem.Status
      if let newStatusAsNumber = change?[NSKeyValueChangeKey.newKey] as? NSNumber {
        newStatus = AVPlayerItem.Status(rawValue: newStatusAsNumber.intValue)!
      } else {
        newStatus = .unknown
      }
      if newStatus == .readyToPlay {
        if isPlayerReadyToPlay == false {
          isPlayerReadyToPlay = true
          playerReadyToPlay?()
          player.playImmediately(atRate: 1.0)
        } else if isPlayerPaused == false {
          player.playImmediately(atRate: 1.0)
        }
      } else if newStatus == .failed {
        //player.replaceCurrentItem(with: playerItem)
        print("AVPLAYER ITEM Error: \(String(describing: self.player.currentItem?.error?.localizedDescription)), error: \(String(describing: self.player.currentItem?.error))")
        if let error = self.player.currentItem?.error {
          let playerError = NPlayerError(kind: .faildStatus, description: error.noInternetConnection ? "No internet connection available" : error.localizedDescription)
           pause(withError: playerError)
        }
 
      }
      
      return
    }
    super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
  }
  
  func play() {
    player.playImmediately(atRate: 1.0)
    isPlayerPaused = false
  }
  
  func pause(withError: NPlayerError? = nil) {
    player.pause()
    isPlayerPaused = true
    if let error = withError {
      isError = true
      onErrorApear?(error)
    }
  }
  
  func reconnect() {
    isError = false
    play()
  }
  
  func stop() {
    pause()
    perfMeasurements?.playbackEnded()
    if let playerTimeObserver = playerTimeObserver {
      player.removeTimeObserver(playerTimeObserver)
    }
    playerItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
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
      self.errorsCount = 0
      self.observerHandler?(time, (isPlaybackBufferFull || isPlaybackLikelyToKeepUp))
    })
  }
  
  @objc
  private func onVideoEndHandler() {
    isPlayerPaused = true
    onVideoEnd?()
  }
  
  @objc
  func handleTimebaseRateChanged(_ notification: Notification) {
    if CMTimebaseGetTypeID() == CFGetTypeID(notification.object as CFTypeRef) {
      let timebase = notification.object as! CMTimebase
      let rate: Double = CMTimebaseGetRate(timebase)
      perfMeasurements?.rateChanged(rate: rate)
    }
  }
  
  @objc
  func handlePlaybackStalled(_ notification: Notification) {
    perfMeasurements?.playbackStalled()
  }
  
  // Getting error from Notification payload
  @objc
  func newErrorLogEntry(_ notification: Notification) {
    guard !isError else {
      return
    }
    guard let object = notification.object, let playerItem = object as? AVPlayerItem else {
      return
    }
    guard let errorLog: AVPlayerItemErrorLog = playerItem.errorLog() else {
      return
    }
    print("Error newErrorLogEntry: \(errorLog.events.map({"\($0.errorStatusCode): \($0.errorComment ?? "")"}))")
    if errorLog.events.last?.errorStatusCode == -1009 {
      let playerError = NPlayerError(kind: .noInternerConnection, description: "No internet connection available")
      pause(withError: playerError)
    }
    if errorLog.events.last?.errorStatusCode == -12888 {
      errorsCount += 1
      if errorsCount > 2 {
        let playerError = NPlayerError(kind: .faildStatus, description: "Unexpected stream stop")
        pause(withError: playerError)
      }
    }
    
  }
  
  @objc
  func failedToPlayToEndTime(_ notification: Notification) {
    if let error = notification.userInfo!["AVPlayerItemFailedToPlayToEndTimeErrorKey"] as? Error {
      print("Error failedToPlayToEndTime: \(error.localizedDescription), error: \(error)")
    }
  }

}
