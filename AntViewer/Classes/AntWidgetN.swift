//
//  AntWidgetN.swift
//  abseil
//
//  Created by Mykola Vaniurskyi on 25.03.2020.
//

import AVKit

enum WidgetState {
  case resting
  case vod
  case live
  case loading(player: AVPlayer)
}

public class AntWidgetN {

  private var currentState = WidgetState.resting {
    didSet {
      widgetView.prepare(for: currentState)
    }
  }
  private var player: AVPlayer?
  private lazy var widgetView: WidgetView = {
    let screenSize = UIScreen.main.bounds.size
    let width: CGFloat = 120
    let x = (screenSize.width - width)/2
    let y = screenSize.height - width - 100
    let rect = CGRect(x: x, y: y, width: width, height: width)
    let view = WidgetView(frame: rect)
    view.backgroundColor = .clear
    view.delegate = self
    return view
  }()

  public var view: UIView { widgetView }

  public init() {
    showLive()
  }

  private func showLive() {
    guard let url = URL(string: "https://coubsecure-s.akamaihd.net/get/b29/p/coub/simple/cw_video_for_sharing/ef45512c73a/617f970d09107fecacd6f/1569968282_looped_1569968273.mp4?dl=1") else { return }
    let player = AVPlayer(url: url)
    self.player = player
    player.isMuted = true
    currentState = .loading(player: player)
    player.play()
    DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
      self?.currentState = .live
    }
  }
}

extension AntWidgetN: WidgetViewDelegate {

}
