//
//  UIColor+Extension.swift
//  AntViewer
//
//  Created by Maryan Luchko on 21.04.2020.
//

import Foundation

public extension UIColor {
  static func color(_ name: String) -> UIColor? {
    let podBundle = Bundle(for: AntWidget.self)
    if let url = podBundle.url(forResource: "AntWidget", withExtension: "bundle") {
      let bundle = Bundle(url: url)
      return UIColor(named: name, in: bundle, compatibleWith: nil)
    }
    return nil
  }

  static var darkTitle: UIColor {
    return UIColor.color("darkTitle") ?? .darkGray
  }
  
  static var pink: UIColor {
    return UIColor.color("a_pink") ?? .pink
  }

  static var cellGray: UIColor {
    return UIColor.color("a_cell_subtitle") ?? .gray
  }

  static var designerGreen: UIColor {
    return UIColor.color("a_green") ?? .green
  }
  
  static var designerBlue: UIColor {
    return UIColor.color("a_button_blue") ?? .blue
  }

  static var gradientDark: UIColor {
    return UIColor.color("gradientDark") ?? .black
  }
  static var bottomMessageGray: UIColor {
    return UIColor.color("a_bottomMessageGray") ?? .gray
  }
  static var curtainYellow: UIColor {
    return UIColor.color("a_curtainYellow") ?? .yellow
  }
}
