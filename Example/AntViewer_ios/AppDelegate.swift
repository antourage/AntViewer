//
//  AppDelegate.swift
//  AntViewer_ios
//
//  Created by Mykola Vaniurskyi on 04/17/2019.
//  Copyright (c) 2019 Mykola Vaniurskyi. All rights reserved.
//

import UIKit
import Firebase
import AntViewer_ios

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  
  var window: UIWindow?
  
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
    
    FirebaseApp.configure()
    setupNotificationsFor(application: application)
    Messaging.messaging().delegate = self
    
    
    AntWidget.authWith(apiKey: "put_your_api_key", refUserId: "userID", nickname: nil) { result in
      switch result {
      case .success:
        break
      case .failure(let error):
        print(error)
      }
    }
    
    //MARK: Connect PN to Antourage Firebase app
    Messaging.messaging().retrieveFCMToken(forSenderID: "1090288296965") { (token, error) in
      guard let token = token else { return }
      AntWidget.registerNotifications(FCMToken: token) { (result) in
        
      }
    }
    
    
    Messaging.messaging().subscribe(toTopic: "test") { error in
      if error == nil {
        print("Subscribed to test topic")
      }
      
    }
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
    print("\(response.notification.request.content.userInfo)")
  }
  
}

extension AppDelegate: MessagingDelegate {
  
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
    print("Token: \(fcmToken)")
  }
  
}

