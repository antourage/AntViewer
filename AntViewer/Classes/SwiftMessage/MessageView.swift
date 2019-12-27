//
//  MessageView.swift
//  SwiftMessages
//
//  Created by Maryan Luchko on 12/12/19.
//  Copyright © 2019 Leobit LLC. All rights reserved.
//

import UIKit

 class MessageView: UIView {

  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var bodyLabel: UILabel!
  @IBOutlet weak var backgroundView: UIView!
  
  var presentingDuration: Double = 2
  var shouldHide: () -> () = { }
  override init(frame: CGRect) {
    super.init(frame: frame)
    commmonInit()
  }

  init(withBanerHeight height: CGFloat, width: CGFloat) {
    let frame = CGRect(x: 0, y: -height, width: width, height: height)
    super.init(frame: frame)
    commmonInit()
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    commmonInit()
    fatalError("init(coder:) has not been implemented")
  }

  private func commmonInit() {
    Bundle(for: type(of: self)).loadNibNamed("MessageView", owner: self, options: nil)
    backgroundView.fixInView(self)
    NSLayoutConstraint(item: backgroundView!, attribute: .height, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: frame.height).isActive = true
  }
  
  func applyTheme(_ theme: Theme) {
    switch theme {
    case .error:
      backgroundView.backgroundColor = UIColor(red: 249.0/255.0, green: 66.0/255.0, blue: 47.0/255.0, alpha: 1.0)
    case .success:
      backgroundView.backgroundColor = UIColor(red: 4/255, green: 168/255, blue: 84/255, alpha: 1)
    case .warning:
      backgroundView.backgroundColor = UIColor(red: 238.0/255.0, green: 189.0/255.0, blue: 34.0/255.0, alpha: 1.0)
    }
  }
  
  @IBAction func handleCloseSwipe(_ sender: UISwipeGestureRecognizer) {
    hideAnimation() 
  }
  
   func showAnimation() {
    UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
      self.frame.origin = .zero
    }, completion: nil)
  }
  
  func hideAnimation(){
    UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
      self.frame.origin = CGPoint(x: 0, y: -self.bounds.height)
    }) { [weak self] (success) in
        guard let `self` = self else { return }
        self.removeFromSuperview()
      self.shouldHide()
    }
  }
}

enum Theme {
  case error, warning, success
}

