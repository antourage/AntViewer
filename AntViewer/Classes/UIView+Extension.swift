//
//  UIView+Extension.swift
//  viewer-module
//
//  Created by Mykola Vaniurskyi on 12/16/18.
//  Copyright © 2018 Mykola Vaniurskyi. All rights reserved.
//

import UIKit
import AVFoundation

public extension UIView {
  
  func findViewController() -> UIViewController? {
    if let nextResponder = self.next as? UIViewController {
      return nextResponder
    } else if let nextResponder = self.next as? UIView {
      return nextResponder.findViewController()
    } else {
      return nil
    }
  }
  
  func showActivityIndicator() {
    removeActivityIndicator()
    let images = Array(0...29).compactMap {
      UIImage.image("\($0)")
    }
    let animationView = UIImageView()
    animationView.animationImages = images
    animationView.tag = 1023
    addSubview(animationView)
    animationView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
    animationView.translatesAutoresizingMaskIntoConstraints = false
    let horizontalConstraint = NSLayoutConstraint(item: animationView, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0)
    let verticalConstraint = NSLayoutConstraint(item: animationView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: NSLayoutConstraint.Attribute.centerY, multiplier: 1, constant: 0)
    addConstraints([horizontalConstraint, verticalConstraint])
    animationView.startAnimating()
    
  }
  
  func removeActivityIndicator() {
    guard let animationView = subviews.first(where: {$0.tag == 1023}) as? UIImageView else {return}
    animationView.stopAnimating()
    animationView.removeFromSuperview()
  }
  
  var isActivityIndicatorLoaded: Bool {
    subviews.first(where: {$0.tag == 1023}) != nil
  }
  
  func fixInView(_ container: UIView!) -> Void{
    self.translatesAutoresizingMaskIntoConstraints = false;
    self.frame = container.frame;
    container.addSubview(self);
    NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: container, attribute: .leading, multiplier: 1.0, constant: 0).isActive = true
    NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: container, attribute: .trailing, multiplier: 1.0, constant: 0).isActive = true
    NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: container, attribute: .top, multiplier: 1.0, constant: 0).isActive = true
    NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: container, attribute: .bottom, multiplier: 1.0, constant: 0).isActive = true
  }

  func fadeIn(duration: TimeInterval = 0.3,
              delay: TimeInterval = 0.0,
              completion: @escaping ((Bool) -> Void) = {(finished: Bool) -> Void in }) {
    UIView.animate(withDuration: duration,
                   delay: delay,
                   options: .curveEaseIn,
                   animations: {
      self.alpha = 1.0
    }, completion: completion)
  }

  func fadeOut(duration: TimeInterval = 0.3,
               delay: TimeInterval = 0.0,
               completion: @escaping (Bool) -> Void = {(finished: Bool) -> Void in }) {
    UIView.animate(withDuration: duration,
                   delay: delay,
                   options: .curveEaseIn,
                   animations: {
      self.alpha = 0.0
    }, completion: completion)
  }

  func addBadge(title: String, corner: UIRectCorner = .topRight, belowView: UIView? = nil) {
    hideBadge()
    let holderView = UIView(frame: frame)
    holderView.translatesAutoresizingMaskIntoConstraints = false
    let randomTag = Int(arc4random_uniform(1024)) + 3000
    holderView.tag = randomTag
    tag = randomTag
    holderView.isUserInteractionEnabled = false
    holderView.backgroundColor = .clear
    if let belowView = belowView {
      superview?.superview?.insertSubview(holderView, belowSubview: belowView)
    } else {
      superview?.superview?.addSubview(holderView)
    }
    holderView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
    holderView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    holderView.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
    holderView.widthAnchor.constraint(equalTo: widthAnchor).isActive = true

    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.text = title
    label.font = UIFont.systemFont(ofSize: 9, weight: .bold)
    label.textAlignment = .center
    let badgeSize = label.intrinsicContentSize
    let origin = CGPoint(x: bounds.width - badgeSize.width / 2, y: badgeSize.width / 5)
    label.frame = CGRect(origin: origin, size: badgeSize)
    label.textColor = .white
    label.backgroundColor = .designerBlue
    label.heightAnchor.constraint(equalToConstant: 14).isActive = true
    let widhtConst = badgeSize.width+4 < 14 ? 14 : badgeSize.width+4
    label.widthAnchor.constraint(equalToConstant: widhtConst).isActive = true
    label.layer.masksToBounds = true
    label.layer.cornerRadius = 10
    let delta = sqrt(pow(Double(bounds.width / 2), 2) / 2)
    label.layer.cornerRadius = badgeSize.height / 2
    holderView.addSubview(label)
    switch corner {
    case .topRight:
      label.centerXAnchor.constraint(equalTo: holderView.centerXAnchor, constant: CGFloat(delta)).isActive = true
      label.centerYAnchor.constraint(equalTo: holderView.centerYAnchor, constant: -CGFloat(delta)).isActive = true
    default:
      break
    }
  }
  
  func hideBadge() {
    superview?.superview?.subviews.first(where: { $0 != self && $0.tag == tag && tag != 0 })?.removeFromSuperview()
    tag = 0
  }
}

public extension UIButton {
  @IBInspectable
  var imageFromBundle: String {
    set {
      setImage(UIImage.image(newValue), for: [])
    }
    get {
      return ""
    }
  }
}

public extension UIImageView {
  @IBInspectable
  var imageFromBundle: String {
    set {
      image = UIImage.image(newValue)
    }
    get {
      return ""
    }
  }
}

public extension UIImage {
  static func image(_ name: String) -> UIImage? {
    let podBundle = Bundle(for: AntWidget.self)
    if let url = podBundle.url(forResource: "AntWidget", withExtension: "bundle") {
      let bundle = Bundle(url: url)
      return UIImage(named: name, in: bundle, compatibleWith: nil)
    }
    return nil
  }
}

