// The MIT License (MIT)
//
// ModernAVPlayer
// Copyright (c) 2018 Raphael Ankierman <raphael.ankierman@radiofrance.com>
//
// PlaybackObservingService.swift
// Created by Jean-Charles Dessaint on 20/04/2018.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import AVFoundation

//sourcery: AutoMockable
protocol PlaybackObservingService {
    var onPlaybackStalled: ((Bool) -> Void)? { get set }
    var onPlayToEndTime: (() -> Void)? { get set }
    var onFailedToPlayToEndTime: (() -> Void)? { get set }
}

final class ModernAVPlayerPlaybackObservingService: PlaybackObservingService {
    
    // MARK: - Input
    
    private let player: AVPlayer
    
    // MARK: - Outputs
  
    var withError = false
    
    var onPlaybackStalled: ((_ withError: Bool) -> Void)?
    var onPlayToEndTime: (() -> Void)?
    var onFailedToPlayToEndTime: (() -> Void)?
    
    // MARK: - Init
    
    init(player: AVPlayer) {
        ModernAVPlayerLogger.instance.log(message: "Init", domain: .lifecycleService)
        self.player = player
        NotificationCenter.default.addObserver(self, selector: #selector(ModernAVPlayerPlaybackObservingService.itemPlaybackStalled),
                                               name: .AVPlayerItemPlaybackStalled, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ModernAVPlayerPlaybackObservingService.itemPlayToEndTime),
                                               name: .AVPlayerItemDidPlayToEndTime, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ModernAVPlayerPlaybackObservingService.itemFailedToPlayToEndTime),
                                               name: .AVPlayerItemFailedToPlayToEndTime, object: nil)
      NotificationCenter.default.addObserver(self, selector: #selector(ModernAVPlayerPlaybackObservingService.newErrorLogEntry(_:)), name: .AVPlayerItemNewErrorLogEntry, object: nil)
    }
    
    deinit {
        ModernAVPlayerLogger.instance.log(message: "Deinit", domain: .lifecycleService)
        NotificationCenter.default.removeObserver(self,
                                                  name: .AVPlayerItemPlaybackStalled,
                                                  object: nil)
        NotificationCenter.default.removeObserver(self,
                                                  name: .AVPlayerItemDidPlayToEndTime,
                                                  object: nil)
        NotificationCenter.default.removeObserver(self,
                                                  name: .AVPlayerItemFailedToPlayToEndTime,
                                                  object: nil)
      NotificationCenter.default.removeObserver(self,
                                                name: .AVPlayerItemNewErrorLogEntry,
                                                object: nil)
    }
    
    private func hasReallyReachedEndTime(player: AVPlayer) -> Bool {
        guard
            let duration = player.currentItem?.duration.seconds
            else { return false }
        
        /// item current time when receive end time notification
        /// is not so accurate according to duration
        /// added +1 make sure about the computation
        if duration.isNaN {
          return true
        }
        let currentTime = player.currentTime().seconds + 1
        return currentTime >= duration
    }
    
    @objc
    private func itemPlaybackStalled() {
        ModernAVPlayerLogger.instance.log(message: "Item playback stalled notification", domain: .service)
        onPlaybackStalled?(withError)
    }
    
    ///
    ///  AVPlayerItemDidPlayToEndTime notification can be triggered when buffer is empty and network is out.
    ///  We manually check if item has really reached his end time.
    ///
    @objc
    private func itemPlayToEndTime() {
        guard hasReallyReachedEndTime(player: player) else {
          itemFailedToPlayToEndTime()
          return
        }
        ModernAVPlayerLogger.instance.log(message: "Item play to end time notification", domain: .service)
        onPlayToEndTime?()
    }
    
    @objc
    private func itemFailedToPlayToEndTime() {
        ModernAVPlayerLogger.instance.log(message: "Item failed to play endtime notification", domain: .service)
        onFailedToPlayToEndTime?()
    }
  
  // Getting error from Notification payload
  @objc
  func newErrorLogEntry(_ notification: Notification) {
    guard let object = notification.object, let playerItem = object as? AVPlayerItem else {
      return
    }
    guard let errorLog: AVPlayerItemErrorLog = playerItem.errorLog() else {
      return
    }
    print("Player state: \(Date().debugDescription) Error newErrorLogEntry: \(errorLog.events.map({"\($0.errorStatusCode): \($0.errorComment ?? "")"}))")
    let count = errorLog.events.filter({ [-12938, -12888].contains($0.errorStatusCode) }).count
    print("Player state: \(Date().debugDescription) Errors count: \(count)")
    
    if count > 1 {
      withError = true
    }
    
  }
  
}
