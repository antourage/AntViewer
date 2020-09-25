//
//  AppDelegate.swift
//  AntViewer_ios
//
//  Created by Mykola Vaniurskyi on 04/17/2019.
//  Copyright (c) 2019 Mykola Vaniurskyi. All rights reserved.
//

import UIKit
import Firebase
import Antourage

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  
  var window: UIWindow?
  
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
    
    FirebaseApp.configure()
    setupNotificationsFor(application: application)
    Messaging.messaging().delegate = self
    
    
    AntWidget.authWith(apiKey: "put_your_api_key", refUserId: "userID", nickname: nil)
    
    return true
  }
  
  func setupNotificationsFor(application: UIApplication) {
    
    UNUserNotificationCenter.current().delegate = self
    let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
    
    UNUserNotificationCenter.current().requestAuthorization(
      options: authOptions,
      completionHandler: {_, _ in })
    
    application.registerForRemoteNotifications()
  }
  
}

extension AppDelegate: UNUserNotificationCenterDelegate {
  
  func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    print("\(notification.request.content.userInfo)")
    
    completionHandler([.alert, .badge, .sound])
  }
  
  func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
    let userInfo = response.notification.request.content.userInfo
    print("\(userInfo)")
    if let category = userInfo["category"] as? String, category == "antourage" {
      AntWidget.shared.showFeed()
    }
  }
  
}

extension AppDelegate: MessagingDelegate {
  
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
    print("Token: \(fcmToken)")
    Messaging.messaging().retrieveFCMToken(forSenderID: AntWidget.AntSenderId) { (token, error) in
      guard let token = token else { return }
      AntWidget.registerNotifications(FCMToken: token) { (result) in
        switch result {
        case .success(let topic):
          Messaging.messaging().subscribe(toTopic: topic) { error in
            if error == nil {
              print("Subscribed to topic")
            }
          }
        case .failure(let notificationError):
          print(notificationError.localizedDescription)
        }
      }
    }
  }
  
}

