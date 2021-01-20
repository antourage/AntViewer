//
//  Antourage.swift
//  Antourage
//
//  Created by Mykola Vaniurskyi on 04.12.2020.
//

import UIKit
import ViewerExtension


@objc
public class Antourage: NSObject {
  
  public static var AntourageSenderId = "1090288296965"
  
  @objc
  public static let shared = Antourage()
  private override init() {
    AppAuth.shared.auth()
    AntWidget.shared.firebaseCreator = FireCreator()
    super.init()
  }
  
  public var widgetLocale: WidgetLocale? {
    get {
      AntWidget.shared.widgetLocale
    }
    set {
      AntWidget.shared.widgetLocale = newValue
    }
  }
  
  public var widgetPosition: WidgetPosition {
    get {
      AntWidget.shared.widgetPosition
    }
    set {
      AntWidget.shared.widgetPosition = newValue
    }
  }
  
  public var widgetMargins: UIOffset {
    get {
      let margins = AntWidget.shared.widgetMargins
      return UIOffset(horizontal: margins.horizontal, vertical: margins.vertical)
    }
    set {
      AntWidget.shared.widgetMargins = WidgetMargins(vertical: newValue.vertical, horizontal: newValue.horizontal)
    }
  }
  
  @objc
  public var view: UIView { AntWidget.shared.widgetView }
  @objc
  public var onViewerAppear: ((NSDictionary) -> Void)? {
    get {
      AntWidget.shared.onViewerAppear
    }
    set {
      AntWidget.shared.onViewerAppear = newValue
    }
  }
  @objc
  public var onViewerDisappear: ((NSDictionary) -> Void)? {
    get {
      AntWidget.shared.onViewerDisappear
    }
    set {
      AntWidget.shared.onViewerDisappear = newValue
    }
  }
  
  @objc
  public static func authWith(apiKey: String, refUserId: String?, nickname: String?) {
    AntWidget.authWith(apiKey: apiKey, refUserId: refUserId, nickname: nickname)
  }

  public static func registerNotifications(FCMToken: String, completionHandler: @escaping (Result<String, Error>) -> Void) {
    AntWidget.registerNotifications(FCMToken: FCMToken, completionHandler: completionHandler)
  }

  @objc
  public static func objc_registerNotifications(FCMToken: String, completionHandler: @escaping (String?, Error?) -> Void) {
    AntWidget.objc_registerNotifications(FCMToken: FCMToken, completionHandler: completionHandler)
  }

  @objc
  public func showFeed() {
    AntWidget.shared.showFeed()
  }
  
}
