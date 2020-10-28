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
    guard
      let url = podBundle.url(forResource: "AntWidget", withExtension: "bundle"),
      let bundle = Bundle(url: url) else {
      return self
    }
    if let languageCode = AntWidget.shared.widgetLocale?.rawValue ?? Locale.current.languageCode {
      return NSLocalizedString(self, tableName: "AntViewerLocalization_\(languageCode)", bundle: bundle, value: "", comment: "")
    }
    return self
  }
}

class LocalizedLabel: UILabel {
  override func awakeFromNib() {
    super.awakeFromNib()
    text = text?.localized()
  }
}

class LocalizedButton: UIButton {
  override func awakeFromNib() {
    super.awakeFromNib()
    setTitle(currentTitle?.localized(), for: .normal)
  }
}
