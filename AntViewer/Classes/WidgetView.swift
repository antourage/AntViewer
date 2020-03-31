//
//  WidgetView.swift
//  abseil
//
//  Created by Mykola Vaniurskyi on 25.03.2020.
//

import AVKit
import UIKit

protocol WidgetViewDelegate: class {
  func widgetViewWillAppear(_ widgetView: WidgetView)
  func widgetViewWillDisappear(_ widgetView: WidgetView)
  func widgetViewDidPressButton(_ widgetView: WidgetView)
}

class WidgetView: UIView {
  private lazy var circleAnimator = Animator(view: circleView, type: .pulse)
  private var playerView: AVPlayerView?
  private lazy var logoView: UIImageView = {
    let logoView = UIImageView(image: UIImage.image("Logo"))
    logoView.contentMode = .scaleAspectFill
    addSubview(logoView)
    return logoView
  }()
  private lazy var playIconView: UIImageView = {
    let playIcon = UIImageView()
    let images = Array(0...99).compactMap {
      UIImage.image("PlayIcon_\(String(format: "%03d", $0))")
    }
    playIcon.animationImages = images
    playIcon.contentMode = .scaleAspectFill
    playIcon.animationDuration = 4
    addSubview(playIcon)
    return playIcon
  }()
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
    delegate?.widgetViewDidPressButton(self)
  }

  override func willMove(toWindow newWindow: UIWindow?) {
    super.willMove(toWindow: newWindow)
    if newWindow == nil {
      delegate?.widgetViewWillDisappear(self)
    } else {
      delegate?.widgetViewWillAppear(self)
    }
  }

  func prepare(for state: WidgetState, completion: @escaping () -> Void) {
    if case .live = state {
      showPlayerView()
      completion()
    } else if circleAnimator.isActive {
      circleAnimator.completion = { [weak self] in
        self?.handle(state: state)
        completion()
      }
      circleAnimator.stop()
    } else {
      handle(state: state)
      completion()
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
      removeBadge()
      break
    default:
      break
    }
  }

  private func showBadge(for state: WidgetState) {
    var text = "NEW"
    var color = UIColor.color("a_poll3Blue")
    if case .live = state {
      text = "LIVE"
      color = UIColor.color("a_pink")
    }
    var badgeAppearance = BadgeAppearance()
    badgeAppearance.backgroundColor = color ?? .white
    badgeAppearance.font = UIFont.systemFont(ofSize: 7, weight: .bold)
    let circleWidth = bounds.width * 0.79
    badgeAppearance.distanceFromCenterX = circleWidth * 0.44
    badgeAppearance.distanceFromCenterY = -circleWidth * 0.34
    badgeAppearance.allowShadow = true
    self.badge(text: text, appearance: badgeAppearance)
  }

  private func removeBadge() {
    self.badge(text: nil)
  }

  private func prepareLive(with player: AVPlayer) {
    showBadge(for: .live)
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
      if let playerView = self?.playerView {
        self?.addSubview(playerView)
      }
      self?.logoView.isHidden = true
      self?.showPlayIcon()
      self?.updateUI()
    }
    circleAnimator.stop()
  }

  private func prepareVOD() {
    showBadge(for: .vod)
    circleAnimator.swapType(to: .pulse)
    circleAnimator.completion = { [weak self] in
      self?.circleAnimator.swapType(to: .spin)
      self?.circleAnimator.animate(duration: 8, repeatCount: .infinity)
    }
    circleAnimator.animate(duration: 1.52, repeatCount: 2)
  }

  private func showLogo() {
    hidePlayIcon()
    playerView?.removeFromSuperview()
    playerView = nil
    logoView.isHidden = false
  }

  private func showPlayIcon() {
    guard playIconView.isHidden else { return }
    playIconView.isHidden = false
    playIconView.startAnimating()
  }

  private func hidePlayIcon() {
    playIconView.stopAnimating()
    playIconView.isHidden = true
  }

  private func updateUI() {
    circleView.frame = bounds
    let width = bounds.width
    let rect = CGRect(x: 0, y: 0, width: width * 0.69, height: width * 0.69)
    let viewToUpdate = playerView ?? logoView
    viewToUpdate.frame = rect
    playIconView.frame = rect
    let circleRect = CGRect(x: 0, y: 0, width: width * 0.79, height: width * 0.79)
    circleView.frame = circleRect
    viewToUpdate.layer.cornerRadius = (width * 0.69)/2
    viewToUpdate.layer.masksToBounds = true
    let center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
    viewToUpdate.center = center
    playIconView.center = center
    circleView.center = center
  }
}
