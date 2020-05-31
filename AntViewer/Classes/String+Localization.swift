//
//  String+Localization.swift
//  AntViewer
//
//  Created by Maryan Luchko on 30.05.2020.
//

import Foundation


extension String {
  func localized() -> String {
    let podBundle = Bundle(for: AntWidget.self)
    if let url = podBundle.url(forResource: "AntWidget", withExtension: "bundle"), let bundle = Bundle(url: url) {
      return NSLocalizedString(self, tableName: "AntViewerLocalizable", bundle: bundle, value: "", comment: "")
    }
    return self
  }
}

