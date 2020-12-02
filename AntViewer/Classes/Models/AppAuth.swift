//
//  AppAuth.swift
//  AntViewer
//
//  Created by Mykola Vaniurskyi on 6/7/19.
//

import Foundation
import Firebase

public class AppAuth {
  public static let shared = AppAuth()
  
  private var fbApp: FirebaseApp?
  
  public func auth() {
    if FirebaseApp.app(name: "AntViewerFirebase") == nil {
      let filePath = Bundle(for: type(of: self)).path(forResource: "GoogleService-Kek", ofType: "plist")
      guard let fileopts = FirebaseOptions(contentsOfFile: filePath!)
        else { return }
      FirebaseApp.configure(name: "AntViewerFirebase", options: fileopts)
    }

    self.fbApp = FirebaseApp.app(name: "AntViewerFirebase")!
    guard let app = fbApp else { return }
    Auth.auth(app: app).signInAnonymously()
  }
  
}
