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
  func widgetViewDidMove(_ widgetView: WidgetView, toSuperview withSize: CGSize?)
  func widgetViewWillDisappear(_ widgetView: WidgetView)
  func widgetViewDidPressButton(_ widgetView: WidgetView)
}

public class WidgetView: UIView {
  private lazy var circleAnimator = Animator(view: circleView, type: .pulse)
  private lazy var playAnimator = Animator(view: playIconView, type: .pulseFade)
  private var playerView: AVPlayerView?
  private var preparingStarted = false
  private var shouldShowPlayer = false
  private lazy var logoView: UIImageView = {
    let logoView = UIImageView(image: UIImage.image("Logo"))
    logoView.contentMode = .scaleAspectFill
    logoView.layer.masksToBounds = true
    addSubview(logoView)
    return logoView
  }()
  private lazy var playIconView: UIImageView = {
    let playIcon = UIImageView(image: UIImage.image("PlayIcon"))
    playIcon.contentMode = .scaleToFill
    playIcon.layer.zPosition = 999
    playIcon.layer.opacity = 0
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

  public override func layoutSubviews() {
    super.layoutSubviews()
    updateUI()
    delegate?.widgetViewDidMove(self, toSuperview: superview?.frame.size)
  }

  public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesEnded(touches, with: event)
    self.isUserInteractionEnabled = false
    delegate?.widgetViewDidPressButton(self)
  }

  public override func willMove(toWindow newWindow: UIWindow?) {
    super.willMove(toWindow: newWindow)
    if newWindow == nil {
      delegate?.widgetViewWillDisappear(self)
    } else {
      delegate?.widgetViewWillAppear(self)
    }
  }

  func prepare(for state: WidgetState, completion: ((WidgetState) -> Void)?) {
    if case .live = state {
      if preparingStarted {
        preparingStarted = false
        showPlayerView()
      } else {
        shouldShowPlayer = true
      }
    } else if circleAnimator.isActive {
      circleAnimator.completion = { [weak self] in
        self?.handle(state: state)
        completion?(state)
      }
      circleAnimator.stop()
    } else {
      handle(state: state)
      completion?(state)
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
    var text = LocalizedStrings.new.localized.uppercased()
    var color = UIColor.color("a_poll3Blue")
    if case .live = state {
      text = LocalizedStrings.live.localized
      color = UIColor.color("a_pink")
    }
    let width = bounds.width * 0.385
    var badgeAppearance = BadgeAppearance()
    badgeAppearance.size = CGSize(width: width, height: width * 0.464)
    badgeAppearance.backgroundColor = color ?? .white
    badgeAppearance.font = UIFont.systemFont(ofSize: 8, weight: .bold)
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
    circleAnimator.animate(repeatCount: .infinity)
    let playerView = AVPlayerView()
    playerView.alpha = 0
    playerView.backgroundColor = .black
    playerView.layer.masksToBounds = true
    playerView.playerLayer.videoGravity = .resizeAspectFill
    playerView.player = player
    self.playerView = playerView
    if shouldShowPlayer {
      showPlayerView()
      shouldShowPlayer = false
    } else {
      preparingStarted = true
    }
  }

  private func showPlayerView() {
    circleAnimator.completion = { [weak self] in
      self?.circleAnimator.swapType(to: .spin)
      self?.circleAnimator.animate(repeatCount: .infinity)
      if let playerView = self?.playerView {
        self?.addSubview(playerView)
        playerView.fadeIn()
      }
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
      self?.circleAnimator.animate(repeatCount: .infinity)
    }
    circleAnimator.animate(repeatCount: 2)
  }

  private func showLogo() {
    hidePlayIcon()
    let playerView = self.playerView
    self.playerView = nil
    playerView?.fadeOut(completion: { value in
      playerView?.removeFromSuperview()
    })
  }

  private func showPlayIcon() {
    guard playIconView.isHidden else { return }
    playAnimator.animate(repeatCount: .infinity)
    playIconView.isHidden = false
  }

  private func hidePlayIcon() {
    playIconView.isHidden = true
    playAnimator.stop(immediately: true)
  }

  private func updateUI() {
    let width = bounds.width
    let rect = CGRect(x: 0, y: 0, width: width * 0.69, height: width * 0.69)
    let circleRect = CGRect(x: 0, y: 0, width: width * 0.79, height: width * 0.79)
    playerView?.frame = rect
    logoView.frame = rect
    playIconView.frame = bounds
    circleView.frame = circleRect
    playerView?.layer.cornerRadius = (width * 0.69)/2
    logoView.layer.cornerRadius = (width * 0.69)/2
    let center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
    playerView?.center = center
    logoView.center = center
    playIconView.center = center
    circleView.center = center
  }
}

//MARK: For RN purpose
public extension WidgetView {
  @objc
  var onViewerAppear: ((NSDictionary) -> Void)? {
    set {
      AntWidget.shared.onViewerAppear = newValue
    }
    get {
      return AntWidget.shared.onViewerAppear
    }
  }
  
  @objc
  var onViewerDisappear: ((NSDictionary) -> Void)? {
    set {
      AntWidget.shared.onViewerDisappear = newValue
    }
    get {
      return AntWidget.shared.onViewerDisappear
    }
  }
  
  @objc
  var widgetPosition: String {
    set {
      if let newPosition = WidgetPosition(rawValue: newValue) {
        AntWidget.shared.widgetPosition = newPosition
      }
    }
    get {
      AntWidget.shared.widgetPosition.rawValue
    }
  }
  
  @objc
  var widgetMargins: NSDictionary {
    set {
      guard
        let vertical = newValue["vertical"] as? CGFloat,
        let horizontal = newValue["horizontal"] as? CGFloat else {
        return
      }
      let margins = WidgetMargins(vertical: vertical, horizontal: horizontal)
      AntWidget.shared.widgetMargins = margins
    }
    get {
      let margins = AntWidget.shared.widgetMargins
      return ["vertical": margins.vertical,
              "horizontal": margins.horizontal]
    }
  }
}
