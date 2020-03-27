//
//  WidgetView.swift
//  abseil
//
//  Created by Mykola Vaniurskyi on 25.03.2020.
//

import AVKit
import UIKit

protocol WidgetViewDelegate: class {

}

class WidgetView: UIView {

  private lazy var circleAnimator = Animator(view: circleView, type: .pulse)
  private var playerView: AVPlayerView?
  private var logoView: UIImageView?
  private var playIconView: UIImageView?
  private lazy var circleView: UIImageView = {
    let imageView = UIImageView(image: UIImage.image("Circle"))
    imageView.contentMode = .scaleToFill
    addSubview(imageView)
    return imageView
  }()

  weak var delegate: WidgetViewDelegate?

  override func layoutSubviews() {
    super.layoutSubviews()
    updateUI()
  }

  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesEnded(touches, with: event)
    self.isUserInteractionEnabled = false
    //delegate
  }

  override func willMove(toWindow newWindow: UIWindow?) {
    super.willMove(toWindow: newWindow)
    //delegate
    if newWindow == nil {
      // UIView disappear
    } else {
      // UIView appear
    }
  }

  func prepare(for state: WidgetState) {
    if case .live = state {
      return showPlayerView()
    }
    if circleAnimator.isActive {
      circleAnimator.completion = { [weak self] in
        self?.handle(state: state)
      }
      circleAnimator.stop()
    } else {
      handle(state: state)
    }
  }

  private func handle(state: WidgetState) {
    showLogo()
    switch state {
    case .loading(player: let player):
      prepareLive(with: player)
    case .vod:
      prepareVOD()
    case .resting:
      //REMOVE BUDGE
      break
    default:
      break
    }
  }

  private func prepareLive(with player: AVPlayer) {

    //TODO: REPLACE LIVE BUDGE FADE
    circleAnimator.swapType(to: .pulse)
    circleAnimator.animate(duration: 1.52, repeatCount: .infinity)
    let playerView = AVPlayerView()
    playerView.playerLayer.videoGravity = .resize
    playerView.player = player
    self.playerView = playerView
  }

  private func showPlayerView() {
    circleAnimator.completion = { [weak self] in
      self?.circleAnimator.swapType(to: .spin)
      self?.circleAnimator.animate(duration: 8, repeatCount: .infinity)
      self?.logoView?.removeFromSuperview()
      self?.logoView = nil
      if let playerView = self?.playerView {
        self?.addSubview(playerView)
      }
      self?.showPlayIcon()
      self?.updateUI()
    }
    circleAnimator.stop()
  }

  private func prepareVOD() {
    //TODO: REPLACE NEW BUDGE FADE
    circleAnimator.swapType(to: .pulse)
    circleAnimator.completion = { [weak self] in
      self?.circleAnimator.swapType(to: .spin)
      self?.circleAnimator.animate(duration: 8, repeatCount: .infinity)
    }
    circleAnimator.animate(duration: 1.52, repeatCount: 1)
  }

  private func showLogo() {
    removePlayIcon()
    playerView?.removeFromSuperview()
    playerView = nil
    let logoView = UIImageView(image: UIImage.image("Logo"))
    logoView.contentMode = .scaleAspectFill
    self.logoView = logoView
    addSubview(logoView)
    updateUI()
  }

  private func showPlayIcon() {
    guard playIconView == nil else { return }
    let playIcon = UIImageView()
    let images = Array(0...99).compactMap {
      UIImage.image("PlayIcon_\(String(format: "%03d", $0))")
    }
    playIcon.animationImages = images
    playIcon.contentMode = .scaleAspectFill
    playIcon.animationDuration = 4
    self.playIconView = playIcon
    addSubview(playIcon)
    playIcon.startAnimating()
  }

  private func removePlayIcon() {
    playIconView?.removeFromSuperview()
    playIconView = nil
  }

  private func updateUI() {
    circleView.frame = bounds
    let width = bounds.width
    let rect = CGRect(x: 0, y: 0, width: width * 0.69, height: width * 0.69)
    let viewToUpdate = playerView ?? logoView
    viewToUpdate?.frame = rect
    playIconView?.frame = rect
    let circleRect = CGRect(x: 0, y: 0, width: width * 0.79, height: width * 0.79)
    circleView.frame = circleRect
    viewToUpdate?.layer.cornerRadius = (width * 0.69)/2
    viewToUpdate?.layer.masksToBounds = true
    let center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
    viewToUpdate?.center = center
    playIconView?.center = center
    circleView.center = center
  }
}
