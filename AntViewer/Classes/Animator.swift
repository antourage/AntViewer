//
//  Animator.swift
//  abseil
//
//  Created by Mykola Vaniurskyi on 26.03.2020.
//

import UIKit

class Animator {
  enum AnimationType: String {
    case spin, fastSpin, pulse, pulseFade
    var duration: CFTimeInterval {
      switch self {
      case .spin:
        return 8
      case .fastSpin:
        return 0.7
      case .pulse:
        return 1.52
      case .pulseFade:
        return 15
      }
    }
  }
  private let view: UIView
  private var type: AnimationType
  private var repeatCount: Float = 1
  private var shouldStop = false

  public var isActive: Bool {
    view.layer.animation(forKey: type.rawValue) != nil
  }
  public var completion: (() -> Void)?

  public init(view: UIView, type: AnimationType) {
    self.view = view
    self.type = type
  }

  public func animate(
    repeatCount: Float? = nil) {
    guard !isActive else { return }
    if let repeatCount = repeatCount {
      self.repeatCount = repeatCount
    }
    shouldStop = self.repeatCount != .infinity
    startAnimation()
  }

  public func swapType(to type: AnimationType) {
    stop(immediately: true)
    self.type = type
  }

  public func stop(
    immediately: Bool = false) {
    shouldStop = true
    if immediately {
      view.layer.removeAnimation(forKey: type.rawValue)
    }
  }

  private func startAnimation() {
    CATransaction.begin()
    let animationType = type
    let animation = createAnimation(with: animationType)
    animation.isRemovedOnCompletion = false
    animation.duration = animationType.duration
    let isInfinite = repeatCount == .infinity
    animation.repeatCount = isInfinite ? 1 : repeatCount
    CATransaction.setCompletionBlock { [weak self] in
      self?.view.layer.removeAnimation(forKey: animationType.rawValue)
      if self?.shouldStop == true {
        self?.completion?()
      } else {
        self?.startAnimation()
      }
    }
    view.layer.add(animation, forKey: animationType.rawValue)
    CATransaction.commit()
  }

  private func createAnimation(with type: AnimationType) -> CAAnimation {
    switch type {
    case .pulse:
      let animation = CAKeyframeAnimation(keyPath: "transform.scale")
      animation.values = [1, 1.25, 1, 1.1, 1, 1]
      animation.keyTimes = [0, 0.16, 0.29, 0.4, 0.5, 1]
      return animation
    case .spin, .fastSpin:
      let animation = CABasicAnimation(keyPath: "transform.rotation")
      animation.fromValue = 0.0
      animation.toValue = CGFloat(.pi * 2.0)
      return animation
    case .pulseFade:
      let opacityAnimation = CAKeyframeAnimation(keyPath: "opacity")
      opacityAnimation.values = [0, 1, 1, 0, 0]
      opacityAnimation.keyTimes = [0.0, 0.0132, 0.2532, 0.2664, 1]
      let scaleAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
      scaleAnimation.values =   [2.2, 1, 1, 1.2, 1, 1.15, 1, 1, 2.2, 2.2]
      scaleAnimation.keyTimes = [0.0, 0.0132, 0.1092, 0.1224, 0.1356, 0.1464, 0.1572, 0.2532, 0.2664, 1]
      let group = CAAnimationGroup()
      group.animations = [opacityAnimation, scaleAnimation]
      return group
    }
  }
}
