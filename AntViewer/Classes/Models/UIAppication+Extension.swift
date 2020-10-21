//
//  UIAppication+Extension.swift
//  Antourage
//
//  Created by Mykola Vaniurskyi on 21.10.2020.
//

import UIKit

extension UIApplication {
  
  class func getTopViewController(base: UIViewController? = nil) -> UIViewController? {
    var baseController = base
    if base == nil {
      if #available(iOS 13.0, *) {
        baseController = UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController
      } else {
        baseController = UIApplication.shared.keyWindow?.rootViewController
      }
    }
    
    if let nav = baseController as? UINavigationController {
      return getTopViewController(base: nav.visibleViewController)
      
    } else if let tab = baseController as? UITabBarController, let selected = tab.selectedViewController {
      return getTopViewController(base: selected)
      
    } else if let presented = baseController?.presentedViewController {
      return getTopViewController(base: presented)
    }
    return baseController
  }
}
