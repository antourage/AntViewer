//
//  UINavigationBar+Extension.swift
//  viewer-module
//
//  Created by Mykola Vaniurskyi on 12/4/18.
//  Copyright © 2018 Mykola Vaniurskyi. All rights reserved.
//

import UIKit

extension UINavigationBar {
  
  func updateBackgroundColor() {
    var barView = subviews.first
    if barView == nil || barView != nil && type(of: barView!) != UIView.self {
      
      barView = UIView(frame: CGRect.zero)
      let navBarSize = frame.size
      let statusBarSize = UIApplication.shared.statusBarFrame.size
      barView?.frame.size = CGSize(width: navBarSize.width, height: navBarSize.height + statusBarSize.height)
      subviews.first?.insertSubview(barView!, at: 0)
    }
    barView?.backgroundColor = barTintColor
    isTranslucent = false
    setBackgroundImage(UIImage(), for: .default)
    shadowImage = UIImage()
    layoutIfNeeded()
  }
  
}
