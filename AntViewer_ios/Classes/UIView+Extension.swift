//
//  UIView+Extension.swift
//  viewer-module
//
//  Created by Mykola Vaniurskyi on 12/16/18.
//  Copyright © 2018 Mykola Vaniurskyi. All rights reserved.
//

import UIKit
import Lottie
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
    let podBundle = Bundle(for: AntWidget.self)
    guard let url = podBundle.url(forResource: "AntWidget", withExtension: "bundle"),
      let bundle = Bundle(url: url) else { return }
    let animationView = AnimationView(name: "loader", bundle: bundle)
    animationView.loopMode = .loop
    addSubview(animationView)
    animationView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
    animationView.translatesAutoresizingMaskIntoConstraints = false
    let horizontalConstraint = NSLayoutConstraint(item: animationView, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0)
    let verticalConstraint = NSLayoutConstraint(item: animationView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: NSLayoutConstraint.Attribute.centerY, multiplier: 1, constant: 0)
    addConstraints([horizontalConstraint, verticalConstraint])
    animationView.play()
    
  }
  
  func removeActivityIndicator() {
    guard let animationView = subviews.first(where: {$0 is AnimationView}) else {return}
    animationView.removeFromSuperview()
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

public extension UIColor {
  static func color(_ name: String) -> UIColor? {
    let podBundle = Bundle(for: AntWidget.self)
    if let url = podBundle.url(forResource: "AntWidget", withExtension: "bundle") {
      let bundle = Bundle(url: url)
      return UIColor(named: name, in: bundle, compatibleWith: nil)
    }
    return nil
  }
}

